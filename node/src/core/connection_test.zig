const std = @import("std");
const testing = std.testing;
const connection = @import("connection.zig");
const protocol = @import("protocol.zig");

const opened_at: i64 = 1_000_000;
const valid_hello =
    \\{"v":1,"t":"session.hello","id":"1","d":{"versions":[1],"client":"web/0.1.0","resume":null}}
;

const Harness = struct {
    arena: std.heap.ArenaAllocator,
    conn: connection.Connection,

    fn init() Harness {
        return .{
            .arena = .init(testing.allocator),
            .conn = .init(opened_at, "0.1.0-dev"),
        };
    }

    fn deinit(h: *Harness) void {
        h.arena.deinit();
    }

    fn run(h: *Harness, event: connection.Event) ![]const connection.Effect {
        var effects: connection.Effects = .empty;
        try h.conn.handle(h.arena.allocator(), event, &effects);
        return effects.items;
    }

    fn established(h: *Harness) !void {
        _ = try h.run(.{ .text = valid_hello });
        try testing.expect(h.conn.state == .established);
    }
};

fn expectError(effects: []const connection.Effect, re: ?[]const u8, code: protocol.ErrorCode) !void {
    const closes = code.closeCode() != null;
    try testing.expectEqual(@as(usize, if (closes) 2 else 1), effects.len);

    const parsed = try std.json.parseFromSlice(std.json.Value, testing.allocator, effects[0].send, .{});
    defer parsed.deinit();
    const message = parsed.value.object;
    try testing.expectEqualStrings("session.error", message.get("t").?.string);
    try testing.expectEqualStrings(@tagName(code), message.get("d").?.object.get("code").?.string);
    if (re) |expected| {
        try testing.expectEqualStrings(expected, message.get("re").?.string);
    } else {
        try testing.expect(message.get("re") == null);
    }

    if (code.closeCode()) |close_code| try testing.expectEqual(close_code, effects[1].close);
}

test "hello válido recebe welcome no formato congelado" {
    var h: Harness = .init();
    defer h.deinit();

    const effects = try h.run(.{ .text = valid_hello });
    try testing.expectEqual(@as(usize, 1), effects.len);
    try testing.expectEqualStrings(
        \\{"v":1,"t":"session.welcome","re":"1","d":{"version":1,"node":"0.1.0-dev","resumed":false}}
    , effects[0].send);
    try testing.expectEqual(@as(u32, 1), h.conn.state.established.version);
}

test "client e resume são opcionais" {
    var h: Harness = .init();
    defer h.deinit();

    const effects = try h.run(.{ .text =
        \\{"v":1,"t":"session.hello","id":"a","d":{"versions":[1]}}
    });
    try testing.expectEqual(@as(usize, 1), effects.len);
    try testing.expect(h.conn.state == .established);
}

test "escolhe a maior versão em comum" {
    var h: Harness = .init();
    defer h.deinit();

    _ = try h.run(.{ .text =
        \\{"v":7,"t":"session.hello","id":"1","d":{"versions":[7,1,2]}}
    });
    try testing.expectEqual(@as(u32, 1), h.conn.state.established.version);
}

test "sem versão em comum responde version_incompatible no formato congelado e fecha com 4001" {
    var h: Harness = .init();
    defer h.deinit();

    const effects = try h.run(.{ .text =
        \\{"v":2,"t":"session.hello","id":"1","d":{"versions":[2,3]}}
    });
    try testing.expectEqual(@as(usize, 2), effects.len);
    try testing.expectEqualStrings(
        \\{"v":1,"t":"session.error","re":"1","d":{"code":"version_incompatible","supported":[1]}}
    , effects[0].send);
    try testing.expectEqual(@as(u16, 4001), effects[1].close);
    try testing.expect(h.conn.state == .closed);
}

test "hello que não chega em 5 s fecha com 4002" {
    var h: Harness = .init();
    defer h.deinit();

    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .tick = opened_at + protocol.hello_timeout_ms - 1 })).len);
    try expectError(try h.run(.{ .tick = opened_at + protocol.hello_timeout_ms }), null, .hello_timeout);
    try testing.expect(h.conn.state == .closed);
}

test "depois do welcome o prazo do hello não vale mais" {
    var h: Harness = .init();
    defer h.deinit();
    try h.established();

    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .tick = opened_at + 60_000 })).len);
}

test "primeira mensagem que não é hello fecha com 4000 e responde ao id" {
    var h: Harness = .init();
    defer h.deinit();

    try expectError(try h.run(.{ .text =
        \\{"v":1,"t":"chat.send","id":"9","d":{}}
    }), "9", .protocol_error);
}

test "envelopes inválidos fecham com 4000" {
    const cases = [_][]const u8{
        "não é json",
        "[]",
        \\{"t":"session.hello","id":"1","d":{"versions":[1]}}
        ,
        \\{"v":0,"t":"session.hello","id":"1","d":{"versions":[1]}}
        ,
        \\{"v":"1","t":"session.hello","id":"1","d":{"versions":[1]}}
        ,
        \\{"v":1,"t":"session.hello","id":"1"}
        ,
        \\{"v":1,"t":"session.hello","id":"1","d":[]}
        ,
        \\{"v":1,"t":"session.hello","id":1,"d":{"versions":[1]}}
        ,
        \\{"v":1,"t":"session.hello","d":{"versions":[1]}}
        ,
        \\{"v":1,"v":2,"t":"session.hello","id":"1","d":{"versions":[1]}}
        ,
    };
    for (cases) |payload| {
        var h: Harness = .init();
        defer h.deinit();
        try expectError(try h.run(.{ .text = payload }), null, .protocol_error);
    }
}

test "dados do hello inválidos fecham com 4000 e respondem ao id" {
    const cases = [_][]const u8{
        \\{"v":1,"t":"session.hello","id":"1","d":{}}
        ,
        \\{"v":1,"t":"session.hello","id":"1","d":{"versions":[]}}
        ,
        \\{"v":1,"t":"session.hello","id":"1","d":{"versions":["1"]}}
        ,
        \\{"v":1,"t":"session.hello","id":"1","d":{"versions":[0]}}
        ,
        \\{"v":1,"t":"session.hello","id":"1","d":{"versions":[1],"client":42}}
        ,
        \\{"v":1,"t":"session.hello","id":"1","d":{"versions":[1],"resume":false}}
        ,
    };
    for (cases) |payload| {
        var h: Harness = .init();
        defer h.deinit();
        try expectError(try h.run(.{ .text = payload }), "1", .protocol_error);
    }
}

test "id acima de 64 bytes fecha com 4000" {
    var h: Harness = .init();
    defer h.deinit();

    const allocator = h.arena.allocator();
    const long_id = try allocator.alloc(u8, protocol.max_id_len + 1);
    @memset(long_id, 'x');
    const payload = try std.fmt.allocPrint(allocator,
        \\{{"v":1,"t":"session.hello","id":"{s}","d":{{"versions":[1]}}}}
    , .{long_id});
    try expectError(try h.run(.{ .text = payload }), null, .protocol_error);
}

test "id com aspas e controle volta escapado no re" {
    var h: Harness = .init();
    defer h.deinit();

    const effects = try h.run(.{ .text =
        \\{"v":1,"t":"session.hello","id":"a\"b\\c\n","d":{"versions":[1]}}
    });
    const parsed = try std.json.parseFromSlice(std.json.Value, testing.allocator, effects[0].send, .{});
    defer parsed.deinit();
    try testing.expectEqualStrings("a\"b\\c\n", parsed.value.object.get("re").?.string);
}

test "frame binário fecha com 4000 antes e depois do hello" {
    {
        var h: Harness = .init();
        defer h.deinit();
        try expectError(try h.run(.binary), null, .protocol_error);
    }
    {
        var h: Harness = .init();
        defer h.deinit();
        try h.established();
        try expectError(try h.run(.binary), null, .protocol_error);
    }
}

test "mensagem acima de 4 KiB antes do hello fecha com 1009" {
    var h: Harness = .init();
    defer h.deinit();

    const payload = try h.arena.allocator().alloc(u8, protocol.max_message_before_hello + 1);
    @memset(payload, ' ');
    try expectError(try h.run(.{ .text = payload }), null, .message_too_large);
}

test "depois do welcome o limite sobe para 64 KiB" {
    var h: Harness = .init();
    defer h.deinit();
    try h.established();

    const allocator = h.arena.allocator();
    const prefix = "{\"v\":1,\"t\":\"chat.send\",\"id\":\"2\",\"d\":{\"text\":\"";
    const suffix = "\"}}";
    const fits = try allocator.alloc(u8, protocol.max_message);
    @memset(fits, 'a');
    @memcpy(fits[0..prefix.len], prefix);
    @memcpy(fits[fits.len - suffix.len ..], suffix);
    try expectError(try h.run(.{ .text = fits }), "2", .unknown_type);

    const too_large = try allocator.alloc(u8, protocol.max_message + 1);
    @memset(too_large, ' ');
    try expectError(try h.run(.{ .text = too_large }), null, .message_too_large);
}

test "tipo desconhecido depois do welcome responde sem fechar" {
    var h: Harness = .init();
    defer h.deinit();
    try h.established();

    try expectError(try h.run(.{ .text =
        \\{"v":1,"t":"chat.send","id":"2","d":{}}
    }), "2", .unknown_type);
    try testing.expect(h.conn.state == .established);
}

test "hello repetido fecha com 4000" {
    var h: Harness = .init();
    defer h.deinit();
    try h.established();

    try expectError(try h.run(.{ .text = valid_hello }), "1", .protocol_error);
}

test "conexão fechada ignora qualquer evento" {
    var h: Harness = .init();
    defer h.deinit();
    _ = try h.run(.binary);

    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .text = valid_hello })).len);
    try testing.expectEqual(@as(usize, 0), (try h.run(.binary)).len);
    try testing.expectEqual(@as(usize, 0), (try h.run(.{ .tick = opened_at + 10_000 })).len);
}

test "mensagem de exatamente 4 KiB antes do hello não é grande demais" {
    var h: Harness = .init();
    defer h.deinit();

    const payload = try h.arena.allocator().alloc(u8, protocol.max_message_before_hello);
    @memset(payload, ' ');
    try expectError(try h.run(.{ .text = payload }), null, .protocol_error);
}
