const std = @import("std");

pub fn main() void {
    const x: i32 = 49; // Stored on the stack
    std.debug.print("Stack variable: {}\n", .{x});
}
