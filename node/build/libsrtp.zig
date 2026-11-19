const std = @import("std");
const mbedtls = @import("mbedtls.zig");

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.lang.Optimize,
    mbedtls_lib: *std.Build.Step.Compile,
) *std.Build.Step.Compile {
    const upstream = b.dependency("libsrtp", .{});
    const t = target.result;
    const config = b.addConfigHeader(.{
        .style = .{ .cmake = upstream.path("config_in_cmake.h") },
        .include_path = "config.h",
    }, .{
        .PACKAGE_VERSION = "2.8.0",
        .PACKAGE_STRING = "libsrtp2 2.8.0",
        .ENABLE_DEBUG_LOGGING = null,
        .ERR_REPORTING_FILE = null,
        .ERR_REPORTING_STDOUT = null,
        .OPENSSL = null,
        .MBEDTLS = true,
        .NSS = null,
        .GCM = true,
        .HAVE_X86 = t.cpu.arch.isX86(),
        .WORDS_BIGENDIAN = t.cpu.arch.endian() == .big,
        .HAVE_ARPA_INET_H = true,
        .HAVE_BYTESWAP_H = true,
        .HAVE_INTTYPES_H = true,
        .HAVE_MACHINE_TYPES_H = null,
        .HAVE_NETINET_IN_H = true,
        .HAVE_STDINT_H = true,
        .HAVE_STDLIB_H = true,
        .HAVE_SYS_INT_TYPES_H = null,
        .HAVE_SYS_SOCKET_H = true,
        .HAVE_SYS_TYPES_H = true,
        .HAVE_UNISTD_H = true,
        .HAVE_WINDOWS_H = null,
        .HAVE_WINSOCK2_H = null,
        .HAVE_INET_ATON = true,
        .HAVE_INET_PTON = true,
        .HAVE_SIGACTION = true,
        .HAVE_USLEEP = true,
        .HAVE_UINT8_T = true,
        .HAVE_UINT16_T = true,
        .HAVE_UINT32_T = true,
        .HAVE_UINT64_T = true,
        .HAVE_INT32_T = true,
        .SIZEOF_UNSIGNED_LONG_CODE = b.fmt("#define SIZEOF_UNSIGNED_LONG {d}", .{t.cTypeByteSize(.ulong).?}),
        .SIZEOF_UNSIGNED_LONG_LONG_CODE = b.fmt("#define SIZEOF_UNSIGNED_LONG_LONG {d}", .{t.cTypeByteSize(.ulonglong).?}),
        .HAVE_INLINE = true,
        .HAVE___INLINE = null,
    });

    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    module.addConfigHeader(config);
    module.addIncludePath(upstream.path("include"));
    module.addIncludePath(upstream.path("crypto/include"));
    module.addCMacro("HAVE_CONFIG_H", "1");
    mbedtls.link(module, mbedtls_lib);
    module.addCSourceFiles(.{
        .root = upstream.path("."),
        .files = &sources,
        .flags = &.{"-std=gnu99"},
    });

    const lib = b.addLibrary(.{ .name = "srtp2", .root_module = module });
    for ([_][]const u8{ "include/srtp.h", "crypto/include/auth.h", "crypto/include/cipher.h", "crypto/include/crypto_types.h" }) |header| {
        lib.installHeader(upstream.path(header), b.fmt("srtp2/{s}", .{std.fs.path.basename(header)}));
    }
    return lib;
}

const sources = [_][]const u8{
    "srtp/srtp.c",
    "crypto/cipher/cipher.c",
    "crypto/cipher/cipher_test_cases.c",
    "crypto/cipher/null_cipher.c",
    "crypto/cipher/aes_icm_mbedtls.c",
    "crypto/cipher/aes_gcm_mbedtls.c",
    "crypto/hash/auth.c",
    "crypto/hash/auth_test_cases.c",
    "crypto/hash/null_auth.c",
    "crypto/hash/hmac_mbedtls.c",
    "crypto/kernel/alloc.c",
    "crypto/kernel/crypto_kernel.c",
    "crypto/kernel/err.c",
    "crypto/kernel/key.c",
    "crypto/math/datatypes.c",
    "crypto/replay/rdb.c",
    "crypto/replay/rdbx.c",
};
