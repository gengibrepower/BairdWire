const std = @import("std");
const c = @import("libsrtp_c");

const rtp_header = [_]u8{ 0x80, 111, 0x00, 0x01, 0x00, 0x00, 0x00, 0xa0, 0xde, 0xad, 0xbe, 0xef };
const payload = "carga de teste";

fn expectOk(status: c.srtp_err_status_t) !void {
    try std.testing.expectEqual(@as(c.srtp_err_status_t, c.srtp_err_status_ok), status);
}

fn roundTrip(comptime setPolicy: fn ([*c]c.srtp_crypto_policy_t) callconv(.c) void, comptime key_len: usize) !void {
    try expectOk(c.srtp_init());
    defer _ = c.srtp_shutdown();

    var key: [key_len]u8 = undefined;
    for (&key, 0..) |*byte, i| byte.* = @intCast(i);

    var policy = std.mem.zeroes(c.srtp_policy_t);
    setPolicy(&policy.rtp);
    setPolicy(&policy.rtcp);
    policy.key = &key;
    policy.window_size = 128;

    policy.ssrc = .{ .type = c.ssrc_any_outbound, .value = 0 };
    var sender: c.srtp_t = null;
    try expectOk(c.srtp_create(&sender, &policy));
    defer _ = c.srtp_dealloc(sender);

    policy.ssrc = .{ .type = c.ssrc_any_inbound, .value = 0 };
    var receiver: c.srtp_t = null;
    try expectOk(c.srtp_create(&receiver, &policy));
    defer _ = c.srtp_dealloc(receiver);

    const plain = rtp_header ++ payload.*;
    var packet: [plain.len + c.SRTP_MAX_TRAILER_LEN]u8 align(4) = undefined;
    @memcpy(packet[0..plain.len], &plain);
    var len: c_int = plain.len;

    try expectOk(c.srtp_protect(sender, &packet, &len));
    try std.testing.expect(len > plain.len);
    try std.testing.expect(!std.mem.eql(u8, packet[rtp_header.len..plain.len], payload));

    try expectOk(c.srtp_unprotect(receiver, &packet, &len));
    try std.testing.expectEqualSlices(u8, &plain, packet[0..@intCast(len)]);
}

test "AES-GCM-128 protege e desprotege um pacote RTP" {
    try roundTrip(c.srtp_crypto_policy_set_aes_gcm_128_16_auth, c.SRTP_AES_GCM_128_KEY_LEN_WSALT);
}

test "AES-CM-128 com HMAC-SHA1-80 protege e desprotege um pacote RTP" {
    try roundTrip(c.srtp_crypto_policy_set_rtp_default, c.SRTP_AES_ICM_128_KEY_LEN_WSALT);
}
