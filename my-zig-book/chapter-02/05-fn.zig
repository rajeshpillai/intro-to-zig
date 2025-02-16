// Functions in Zig use explicit return types.
const std = @import("std");

// Function that returns the square of a number
fn square(x: i32) i32 {
    return x * x;
}

pub fn main() void {
    const result = square(5);
    std.debug.print("Square: {}\n", .{result});
}
