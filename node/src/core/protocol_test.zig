const std = @import("std");
const testing = std.testing;
const protocol = @import("protocol.zig");

test "closeCode fecha com o código de cada erro e não fecha nos recuperáveis" {
    try testing.expectEqual(@as(?u16, 4000), protocol.ErrorCode.protocol_error.closeCode());
    try testing.expectEqual(@as(?u16, 4001), protocol.ErrorCode.version_incompatible.closeCode());
    try testing.expectEqual(@as(?u16, 4002), protocol.ErrorCode.hello_timeout.closeCode());
    try testing.expectEqual(@as(?u16, 1009), protocol.ErrorCode.message_too_large.closeCode());
    try testing.expectEqual(@as(?u16, null), protocol.ErrorCode.unknown_type.closeCode());
    try testing.expectEqual(@as(?u16, null), protocol.ErrorCode.invalid_state.closeCode());
}

fn candidateSignal(arena: std.mem.Allocator, candidate_len: usize, mid_len: usize) !protocol.ParsedSignal {
    const candidate = try arena.alloc(u8, candidate_len);
    @memset(candidate, 'c');
    const mid = try arena.alloc(u8, mid_len);
    @memset(mid, '0');
    const json = try std.fmt.allocPrint(arena,
        \\{{"pc":"publish","candidate":"{s}","mid":"{s}"}}
    , .{ candidate, mid });
    const d = try std.json.parseFromSliceLeaky(std.json.Value, arena, json, .{});
    return protocol.parseSignal("rtc.candidate", d.object);
}

test "rtc.candidate aceita candidate até 1024 bytes e mid de 1 a 32 bytes" {
    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();

    try testing.expect(try candidateSignal(a, protocol.max_candidate_len, 1) == .signal);
    try testing.expect(try candidateSignal(a, protocol.max_candidate_len + 1, 1) == .invalid);
    try testing.expect(try candidateSignal(a, 10, 0) == .invalid);
    try testing.expect(try candidateSignal(a, 10, protocol.max_mid_len) == .signal);
    try testing.expect(try candidateSignal(a, 10, protocol.max_mid_len + 1) == .invalid);
}
