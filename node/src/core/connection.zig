const std = @import("std");
const protocol = @import("protocol.zig");

pub const Event = union(enum) {
    text: []const u8,
    binary,
    tick: i64,
};

pub const Effect = union(enum) {
    send: []const u8,
    close: u16,
};

pub const Effects = std.ArrayList(Effect);

pub const Connection = struct {
    state: State,
    node_version: []const u8,

    const State = union(enum) {
        awaiting_hello: struct { deadline: i64 },
        established: struct { version: u32 },
        closed,
    };

    pub fn init(opened_at: i64, node_version: []const u8) Connection {
        return .{
            .state = .{ .awaiting_hello = .{ .deadline = opened_at + protocol.hello_timeout_ms } },
            .node_version = node_version,
        };
    }

    pub fn handle(conn: *Connection, arena: std.mem.Allocator, event: Event, effects: *Effects) std.mem.Allocator.Error!void {
        switch (conn.state) {
            .closed => {},
            .awaiting_hello => |awaiting| switch (event) {
                .tick => |now| if (now >= awaiting.deadline) try conn.fail(arena, effects, null, .hello_timeout),
                .binary => try conn.fail(arena, effects, null, .protocol_error),
                .text => |payload| try conn.onHello(arena, payload, effects),
            },
            .established => switch (event) {
                .tick => {},
                .binary => try conn.fail(arena, effects, null, .protocol_error),
                .text => |payload| try conn.onMessage(arena, payload, effects),
            },
        }
    }

    fn onHello(conn: *Connection, arena: std.mem.Allocator, payload: []const u8, effects: *Effects) !void {
        if (payload.len > protocol.max_message_before_hello) return conn.fail(arena, effects, null, .message_too_large);

        const envelope = try protocol.parseEnvelope(arena, payload) orelse
            return conn.fail(arena, effects, null, .protocol_error);
        const id = envelope.id orelse return conn.fail(arena, effects, null, .protocol_error);
        if (!std.mem.eql(u8, envelope.t, "session.hello")) return conn.fail(arena, effects, id, .protocol_error);
        const hello = protocol.parseHello(envelope.d) orelse return conn.fail(arena, effects, id, .protocol_error);

        const version = protocol.chooseVersion(hello.versions) orelse
            return conn.fail(arena, effects, id, .version_incompatible);
        try effects.append(arena, .{ .send = try protocol.welcome(arena, id, version, conn.node_version) });
        conn.state = .{ .established = .{ .version = version } };
    }

    fn onMessage(conn: *Connection, arena: std.mem.Allocator, payload: []const u8, effects: *Effects) !void {
        if (payload.len > protocol.max_message) return conn.fail(arena, effects, null, .message_too_large);

        const envelope = try protocol.parseEnvelope(arena, payload) orelse
            return conn.fail(arena, effects, null, .protocol_error);
        if (std.mem.eql(u8, envelope.t, "session.hello")) return conn.fail(arena, effects, envelope.id, .protocol_error);
        try conn.fail(arena, effects, envelope.id, .unknown_type);
    }

    fn fail(conn: *Connection, arena: std.mem.Allocator, effects: *Effects, re: ?[]const u8, code: protocol.ErrorCode) !void {
        try effects.append(arena, .{ .send = try protocol.errorMessage(arena, re, code) });
        if (code.closeCode()) |close_code| {
            try effects.append(arena, .{ .close = close_code });
            conn.state = .closed;
        }
    }
};
