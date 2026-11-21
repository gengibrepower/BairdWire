const std = @import("std");
const testing = std.testing;
const rtp = @import("rtp.zig");

test "isRtp exige versão 2, 12 bytes e payload type fora da faixa do RTCP" {
    try testing.expect(rtp.isRtp(&[_]u8{ 0x80, 111, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 }));
    try testing.expect(!rtp.isRtp(&[_]u8{ 0x40, 111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }));
    try testing.expect(!rtp.isRtp(&[_]u8{ 0x80, 200, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }));
    try testing.expect(!rtp.isRtp(&[_]u8{ 0x80, 223, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }));
    try testing.expect(rtp.isRtp(&[_]u8{ 0x80, 224, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }));
    try testing.expect(!rtp.isRtp(&[_]u8{ 0x80, 111, 0 }));
}

test "isRtp separa RTP e RTCP exatamente entre 191 e 192" {
    try testing.expect(rtp.isRtp(&[_]u8{ 0x80, 191, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }));
    try testing.expect(!rtp.isRtp(&[_]u8{ 0x80, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }));
}

test "isRtp recusa pacote um byte menor que o cabeçalho" {
    try testing.expect(!rtp.isRtp(&[_]u8{ 0x80, 111, 0, 0, 0, 0, 0, 0, 0, 0, 0 }));
}
