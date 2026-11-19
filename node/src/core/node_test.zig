const std = @import("std");
const testing = std.testing;
const node_mod = @import("node.zig");
const protocol = @import("protocol.zig");

const hello =
    \\{"v":1,"t":"session.hello","id":"1","d":{"versions":[1]}}
;

fn run(node: *node_mod.Node, arena: *std.heap.ArenaAllocator, event: node_mod.Event) ![]const node_mod.Effect {
    var effects: node_mod.Effects = .empty;
    try node.handle(arena.allocator(), event, &effects);
    return effects.items;
}

test "efeitos saem com o id da conexão que os produziu" {
    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    var node: node_mod.Node = .init(testing.allocator, "0.1.0-dev");
    defer node.deinit();

    _ = try run(&node, &arena, .{ .opened = .{ .id = 7, .now = 0 } });
    _ = try run(&node, &arena, .{ .opened = .{ .id = 8, .now = 0 } });

    const effects = try run(&node, &arena, .{ .text = .{ .id = 8, .payload = hello } });
    try testing.expectEqual(@as(usize, 1), effects.len);
    try testing.expectEqual(@as(node_mod.ConnId, 8), effects[0].send.id);
}

test "tick só derruba quem não mandou hello a tempo" {
    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    var node: node_mod.Node = .init(testing.allocator, "0.1.0-dev");
    defer node.deinit();

    _ = try run(&node, &arena, .{ .opened = .{ .id = 1, .now = 0 } });
    _ = try run(&node, &arena, .{ .opened = .{ .id = 2, .now = 0 } });
    _ = try run(&node, &arena, .{ .text = .{ .id = 1, .payload = hello } });

    const effects = try run(&node, &arena, .{ .tick = protocol.hello_timeout_ms });
    try testing.expectEqual(@as(usize, 2), effects.len);
    try testing.expectEqual(@as(node_mod.ConnId, 2), effects[0].send.id);
    try testing.expectEqual(@as(node_mod.ConnId, 2), effects[1].close.id);
    try testing.expectEqual(@as(u16, 4002), effects[1].close.code);
}

test "eventos de conexão desconhecida ou já encerrada são ignorados" {
    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    var node: node_mod.Node = .init(testing.allocator, "0.1.0-dev");
    defer node.deinit();

    try testing.expectEqual(@as(usize, 0), (try run(&node, &arena, .{ .text = .{ .id = 99, .payload = hello } })).len);

    _ = try run(&node, &arena, .{ .opened = .{ .id = 1, .now = 0 } });
    _ = try run(&node, &arena, .{ .closed = 1 });
    try testing.expectEqual(@as(usize, 0), (try run(&node, &arena, .{ .binary = 1 })).len);
    try testing.expectEqual(@as(usize, 0), node.connections.count());
}
