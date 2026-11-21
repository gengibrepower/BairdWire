const std = @import("std");
const testing = std.testing;
const webrtc = @import("webrtc.zig");

test "redact tira IPv4, IPv6 e portas e mantém o texto" {
    var buffer: [256]u8 = undefined;
    const cases = [_][2][]const u8{
        .{ "ICE failed for 192.168.0.12:50000", "ICE failed for <redigido>" },
        .{ "Using [2804:14c:5b8::1]:443 now", "Using <redigido> now" },
        .{ "fe80::1%eth0 down", "<redigido>%eth0 down" },
        .{ "DTLS handshake failed", "DTLS handshake failed" },
        .{ "add face bead", "add face bead" },
        .{ "Peer 4b1d-9c.local unreachable", "Peer 4b1d-<redigido>local unreachable" },
    };
    for (cases) |case| try testing.expectEqualStrings(case[1], webrtc.redact(&buffer, case[0]));
}

test "redact trunca no tamanho do buffer" {
    var buffer: [8]u8 = undefined;
    try testing.expectEqualStrings("conexão", webrtc.redact(&buffer, "conexão perdida"));
}

test "isExpectedNoise só cala o aviso de candidato TCP ignorado" {
    try testing.expect(webrtc.isExpectedNoise("rtc::impl::IceTransport::LogCallback@123: juice: ICE-TCP is disabled, ignoring TCP candidate"));
    try testing.expect(!webrtc.isExpectedNoise("juice: ICE failed"));
    try testing.expect(!webrtc.isExpectedNoise("DTLS handshake failed"));
}
