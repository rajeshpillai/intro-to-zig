// Zig supports both while loops (manual control) and for loops (iteration over ranges or arrays).
const std = @import("std");

pub fn main() void {
    var count: i32 = 1;
    while (count <= 5) : (count += 1) {
        std.debug.print("Count: {}\n", .{count});
    }

    const numbers = [_]i32{ 10, 20, 30, 40 };

    for (numbers) |num| {
        std.debug.print("Number: {}\n", .{num});
    }
}
