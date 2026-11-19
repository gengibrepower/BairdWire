const std = @import("std");
const testing = std.testing;
const ws = @import("websocket");
const runtime = @import("runtime.zig");

const origin = "http://bairdwire.test";
const good_headers = "host: 127.0.0.1\r\norigin: " ++ origin;

fn startRuntime(rt: *runtime.Runtime, port: u16) !void {
    try rt.start(testing.io, testing.allocator, .{ .origin = origin, .port = port });
}

fn connect(port: u16, request_path: []const u8, headers: []const u8) !ws.Client {
    var client = try ws.Client.init(testing.io, testing.allocator, .{ .port = port, .host = "127.0.0.1" });
    errdefer client.deinit();
    try client.handshake(request_path, .{ .headers = headers, .timeout_ms = 2_000 });
    try client.readTimeout(8_000);
    return client;
}

fn expectText(client: *ws.Client, expected: []const u8) !void {
    const message = (try client.read()) orelse return error.NoMessage;
    defer client.done(message);
    try testing.expectEqual(ws.Message.Type.text, message.type);
    try testing.expectEqualStrings(expected, message.data);
}

test "hello pelo socket real recebe welcome" {
    var rt: runtime.Runtime = undefined;
    try startRuntime(&rt, 18_091);
    defer rt.stop();

    var client = try connect(18_091, "/api/ws", good_headers);
    defer client.deinit();

    var hello = (
        \\{"v":1,"t":"session.hello","id":"1","d":{"versions":[1]}}
    ).*;
    try client.write(&hello);
    try expectText(&client,
        \\{"v":1,"t":"session.welcome","re":"1","d":{"version":1,"node":"0.1.0-dev","resumed":false}}
    );
}

test "upgrade com Origin de outro site é recusado" {
    var rt: runtime.Runtime = undefined;
    try startRuntime(&rt, 18_092);
    defer rt.stop();

    try testing.expectError(error.InvalidHandshakeResponse, connect(18_092, "/api/ws", "host: 127.0.0.1\r\norigin: https://atacante.example"));
    try testing.expectError(error.InvalidHandshakeResponse, connect(18_092, "/api/ws", "host: 127.0.0.1"));
}

test "upgrade fora de /api/ws é recusado" {
    var rt: runtime.Runtime = undefined;
    try startRuntime(&rt, 18_093);
    defer rt.stop();

    try testing.expectError(error.InvalidHandshakeResponse, connect(18_093, "/", good_headers));
}

test "conexão sem hello é fechada com 4002 pelo relógio do runtime" {
    var rt: runtime.Runtime = undefined;
    try startRuntime(&rt, 18_094);
    defer rt.stop();

    var client = try connect(18_094, "/api/ws", good_headers);
    defer client.deinit();

    try expectText(&client,
        \\{"v":1,"t":"session.error","d":{"code":"hello_timeout"}}
    );
    const close = (try client.read()) orelse return error.NoMessage;
    defer client.done(close);
    try testing.expectEqual(ws.Message.Type.close, close.type);
    try testing.expectEqual(@as(u16, 4002), std.mem.readInt(u16, close.data[0..2], .big));
}
