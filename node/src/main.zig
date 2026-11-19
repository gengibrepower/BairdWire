const std = @import("std");
const core = @import("core");
const runtime = @import("runtime.zig");

const log = std.log.scoped(.main);

pub const std_options: std.Options = .{ .logFn = logWithoutLibraryData };

const own_scopes = [_][]const u8{ "main", "runtime" };

fn logWithoutLibraryData(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    const own = comptime for (own_scopes) |name| {
        if (std.mem.eql(u8, @tagName(scope), name)) break true;
    } else false;
    if (own) return std.log.defaultLog(level, scope, format, args);
    std.log.defaultLog(level, scope, "{s}", .{format});
}

pub fn main(init: std.process.Init) !void {
    const env = init.environ_map;
    const origin = env.get("BAIRDWIRE_ORIGIN") orelse {
        log.err("defina BAIRDWIRE_ORIGIN com a origem pública do nó, por exemplo https://exemplo.org", .{});
        return error.MissingOrigin;
    };
    var config: runtime.Config = .{ .origin = origin };
    if (env.get("BAIRDWIRE_WS_ADDRESS")) |address| config.address = address;
    if (env.get("BAIRDWIRE_WS_PORT")) |port| config.port = std.fmt.parseInt(u16, port, 10) catch {
        log.err("BAIRDWIRE_WS_PORT inválida", .{});
        return error.InvalidPort;
    };

    var rt: runtime.Runtime = undefined;
    try rt.start(init.io, init.gpa, config);
    log.info("bairdwire-node {s} ouvindo o WebSocket em {s}:{d}", .{ core.version, config.address, config.port });
    rt.listener.join();
}

test {
    _ = @import("runtime_test.zig");
}
