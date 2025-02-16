const std = @import("std");

// Run this code as : zig run filename.zig -- hello world
// ✅ The first argument (main.zig) is always the program name.

pub fn main() !void {
    var args = std.process.args();

    while (args.next()) |arg| {
        std.debug.print("Argument: {s}\n", .{arg});
    }
}
