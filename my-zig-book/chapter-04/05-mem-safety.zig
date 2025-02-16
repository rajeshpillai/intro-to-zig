const std = @import("std");

// 🚨 This will trigger a runtime error: index out of bounds.
// ✅ Zig prevents unsafe memory access with runtime checks.
pub fn main() !void {
    const buffer: [5]u8 = [_]u8{ 0, 1, 2, 3, 4 };

    // Accessing an out-of-bounds index
    std.debug.print("Invalid access: {}\n", .{buffer[10]});
}
