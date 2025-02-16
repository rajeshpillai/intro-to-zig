const std = @import("std");

// Run this code as : zig run filename.zig --name somename
// ✅ CLI flags like --name allow dynamic user input.
pub fn main() !void {
    var args = std.process.args();
    _ = args.next(); // Skip the program name

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--name")) {
            if (args.next()) |value| {
                std.debug.print("Hello, {s}!\n", .{value});
            } else {
                std.debug.print("Error: --name reqires a value\n", .{});
            }
        }
    }
}
