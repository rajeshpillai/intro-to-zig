// Sometimes, we need to customize memory allocation for performance optimization.

// Example: Creating a Simple Custom Allocator

const std = @import("std");

const MyAllocator = struct {
    backing_allocator: std.mem.Allocator,

    fn alloc(self: *MyAllocator, len: usize) ![]u8 {
        return try self.backing_allocator.alloc(u8, len);
    }

    fn free(self: *MyAllocator, ptr: []u8) void {
        self.backing_allocator.free(ptr);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var my_allocator = MyAllocator{ .backing_allocator = gpa.allocator() };

    const memory = try my_allocator.alloc(50);
    defer my_allocator.free(memory);

    std.debug.print("Custom Allocator: Allocaed {} bytes\n", .{memory.len});
}
