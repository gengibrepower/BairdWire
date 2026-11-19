const std = @import("std");
const testing = std.testing;
const node_mod = @import("node.zig");
const protocol = @import("protocol.zig");
const rtp = @import("rtp.zig");

const conn: node_mod.ConnId = 1;
const publish_pc: node_mod.PcId = 1;
const subscribe_pc: node_mod.PcId = 2;
const source_track: node_mod.TrackId = 40;

const publish_offer =
    \\{"v":1,"t":"rtc.offer","id":"o1","d":{"pc":"publish","sdp":"v=0 oferta"}}
;
const opus_track = "m=audio 9 UDP/TLS/RTP/SAVPF 111 63\r\na=rtpmap:111 opus/48000/2\r\na=rtpmap:63 red/48000/2\r\n";

const Harness = struct {
    arena: std.heap.ArenaAllocator,
    node: node_mod.Node,

    fn init() Harness {
        return .{ .arena = .init(testing.allocator), .node = .init(testing.allocator, "0.1.0-dev", 42) };
    }

    fn deinit(h: *Harness) void {
        h.node.deinit();
        h.arena.deinit();
    }

    fn run(h: *Harness, event: node_mod.Event) ![]const node_mod.Effect {
        _ = h.arena.reset(.retain_capacity);
        var effects: node_mod.Effects = .empty;
        try h.node.handle(h.arena.allocator(), event, &effects);
        return effects.items;
    }

    fn text(h: *Harness, payload: []const u8) ![]const node_mod.Effect {
        return h.run(.{ .text = .{ .id = conn, .payload = payload } });
    }

    fn established(h: *Harness) !void {
        _ = try h.run(.{ .opened = .{ .id = conn, .now = 0 } });
        _ = try h.text(
            \\{"v":1,"t":"session.hello","id":"h","d":{"versions":[1]}}
        );
    }

    fn published(h: *Harness) !void {
        try h.established();
        _ = try h.text(publish_offer);
        _ = try h.run(.{ .rtc_description = .{ .pc = publish_pc, .sdp = "v=0 resposta" } });
    }

    fn subscribed(h: *Harness) !u32 {
        try h.published();
        const effects = try h.run(.{ .rtc_track = .{ .pc = publish_pc, .track = source_track, .description = opus_track } });
        const ssrc = effects[0].rtc_create.track.?.ssrc;
        _ = try h.run(.{ .rtc_description = .{ .pc = subscribe_pc, .sdp = "v=0 oferta do nó" } });
        _ = try h.text(
            \\{"v":1,"t":"rtc.answer","re":"subscribe-2","d":{"pc":"subscribe","sdp":"v=0 resposta do cliente"}}
        );
        return ssrc;
    }
};

fn expectSend(effect: node_mod.Effect, expected: []const u8) !void {
    try testing.expectEqual(conn, effect.send.id);
    try testing.expectEqualStrings(expected, effect.send.payload);
}

fn expectInvalidState(effects: []const node_mod.Effect, re: []const u8) !void {
    try testing.expectEqual(@as(usize, 1), effects.len);
    const expected = try std.fmt.allocPrint(testing.allocator,
        \\{{"v":1,"t":"session.error","re":"{s}","d":{{"code":"invalid_state"}}}}
    , .{re});
    defer testing.allocator.free(expected);
    try expectSend(effects[0], expected);
}

fn rtpPacket(payload_type: u8, ssrc: u32) [16]u8 {
    var packet = [_]u8{ 0x80, payload_type, 0x12, 0x34, 0, 0, 0x03, 0xc0, 0, 0, 0, 0, 0xde, 0xad, 0xbe, 0xef };
    rtp.setSsrc(&packet, ssrc);
    return packet;
}

test "oferta de publish cria a PeerConnection e repassa o SDP" {
    var h: Harness = .init();
    defer h.deinit();
    try h.established();

    const effects = try h.text(publish_offer);
    try testing.expectEqual(@as(usize, 2), effects.len);
    try testing.expectEqual(publish_pc, effects[0].rtc_create.pc);
    try testing.expectEqual(@as(?node_mod.OutgoingTrack, null), effects[0].rtc_create.track);
    try testing.expectEqual(publish_pc, effects[1].rtc_remote_description.pc);
    try testing.expectEqual(node_mod.DescriptionKind.offer, effects[1].rtc_remote_description.kind);
    try testing.expectEqualStrings("v=0 oferta", effects[1].rtc_remote_description.sdp);
}

test "descrição local do publish vira rtc.answer com re da oferta" {
    var h: Harness = .init();
    defer h.deinit();
    try h.established();
    _ = try h.text(publish_offer);

    const effects = try h.run(.{ .rtc_description = .{ .pc = publish_pc, .sdp = "v=0\r\nresposta" } });
    try testing.expectEqual(@as(usize, 1), effects.len);
    try expectSend(effects[0],
        \\{"v":1,"t":"rtc.answer","re":"o1","d":{"pc":"publish","sdp":"v=0\r\nresposta"}}
    );
    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .rtc_description = .{ .pc = publish_pc, .sdp = "de novo" } })).len);
}

test "oferta sem id, de subscribe ou com dados inválidos fecha com 4000" {
    const cases = [_][]const u8{
        \\{"v":1,"t":"rtc.offer","d":{"pc":"publish","sdp":"v=0"}}
        ,
        \\{"v":1,"t":"rtc.offer","id":"o","d":{"pc":"subscribe","sdp":"v=0"}}
        ,
        \\{"v":1,"t":"rtc.offer","id":"o","d":{"pc":"outro","sdp":"v=0"}}
        ,
        \\{"v":1,"t":"rtc.offer","id":"o","d":{"pc":"publish","sdp":""}}
        ,
        \\{"v":1,"t":"rtc.offer","id":"o","d":{"pc":"publish"}}
        ,
        \\{"v":1,"t":"rtc.answer","d":{"pc":"subscribe","sdp":"v=0"}}
        ,
        \\{"v":1,"t":"rtc.answer","re":"x","d":{"pc":"publish","sdp":"v=0"}}
        ,
        \\{"v":1,"t":"rtc.candidate","d":{"pc":"publish","candidate":"c","mid":""}}
        ,
        \\{"v":1,"t":"rtc.candidate","d":{"pc":"publish","mid":"0"}}
        ,
    };
    for (cases) |case| {
        var h: Harness = .init();
        defer h.deinit();
        try h.established();
        const effects = try h.text(case);
        try testing.expectEqual(@as(usize, 2), effects.len);
        try testing.expectEqual(@as(u16, 4000), effects[1].close.code);
    }
}

test "segunda oferta de publish responde invalid_state sem fechar" {
    var h: Harness = .init();
    defer h.deinit();
    try h.established();
    _ = try h.text(publish_offer);
    try expectInvalidState(try h.text(publish_offer), "o1");
}

test "track Opus no publish cria o subscribe com o mesmo payload type" {
    var h: Harness = .init();
    defer h.deinit();
    try h.published();

    const effects = try h.run(.{ .rtc_track = .{ .pc = publish_pc, .track = source_track, .description = opus_track } });
    try testing.expectEqual(@as(usize, 1), effects.len);
    const create = effects[0].rtc_create;
    try testing.expectEqual(subscribe_pc, create.pc);
    try testing.expectEqualStrings(node_mod.sink_mid, create.track.?.mid);
    try testing.expectEqual(@as(u8, 111), create.track.?.payload_type);
    try testing.expect(create.track.?.ssrc != 0);
}

test "track sem Opus é ignorada" {
    var h: Harness = .init();
    defer h.deinit();
    try h.published();
    const effects = try h.run(.{ .rtc_track = .{ .pc = publish_pc, .track = source_track, .description = "m=audio 9 RTP 0\r\na=rtpmap:0 PCMU/8000\r\n" } });
    try testing.expectEqual(@as(usize, 0), effects.len);
}

test "descrição local do subscribe vira rtc.offer com id próprio" {
    var h: Harness = .init();
    defer h.deinit();
    try h.published();
    _ = try h.run(.{ .rtc_track = .{ .pc = publish_pc, .track = source_track, .description = opus_track } });

    const effects = try h.run(.{ .rtc_description = .{ .pc = subscribe_pc, .sdp = "v=0 oferta do nó" } });
    try testing.expectEqual(@as(usize, 1), effects.len);
    try expectSend(effects[0],
        \\{"v":1,"t":"rtc.offer","id":"subscribe-2","d":{"pc":"subscribe","sdp":"v=0 oferta do nó"}}
    );
}

test "resposta do subscribe só vale com o re da oferta do nó" {
    var h: Harness = .init();
    defer h.deinit();
    try h.published();
    _ = try h.run(.{ .rtc_track = .{ .pc = publish_pc, .track = source_track, .description = opus_track } });

    const early =
        \\{"v":1,"t":"rtc.answer","re":"subscribe-2","d":{"pc":"subscribe","sdp":"v=0"}}
    ;
    try expectInvalidState(try h.text(early), "subscribe-2");

    _ = try h.run(.{ .rtc_description = .{ .pc = subscribe_pc, .sdp = "v=0 oferta do nó" } });
    try expectInvalidState(try h.text(
        \\{"v":1,"t":"rtc.answer","re":"subscribe-9","d":{"pc":"subscribe","sdp":"v=0"}}
    ), "subscribe-9");

    const effects = try h.text(early);
    try testing.expectEqual(@as(usize, 1), effects.len);
    try testing.expectEqual(subscribe_pc, effects[0].rtc_remote_description.pc);
    try testing.expectEqual(node_mod.DescriptionKind.answer, effects[0].rtc_remote_description.kind);

    try expectInvalidState(try h.text(early), "subscribe-2");
}

test "candidatos vão para a PeerConnection certa e o vazio é ignorado" {
    var h: Harness = .init();
    defer h.deinit();
    try h.established();

    const publish_candidate =
        \\{"v":1,"t":"rtc.candidate","id":"c1","d":{"pc":"publish","candidate":"candidate:1 1 udp 1 h 9 typ host","mid":"0"}}
    ;
    try expectInvalidState(try h.text(publish_candidate), "c1");

    _ = try h.text(publish_offer);
    const effects = try h.text(publish_candidate);
    try testing.expectEqual(@as(usize, 1), effects.len);
    try testing.expectEqual(publish_pc, effects[0].rtc_remote_candidate.pc);
    try testing.expectEqualStrings("candidate:1 1 udp 1 h 9 typ host", effects[0].rtc_remote_candidate.candidate);
    try testing.expectEqualStrings("0", effects[0].rtc_remote_candidate.mid);

    try testing.expectEqual(@as(usize, 0), (try h.text(
        \\{"v":1,"t":"rtc.candidate","d":{"pc":"publish","candidate":"","mid":"0"}}
    )).len);

    try expectInvalidState(try h.text(
        \\{"v":1,"t":"rtc.candidate","id":"c2","d":{"pc":"subscribe","candidate":"candidate:x","mid":"0"}}
    ), "c2");
}

test "RTP Opus do publish volta pelo subscribe só com o SSRC trocado" {
    var h: Harness = .init();
    defer h.deinit();
    const ssrc = try h.subscribed();

    const packet = rtpPacket(111, 0x11223344);
    const effects = try h.run(.{ .rtc_media = .{ .pc = publish_pc, .track = source_track, .packet = &packet } });
    try testing.expectEqual(@as(usize, 1), effects.len);
    const send = effects[0].rtc_send;
    try testing.expectEqual(subscribe_pc, send.pc);
    try testing.expectEqualStrings(node_mod.sink_mid, send.mid);
    try testing.expectEqual(ssrc, rtp.ssrcOf(send.packet));
    try testing.expectEqualSlices(u8, packet[0..8], send.packet[0..8]);
    try testing.expectEqualSlices(u8, packet[12..], send.packet[12..]);
    try testing.expectEqual(@as(u32, 0x11223344), rtp.ssrcOf(&packet));
}

test "RTP com marcador mantém o payload type de 7 bits" {
    var h: Harness = .init();
    defer h.deinit();
    _ = try h.subscribed();
    const packet = rtpPacket(0x80 | 111, 1);
    try testing.expectEqual(@as(usize, 1), (try h.run(.{ .rtc_media = .{ .pc = publish_pc, .track = source_track, .packet = &packet } })).len);
}

test "RTCP, outro payload type, outra track, pacote curto e o subscribe não repassam" {
    var h: Harness = .init();
    defer h.deinit();
    _ = try h.subscribed();

    const red = rtpPacket(63, 1);
    const rtcp = [_]u8{ 0x81, 201, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0 };
    const short = [_]u8{ 0x80, 111, 0, 1 };
    const opus = rtpPacket(111, 1);
    const cases = [_]node_mod.Event{
        .{ .rtc_media = .{ .pc = publish_pc, .track = source_track, .packet = &red } },
        .{ .rtc_media = .{ .pc = publish_pc, .track = source_track, .packet = &rtcp } },
        .{ .rtc_media = .{ .pc = publish_pc, .track = source_track, .packet = &short } },
        .{ .rtc_media = .{ .pc = publish_pc, .track = source_track + 1, .packet = &opus } },
        .{ .rtc_media = .{ .pc = subscribe_pc, .track = source_track, .packet = &opus } },
        .{ .rtc_media = .{ .pc = 99, .track = source_track, .packet = &opus } },
    };
    for (cases) |event| try testing.expectEqual(@as(usize, 0), (try h.run(event)).len);
}

test "RTP antes da resposta do subscribe é descartado" {
    var h: Harness = .init();
    defer h.deinit();
    try h.published();
    _ = try h.run(.{ .rtc_track = .{ .pc = publish_pc, .track = source_track, .description = opus_track } });
    const packet = rtpPacket(111, 1);
    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .rtc_media = .{ .pc = publish_pc, .track = source_track, .packet = &packet } })).len);
}

test "WebSocket fechado fecha as duas PeerConnections e esquece a chamada" {
    var h: Harness = .init();
    defer h.deinit();
    _ = try h.subscribed();

    const effects = try h.run(.{ .closed = conn });
    try testing.expectEqual(@as(usize, 2), effects.len);
    try testing.expectEqual(publish_pc, effects[0].rtc_close);
    try testing.expectEqual(subscribe_pc, effects[1].rtc_close);

    const packet = rtpPacket(111, 1);
    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .rtc_media = .{ .pc = publish_pc, .track = source_track, .packet = &packet } })).len);
    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .rtc_state = .{ .pc = subscribe_pc, .state = .closed } })).len);
}

test "PeerConnection que falha encerra a chamada e permite uma nova oferta" {
    var h: Harness = .init();
    defer h.deinit();
    _ = try h.subscribed();

    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .rtc_state = .{ .pc = publish_pc, .state = .disconnected } })).len);
    const effects = try h.run(.{ .rtc_state = .{ .pc = subscribe_pc, .state = .failed } });
    try testing.expectEqual(@as(usize, 2), effects.len);

    const again = try h.text(publish_offer);
    try testing.expectEqual(@as(node_mod.PcId, 3), again[0].rtc_create.pc);
}
