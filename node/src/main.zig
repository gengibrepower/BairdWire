const std = @import("std");
const core = @import("core");

pub fn main(init: std.process.Init) !void {
    var buffer: [64]u8 = undefined;
    var stdout: std.Io.File.Writer = .init(.stdout(), init.io, &buffer);
    try stdout.interface.print("bairdwire-node {s}\n", .{core.version});
    try stdout.interface.flush();
}
