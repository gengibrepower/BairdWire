const std = @import("std");
const c = @import("libdatachannel_c");

test "cria uma PeerConnection e gera uma oferta com fingerprint DTLS" {
    c.rtcInitLogger(c.RTC_LOG_NONE, null);
    defer c.rtcCleanup();

    var config = std.mem.zeroes(c.rtcConfiguration);
    config.disableAutoNegotiation = true;
    const pc = c.rtcCreatePeerConnection(&config);
    try std.testing.expect(pc > 0);
    defer _ = c.rtcDeletePeerConnection(pc);

    try std.testing.expect(c.rtcCreateDataChannel(pc, "eco") > 0);
    try std.testing.expectEqual(@as(c_int, c.RTC_ERR_SUCCESS), c.rtcSetLocalDescription(pc, "offer"));

    var sdp: [8192]u8 = undefined;
    const len = c.rtcGetLocalDescription(pc, &sdp, sdp.len);
    try std.testing.expect(len > 0);
    const offer = sdp[0..@intCast(len)];
    try std.testing.expect(std.mem.startsWith(u8, offer, "v=0"));
    try std.testing.expect(std.mem.indexOf(u8, offer, "a=fingerprint:sha-256 ") != null);
    try std.testing.expect(std.mem.indexOf(u8, offer, "m=application") != null);
}
