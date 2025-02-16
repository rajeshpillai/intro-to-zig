const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("output.txt", .{});
    defer file.close();

    var buffer: [100]u8 = undefined;
    const bytes_read = try file.reader().read(&buffer);

    std.debug.print("Read {d} bytes: {s}\n", .{ bytes_read, buffer[0..bytes_read] });
}
