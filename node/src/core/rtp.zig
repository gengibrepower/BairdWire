const std = @import("std");

pub const header_len = 12;

pub fn isRtp(packet: []const u8) bool {
    if (packet.len < header_len) return false;
    if (packet[0] >> 6 != 2) return false;
    return !isRtcpPayloadType(packet[1]);
}

fn isRtcpPayloadType(second_byte: u8) bool {
    return second_byte >= 192 and second_byte <= 223;
}

pub fn setSsrc(packet: []u8, ssrc: u32) void {
    std.mem.writeInt(u32, packet[8..12], ssrc, .big);
}

pub fn ssrcOf(packet: []const u8) u32 {
    return std.mem.readInt(u32, packet[8..12], .big);
}

pub fn payloadType(packet: []const u8) u7 {
    return @truncate(packet[1]);
}
