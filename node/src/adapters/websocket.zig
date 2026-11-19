const std = @import("std");
const ws = @import("websocket");
const core = @import("core");
const node = core.node;

pub const path = "/api/ws";

pub const Events = std.Io.Queue(node.Event);

pub const Gateway = struct {
    io: std.Io,
    gpa: std.mem.Allocator,
    events: *Events,
    origin: []const u8,
    next_id: std.atomic.Value(node.ConnId) = .init(1),
    lock: std.Io.Mutex = .init,
    conns: std.AutoHashMapUnmanaged(node.ConnId, *ws.Conn) = .empty,

    pub fn deinit(gateway: *Gateway) void {
        gateway.conns.deinit(gateway.gpa);
    }

    pub fn dispatch(gateway: *Gateway, effect: node.Effect) void {
        gateway.lock.lockUncancelable(gateway.io);
        defer gateway.lock.unlock(gateway.io);
        switch (effect) {
            .send => |send| if (gateway.conns.get(send.id)) |conn| conn.write(send.payload) catch {},
            .close => |close| if (gateway.conns.get(close.id)) |conn| conn.close(.{ .code = close.code }) catch {},
        }
    }

    fn enqueue(gateway: *Gateway, event: node.Event) void {
        gateway.events.putOneUncancelable(gateway.io, event) catch {
            if (event == .text) gateway.gpa.free(event.text.payload);
        };
    }
};

pub const Handler = struct {
    gateway: *Gateway,
    conn: *ws.Conn,
    id: node.ConnId,

    pub fn init(handshake: *ws.Handshake, conn: *ws.Conn, gateway: *Gateway) !Handler {
        const target = handshake.url;
        const request_path = target[0 .. std.mem.indexOfScalar(u8, target, '?') orelse target.len];
        if (!std.mem.eql(u8, request_path, path)) return error.NotFound;

        const origin = handshake.headers.get("origin") orelse return error.ForbiddenOrigin;
        if (!std.mem.eql(u8, origin, gateway.origin)) return error.ForbiddenOrigin;

        return .{ .gateway = gateway, .conn = conn, .id = gateway.next_id.fetchAdd(1, .monotonic) };
    }

    pub fn afterInit(handler: *Handler) !void {
        const gateway = handler.gateway;
        {
            gateway.lock.lockUncancelable(gateway.io);
            defer gateway.lock.unlock(gateway.io);
            try gateway.conns.put(gateway.gpa, handler.id, handler.conn);
        }
        gateway.enqueue(.{ .opened = .{ .id = handler.id, .now = nowMs(gateway.io) } });
    }

    pub fn clientMessage(handler: *Handler, data: []const u8, kind: ws.MessageTextType) !void {
        const gateway = handler.gateway;
        switch (kind) {
            .text => gateway.enqueue(.{ .text = .{ .id = handler.id, .payload = try gateway.gpa.dupe(u8, data) } }),
            .binary => gateway.enqueue(.{ .binary = handler.id }),
        }
    }

    pub fn close(handler: *Handler) void {
        const gateway = handler.gateway;
        {
            gateway.lock.lockUncancelable(gateway.io);
            defer gateway.lock.unlock(gateway.io);
            _ = gateway.conns.remove(handler.id);
        }
        gateway.enqueue(.{ .closed = handler.id });
    }
};

pub fn nowMs(io: std.Io) i64 {
    return std.Io.Clock.awake.now(io).toMilliseconds();
}
