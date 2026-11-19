const std = @import("std");
const mbedtls = @import("mbedtls.zig");

pub const Deps = struct {
    mbedtls: *std.Build.Step.Compile,
    juice: *std.Build.Step.Compile,
    srtp: *std.Build.Step.Compile,
    usrsctp: *std.Build.Step.Compile,
};

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    deps: Deps,
) *std.Build.Step.Compile {
    const upstream = b.dependency("libdatachannel", .{});
    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    module.addIncludePath(upstream.path("include"));
    module.addIncludePath(upstream.path("include/rtc"));
    module.addIncludePath(upstream.path("src"));
    module.addIncludePath(b.dependency("plog", .{}).path("include"));
    module.addIncludePath(deps.srtp.getEmittedIncludeTree().path(b, "srtp2"));
    for (macros) |macro| module.addCMacro(macro[0], macro[1]);
    mbedtls.link(module, deps.mbedtls);
    module.linkLibrary(deps.juice);
    module.linkLibrary(deps.srtp);
    module.linkLibrary(deps.usrsctp);
    module.addCSourceFiles(.{
        .root = upstream.path("."),
        .files = &sources,
        .flags = &.{"-std=c++17"},
    });

    const lib = b.addLibrary(.{ .name = "datachannel", .root_module = module });
    lib.installHeadersDirectory(upstream.path("include/rtc"), "rtc", .{});
    return lib;
}

pub const macros = [_][2][]const u8{
    .{ "RTC_EXPORTS", "1" },
    .{ "RTC_STATIC", "1" },
    .{ "RTC_ENABLE_WEBSOCKET", "0" },
    .{ "RTC_ENABLE_MEDIA", "1" },
    .{ "RTC_SYSTEM_SRTP", "0" },
    .{ "RTC_SYSTEM_JUICE", "0" },
    .{ "USE_MBEDTLS", "1" },
    .{ "USE_GNUTLS", "0" },
    .{ "USE_NICE", "0" },
};

const sources = [_][]const u8{
    "src/av1rtppacketizer.cpp",
    "src/candidate.cpp",
    "src/capi.cpp",
    "src/channel.cpp",
    "src/configuration.cpp",
    "src/datachannel.cpp",
    "src/dependencydescriptor.cpp",
    "src/description.cpp",
    "src/global.cpp",
    "src/h264rtpdepacketizer.cpp",
    "src/h264rtppacketizer.cpp",
    "src/h265nalunit.cpp",
    "src/h265rtpdepacketizer.cpp",
    "src/h265rtppacketizer.cpp",
    "src/iceudpmuxlistener.cpp",
    "src/impl/certificate.cpp",
    "src/impl/channel.cpp",
    "src/impl/datachannel.cpp",
    "src/impl/dtlssrtptransport.cpp",
    "src/impl/dtlstransport.cpp",
    "src/impl/http.cpp",
    "src/impl/httpproxytransport.cpp",
    "src/impl/icetransport.cpp",
    "src/impl/iceudpmuxlistener.cpp",
    "src/impl/init.cpp",
    "src/impl/logcounter.cpp",
    "src/impl/peerconnection.cpp",
    "src/impl/pollinterrupter.cpp",
    "src/impl/pollservice.cpp",
    "src/impl/processor.cpp",
    "src/impl/sctptransport.cpp",
    "src/impl/sha.cpp",
    "src/impl/tcpserver.cpp",
    "src/impl/tcptransport.cpp",
    "src/impl/threadpool.cpp",
    "src/impl/tls.cpp",
    "src/impl/tlstransport.cpp",
    "src/impl/track.cpp",
    "src/impl/transport.cpp",
    "src/impl/utils.cpp",
    "src/impl/verifiedtlstransport.cpp",
    "src/impl/websocket.cpp",
    "src/impl/websocketserver.cpp",
    "src/impl/wshandshake.cpp",
    "src/impl/wstransport.cpp",
    "src/mediahandler.cpp",
    "src/message.cpp",
    "src/nalunit.cpp",
    "src/pacinghandler.cpp",
    "src/peerconnection.cpp",
    "src/plihandler.cpp",
    "src/rembhandler.cpp",
    "src/rtcpnackresponder.cpp",
    "src/rtcpreceivingsession.cpp",
    "src/rtcpsrreporter.cpp",
    "src/rtp.cpp",
    "src/rtpdepacketizer.cpp",
    "src/rtppacketizationconfig.cpp",
    "src/rtppacketizer.cpp",
    "src/track.cpp",
    "src/websocket.cpp",
    "src/websocketserver.cpp",
};
