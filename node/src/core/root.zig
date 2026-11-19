pub const version = "0.1.0-dev";
pub const protocol = @import("protocol.zig");
pub const connection = @import("connection.zig");
pub const node = @import("node.zig");

test {
    _ = @import("connection_test.zig");
    _ = @import("node_test.zig");
}
