const std = @import("std");

pub fn opusPayloadType(media_description: []const u8) ?u8 {
    var lines = std.mem.splitScalar(u8, media_description, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, "\r");
        const rest = std.mem.cutPrefix(u8, line, "a=rtpmap:") orelse continue;
        const space = std.mem.indexOfScalar(u8, rest, ' ') orelse continue;
        const encoding = rest[space + 1 ..];
        if (!std.ascii.startsWithIgnoreCase(encoding, "opus/48000")) continue;
        return std.fmt.parseInt(u8, rest[0..space], 10) catch continue;
    }
    return null;
}

test "opusPayloadType lê o rtpmap do Opus" {
    try std.testing.expectEqual(@as(?u8, 111), opusPayloadType("m=audio 9 UDP/TLS/RTP/SAVPF 111 63\r\na=rtpmap:111 opus/48000/2\r\na=rtpmap:63 red/48000/2\r\n"));
    try std.testing.expectEqual(@as(?u8, 109), opusPayloadType("a=rtpmap:0 PCMU/8000\na=rtpmap:109 OPUS/48000/2\n"));
    try std.testing.expectEqual(@as(?u8, null), opusPayloadType("a=rtpmap:300 opus/48000/2\r\n"));
    try std.testing.expectEqual(@as(?u8, null), opusPayloadType("a=rtpmap:x opus/48000/2\r\n"));
    try std.testing.expectEqual(@as(?u8, null), opusPayloadType("a=rtpmap:96 opus/16000\r\n"));
    try std.testing.expectEqual(@as(?u8, null), opusPayloadType(""));
}
