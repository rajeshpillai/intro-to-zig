// Zig’s if-else statements work like in C, but with optional error handling.

const std = @import("std");

pub fn main() void {
    const score: i32 = 85;

    if (score >= 90) {
        std.debug.print("Grade: A\n", .{});
    } else if (score >= 80) {
        std.debug.print("Grade: B\n", .{});
    } else {
        std.debug.print("Grade: C\n", .{});
    }
}
