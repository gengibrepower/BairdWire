const std = @import("std");
const testing = std.testing;
const sdp = @import("sdp.zig");

test "opusPayloadType lê o rtpmap do Opus" {
    try testing.expectEqual(@as(?u8, 111), sdp.opusPayloadType("m=audio 9 UDP/TLS/RTP/SAVPF 111 63\r\na=rtpmap:111 opus/48000/2\r\na=rtpmap:63 red/48000/2\r\n"));
    try testing.expectEqual(@as(?u8, 109), sdp.opusPayloadType("a=rtpmap:0 PCMU/8000\na=rtpmap:109 OPUS/48000/2\n"));
    try testing.expectEqual(@as(?u8, null), sdp.opusPayloadType("a=rtpmap:300 opus/48000/2\r\n"));
    try testing.expectEqual(@as(?u8, null), sdp.opusPayloadType("a=rtpmap:x opus/48000/2\r\n"));
    try testing.expectEqual(@as(?u8, null), sdp.opusPayloadType("a=rtpmap:96 opus/16000\r\n"));
    try testing.expectEqual(@as(?u8, null), sdp.opusPayloadType(""));
}

test "opusPayloadType fica com o primeiro rtpmap de Opus" {
    try testing.expectEqual(@as(?u8, 111), sdp.opusPayloadType("a=rtpmap:111 opus/48000/2\r\na=rtpmap:96 opus/48000/2\r\n"));
}

test "opusPayloadType ignora rtpmap sem espaço entre o número e a codificação" {
    try testing.expectEqual(@as(?u8, null), sdp.opusPayloadType("a=rtpmap:111opus/48000/2\r\n"));
}
