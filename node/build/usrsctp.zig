const std = @import("std");

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
) *std.Build.Step.Compile {
    const upstream = b.dependency("usrsctp", .{});
    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    module.addIncludePath(upstream.path("usrsctplib"));
    for ([_][]const u8{
        "__Userspace__",
        "SCTP_SIMPLE_ALLOCATOR",
        "SCTP_PROCESS_LEVEL_LOCKS",
        "SCTP_DEBUG",
        "_GNU_SOURCE",
        "HAVE_LINUX_IF_ADDR_H",
        "HAVE_LINUX_RTNETLINK_H",
        "HAVE_NETINET_IP_ICMP_H",
        "HAVE_NET_ROUTE_H",
        "HAVE_STDATOMIC_H",
    }) |macro| module.addCMacro(macro, "1");
    if (!target.result.abi.isMusl()) module.addCMacro("HAVE_SYS_QUEUE_H", "1");
    module.addCSourceFiles(.{
        .root = upstream.path("usrsctplib"),
        .files = &sources,
        .flags = &.{ "-std=c99", "-Wno-address-of-packed-member", "-Wno-deprecated-declarations" },
    });

    const lib = b.addLibrary(.{ .name = "usrsctp", .root_module = module });
    lib.installHeader(upstream.path("usrsctplib/usrsctp.h"), "usrsctp.h");
    return lib;
}

const sources = [_][]const u8{
    "netinet/sctp_asconf.c",
    "netinet/sctp_auth.c",
    "netinet/sctp_bsd_addr.c",
    "netinet/sctp_callout.c",
    "netinet/sctp_cc_functions.c",
    "netinet/sctp_crc32.c",
    "netinet/sctp_indata.c",
    "netinet/sctp_input.c",
    "netinet/sctp_output.c",
    "netinet/sctp_pcb.c",
    "netinet/sctp_peeloff.c",
    "netinet/sctp_sha1.c",
    "netinet/sctp_ss_functions.c",
    "netinet/sctp_sysctl.c",
    "netinet/sctp_timer.c",
    "netinet/sctp_userspace.c",
    "netinet/sctp_usrreq.c",
    "netinet/sctputil.c",
    "netinet6/sctp6_usrreq.c",
    "user_environment.c",
    "user_mbuf.c",
    "user_recv_thread.c",
    "user_socket.c",
};
