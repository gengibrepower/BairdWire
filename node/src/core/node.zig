const std = @import("std");
const connection = @import("connection.zig");

pub const ConnId = u64;

pub const Event = union(enum) {
    opened: struct { id: ConnId, now: i64 },
    text: struct { id: ConnId, payload: []const u8 },
    binary: ConnId,
    closed: ConnId,
    tick: i64,
};

pub const Effect = union(enum) {
    send: struct { id: ConnId, payload: []const u8 },
    close: struct { id: ConnId, code: u16 },
};

pub const Effects = std.ArrayList(Effect);

pub const Node = struct {
    gpa: std.mem.Allocator,
    version: []const u8,
    connections: std.AutoHashMapUnmanaged(ConnId, connection.Connection) = .empty,

    pub fn init(gpa: std.mem.Allocator, version: []const u8) Node {
        return .{ .gpa = gpa, .version = version };
    }

    pub fn deinit(node: *Node) void {
        node.connections.deinit(node.gpa);
    }

    pub fn handle(node: *Node, arena: std.mem.Allocator, event: Event, effects: *Effects) std.mem.Allocator.Error!void {
        switch (event) {
            .opened => |opened| try node.connections.put(node.gpa, opened.id, .init(opened.now, node.version)),
            .closed => |id| _ = node.connections.remove(id),
            .text => |text| try node.forward(arena, text.id, .{ .text = text.payload }, effects),
            .binary => |id| try node.forward(arena, id, .binary, effects),
            .tick => |now| {
                var it = node.connections.iterator();
                while (it.next()) |entry| try node.deliver(arena, entry.key_ptr.*, entry.value_ptr, .{ .tick = now }, effects);
            },
        }
    }

    fn forward(node: *Node, arena: std.mem.Allocator, id: ConnId, event: connection.Event, effects: *Effects) !void {
        const conn = node.connections.getPtr(id) orelse return;
        try node.deliver(arena, id, conn, event, effects);
    }

    fn deliver(_: *Node, arena: std.mem.Allocator, id: ConnId, conn: *connection.Connection, event: connection.Event, effects: *Effects) !void {
        var produced: connection.Effects = .empty;
        try conn.handle(arena, event, &produced);
        for (produced.items) |effect| try effects.append(arena, switch (effect) {
            .send => |payload| .{ .send = .{ .id = id, .payload = payload } },
            .close => |code| .{ .close = .{ .id = id, .code = code } },
        });
    }
};
