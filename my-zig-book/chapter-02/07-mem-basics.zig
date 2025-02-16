// Zig does not use a garbage collector—memory is manually managed using allocators.

const std = @import("std");

pub fn main() void {
    // The first {} is the anonmous struct(arg) and the second {} instantiates the allocator struct
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator(); // Retrieves teh allocator

    const ptr = allocator.alloc(u8, 10) catch |err| {
        std.debug.print("Allocation failed: {}\n", .{err});
        return;
    };

    std.debug.print("Allocated memory successfully!\n", .{});

    allocator.free(ptr); // Free memory manually
}
