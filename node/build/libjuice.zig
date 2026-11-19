const std = @import("std");

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
) *std.Build.Step.Compile {
    const upstream = b.dependency("libjuice", .{});
    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    module.addIncludePath(upstream.path("include"));
    module.addIncludePath(upstream.path("include/juice"));
    module.addIncludePath(upstream.path("src"));
    module.addCMacro("JUICE_STATIC", "1");
    module.addCMacro("JUICE_EXPORTS", "1");
    module.addCMacro("USE_NETTLE", "0");
    module.addCMacro("NO_SERVER", "1");
    if (optimize != .debug) module.addCMacro("RELEASE", "1");
    module.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &sources,
        .flags = &.{"-std=gnu11"},
    });

    const lib = b.addLibrary(.{ .name = "juice", .root_module = module });
    lib.installHeadersDirectory(upstream.path("include"), "", .{});
    return lib;
}

const sources = [_][]const u8{
    "addr.c",
    "agent.c",
    "base64.c",
    "conn.c",
    "conn_mux.c",
    "conn_poll.c",
    "conn_thread.c",
    "const_time.c",
    "crc32.c",
    "hash.c",
    "hmac.c",
    "ice.c",
    "juice.c",
    "log.c",
    "random.c",
    "server.c",
    "stun.c",
    "tcp.c",
    "timestamp.c",
    "turn.c",
    "udp.c",
};
