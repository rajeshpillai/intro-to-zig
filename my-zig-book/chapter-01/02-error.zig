const std = @import("std");

// Explanation
// ✅ catch {} handles errors without crashing the program.
// ✅ No need for try-catch blocks—errors are values, not exceptions

pub fn main() void {
    const file = std.fs.cwd().openFile("nonexistent.txt", .{}) catch {
        std.debug.print("Error: File not found\n", .{});
        return;
    };

    file.close();
}
