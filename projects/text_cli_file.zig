// ==========================================================================
// Zig Text Processing CLI Tool
// ==========================================================================
//
// Usage Examples:
//
// 1️⃣ Word Count in Multiple Files:
//    zig run text_cli_file.zig -- wc file1.txt file2.txt
//
// 2️⃣ Line Count in Multiple Files:
//    zig run text_cli_file.zig -- lc file1.txt file2.txt
//
// 3️⃣ Find a Word in Multiple Files:
//    zig run text_cli_file.zig -- find Zig file1.txt file2.txt
//
// 4️⃣ Replace a Word in Multiple Files and Save Output:
//    zig run text_cli_file.zig -- replace old new file1.txt file2.txt output.txt
//
// --------------------------------------------------------------------------
// Why `--` is Needed?
// - When running with `zig run`, the `--` ensures that file names and options
//   are passed to the program instead of being treated as Zig source files.
//
// - Example of incorrect usage (will fail):
//    zig run text_cli_file.zig wc file1.txt file2.txt  ❌
//
// - Correct usage with `--`:
//    zig run text_cli_file.zig -- wc file1.txt file2.txt ✅
//
// --------------------------------------------------------------------------
// Alternative: Build the Executable
// - To avoid using `zig run`, build the binary and run it directly:
//
//    $ zig build-exe text_cli_file.zig -O ReleaseSafe -o textcli
//    $ ./textcli wc file1.txt file2.txt
//
// ==========================================================================
//

const std = @import("std");

fn readFile(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close(); // Ensure the file closes after reading

    const stat = try file.stat();
    const buffer = try allocator.alloc(u8, stat.size);

    _ = try file.reader().readAll(buffer);
    return buffer;
}

fn readMultipleFiles(allocator: std.mem.Allocator, filenames: [][]const u8) ![]u8 {
    var combined_text = std.ArrayList(u8).init(allocator);
    defer combined_text.deinit(); // Ensure cleanup

    for (filenames) |filename| {
        const file_content = try readFile(allocator, filename);
        defer allocator.free(file_content);

        try combined_text.appendSlice(file_content);
        try combined_text.appendSlice("\n"); // Add a newline between files
    }

    return try combined_text.toOwnedSlice();
}

fn writeFile(filename: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().createFile(filename, .{ .truncate = true });
    defer file.close();

    _ = try file.writer().writeAll(content);
    std.debug.print("✅ Output saved to: {s}\n", .{filename});
}

fn readInput(allocator: std.mem.Allocator) ![]u8 {
    const stdin = std.io.getStdIn();
    var buffer: [1024]u8 = undefined;
    const bytes_read = try stdin.reader().read(&buffer);

    return try allocator.dupe(u8, buffer[0..bytes_read]);
}

fn wordCount(text: []const u8) void {
    var count: usize = 0;
    var parts = std.mem.splitSequence(u8, text, " ");
    while (parts.next()) |_| {
        count += 1;
    }
    std.debug.print("📌 Word count: {}\n", .{count});
}

fn lineCount(text: []const u8) void {
    var count: usize = 0;
    var parts = std.mem.splitSequence(u8, text, "\n");
    while (parts.next()) |_| {
        count += 1;
    }
    std.debug.print("📌 Line count: {}\n", .{count});
}

fn findWord(text: []const u8, word: []const u8) void {
    const index = std.mem.indexOf(u8, text, word) orelse {
        std.debug.print("❌ Word '{s}' not found.\n", .{word});
        return;
    };
    std.debug.print("✅ Word '{s}' found at index {}\n", .{ word, index });
}

fn replaceWord(allocator: std.mem.Allocator, text: []const u8, old: []const u8, new: []const u8) ![]const u8 {
    return try std.mem.replaceOwned(u8, allocator, text, old, new);
}

// The entry point
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.args();
    _ = args.next(); // Skip program name

    const command = args.next() orelse {
        std.debug.print("Usage: textcli <command> [args]\n", .{});
        return;
    };

    // Collect all filenames
    var filenames = std.ArrayList([]const u8).init(allocator);
    defer filenames.deinit();

    while (args.next()) |filename| {
        try filenames.append(filename);
    }

    // Read input from multiple files
    const input = try readMultipleFiles(allocator, filenames.items);
    defer allocator.free(input);

    if (std.mem.eql(u8, command, "wc")) {
        wordCount(input);
    } else if (std.mem.eql(u8, command, "lc")) {
        lineCount(input);
    } else if (std.mem.eql(u8, command, "find")) {
        const word = args.next() orelse {
            std.debug.print("❌ Please specify a word to find.\n", .{});
            return;
        };
        findWord(input, word);
    } else if (std.mem.eql(u8, command, "replace")) {
        const old = args.next() orelse {
            std.debug.print("❌ Please specify the word to replace.\n", .{});
            return;
        };
        const new = args.next() orelse {
            std.debug.print("❌ Please specify the new word.\n", .{});
            return;
        };

        const output_filename = args.next() orelse null;
        const replaced = try replaceWord(allocator, input, old, new);

        if (output_filename) |outfile| {
            try writeFile(outfile, replaced);
        } else {
            std.debug.print("✅ Replaced text:\n{s}\n", .{replaced});
        }

        allocator.free(replaced);
    } else {
        std.debug.print("❌ Unknown command: '{s}'\n", .{command});
    }
}
