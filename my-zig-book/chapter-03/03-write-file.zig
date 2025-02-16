const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().createFile("output.txt", .{});
    defer file.close();

    try file.writer().writeAll("Hello, Zig File I/O!\n");
    std.debug.print("File written successfully!\n", .{});
}
