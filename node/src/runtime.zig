const std = @import("std");
const ws = @import("websocket");
const core = @import("core");
const websocket = @import("adapters/websocket.zig");
const node = core.node;

const log = std.log.scoped(.runtime);

pub const Config = struct {
    origin: []const u8,
    address: []const u8 = "127.0.0.1",
    port: u16 = 8090,
};

const tick_interval_ms = 1_000;
const queue_capacity = 1024;

pub const Runtime = struct {
    io: std.Io,
    gpa: std.mem.Allocator,
    buffer: [queue_capacity]node.Event,
    events: websocket.Events,
    gateway: websocket.Gateway,
    server: ws.Server(websocket.Handler),
    listener: std.Thread,
    actor: std.Thread,
    ticker: std.Thread,

    pub fn start(rt: *Runtime, io: std.Io, gpa: std.mem.Allocator, config: Config) !void {
        rt.io = io;
        rt.gpa = gpa;
        rt.events = .init(&rt.buffer);
        rt.gateway = .{ .io = io, .gpa = gpa, .events = &rt.events, .origin = config.origin };
        errdefer rt.gateway.deinit();

        rt.server = try .init(io, gpa, .{
            .address = config.address,
            .port = config.port,
            .max_message_size = core.protocol.max_message,
            .handshake = .{ .timeout = 5, .max_size = 8 * 1024, .max_headers = 32 },
        });
        errdefer rt.server.deinit();

        rt.actor = try std.Thread.spawn(.{}, runActor, .{rt});
        errdefer {
            rt.events.close(io);
            rt.actor.join();
        }
        rt.ticker = try std.Thread.spawn(.{}, runTicker, .{rt});
        errdefer rt.ticker.join();
        rt.listener = try rt.server.listenInNewThread(&rt.gateway);
    }

    pub fn stop(rt: *Runtime) void {
        rt.server.stop();
        rt.listener.join();
        rt.events.close(rt.io);
        rt.actor.join();
        rt.ticker.join();
        rt.server.deinit();
        rt.gateway.deinit();
    }

    fn runActor(rt: *Runtime) void {
        var state: node.Node = .init(rt.gpa, core.version);
        defer state.deinit();
        var arena: std.heap.ArenaAllocator = .init(rt.gpa);
        defer arena.deinit();

        while (true) {
            const event = rt.events.getOneUncancelable(rt.io) catch break;
            defer if (event == .text) rt.gpa.free(event.text.payload);
            _ = arena.reset(.retain_capacity);

            var effects: node.Effects = .empty;
            state.handle(arena.allocator(), event, &effects) catch {
                log.err("sem memória ao processar um evento", .{});
                continue;
            };
            for (effects.items) |effect| rt.gateway.dispatch(effect);
        }
    }

    fn runTicker(rt: *Runtime) void {
        while (true) {
            rt.io.sleep(.fromMilliseconds(tick_interval_ms), .awake) catch break;
            rt.events.putOneUncancelable(rt.io, .{ .tick = websocket.nowMs(rt.io) }) catch break;
        }
    }
};
