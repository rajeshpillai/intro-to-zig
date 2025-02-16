const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const numbers = try allocator.alloc(i32, 5);
    defer allocator.free(numbers); // Always free memory!

    numbers[0] = 10;
    std.debug.print("Heap Variable: {},{}\n", .{ numbers[0], numbers.len });
}
