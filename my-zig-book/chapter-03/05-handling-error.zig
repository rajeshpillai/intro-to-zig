const std = @import("std");

pub fn main() !void {
    const file = std.fs.cwd().openFile("nonexistent.txt", .{}) catch {
        std.debug.print("Error: File not found\n", .{});
        return;
    };
    file.close();
}
