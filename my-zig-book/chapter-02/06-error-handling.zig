// Unlike other languages that use exceptions, Zig has explicit error handling.

const std = @import("std");

// Function that may return an error
fn divide(a: u32, b: u32) !u32 {
    if (b == 0) return error.DivisionByZero;
    return a / b;
}

pub fn main() void {
    const result = divide(10, 2) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };

    std.debug.print("Result: {}\n", .{result});
}
