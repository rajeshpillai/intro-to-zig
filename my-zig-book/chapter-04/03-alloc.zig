// Allocating and Freeing Memory with Allocators
// Zig does not use malloc and free directly. Instead, it provides
// allocators for memory management.

// Example: Using the General Purpose Allocator (std.heap)

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const buffer = try allocator.alloc(u8, 100); // Allocate 100 bytes
    defer allocator.free(buffer); // Free memory when done

    buffer[0] = 'Z'; // Use allocated memory
    std.debug.print("First byte: {c}\n", .{buffer[0]});
}
