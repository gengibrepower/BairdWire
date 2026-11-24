const std = @import("std");

pub fn opusPayloadType(media_description: []const u8) ?u8 {
    var media_lines = std.mem.splitScalar(u8, media_description, '\n');
    while (media_lines.next()) |line| {
        const trimmed = std.mem.trimEnd(u8, line, "\r");
        const after_prefix = std.mem.cutPrefix(u8, trimmed, "a=rtpmap:") orelse continue;
        const space_index = std.mem.indexOfScalar(u8, after_prefix, ' ') orelse continue;
        const encoding = after_prefix[space_index + 1 ..];
        if (!std.ascii.startsWithIgnoreCase(encoding, "opus/48000")) continue;
        return std.fmt.parseInt(u8, after_prefix[0..space_index], 10) catch continue;
    }
    return null;
}
