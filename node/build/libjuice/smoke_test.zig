const std = @import("std");
const c = @import("libjuice_c");

test "cria um agente e gera a descrição local" {
    c.juice_set_log_level(c.JUICE_LOG_LEVEL_NONE);
    const config: c.juice_config_t = .{ .concurrency_mode = c.JUICE_CONCURRENCY_MODE_POLL };
    const agent = c.juice_create(&config) orelse return error.AgentNotCreated;
    defer c.juice_destroy(agent);

    var description: [c.JUICE_MAX_SDP_STRING_LEN]u8 = undefined;
    try std.testing.expectEqual(@as(c_int, 0), c.juice_get_local_description(agent, &description, description.len));
    try std.testing.expect(std.mem.indexOf(u8, std.mem.sliceTo(&description, 0), "a=ice-ufrag:") != null);
}
