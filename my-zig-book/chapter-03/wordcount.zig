// Building a Simple CLI Tool: Word Counter
// Let’s build a CLI tool that counts words in a file.

// Usage: zig run wordcount.zig -- <filename>

const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next(); // Skip program name

    const filename = args.next() orelse {
        std.debug.print("Usage: wordcount <filename>\n", .{});
        return;
    };

    var file = std.fs.cwd().openFile(filename, .{}) catch {
        std.debug.print("Error: could not open file '{s}'\n", .{filename});
        return;
    };

    defer file.close();
    var buffer: [1024]u8 = undefined;
    const bytes_read = try file.reader().read(&buffer);
    const content = buffer[0..bytes_read];

    var word_count: usize = 0;
    var iter = std.mem.tokenizeAny(u8, content, " \n\t");

    while (iter.next()) |_| {
        word_count += 1;
    }

    std.debug.print("File '{s}' contains {d} words\n", .{ filename, word_count });
}
