const std = @import("std");
const c = @import("mbedtls_c");

test "versão fixada no ADR 0034" {
    var version: [9]u8 = undefined;
    c.mbedtls_version_get_string(&version);
    try std.testing.expectEqualStrings("3.6.8", std.mem.sliceTo(&version, 0));
}

test "sha256 confere com o vetor do FIPS 180-2" {
    var digest: [32]u8 = undefined;
    try std.testing.expectEqual(@as(c_int, 0), c.mbedtls_sha256("abc", 3, &digest, 0));
    var expected: [32]u8 = undefined;
    _ = try std.fmt.hexToBytes(&expected, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    try std.testing.expectEqualSlices(u8, &expected, &digest);
}

test "config tem DTLS-SRTP e threading" {
    try std.testing.expect(@hasDecl(c, "mbedtls_ssl_conf_dtls_srtp_protection_profiles"));
    try std.testing.expect(@hasDecl(c, "mbedtls_mutex_lock"));
}
