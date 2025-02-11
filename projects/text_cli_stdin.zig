// Usage:
// echo "Hello Zig, you are awesome!" | zig run text_cli_stdin.zig -- wc
// echo "Line 1\nLine 2\nLine 3" | zig run text_cli_stdin.zig -- lc

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.args();
    _ = args.next(); // Skip program name

    const command = args.next() orelse {
        std.debug.print("Usage: textcli <command> [args]\n", .{});
        std.debug.print("Commands:\n", .{});
        std.debug.print("  wc                - Word count\n", .{});
        std.debug.print("  lc                - Line count\n", .{});
        std.debug.print("  find <word>       - Find occurrences of a word\n", .{});
        std.debug.print("  replace <old> <new> - Replace a word\n", .{});
        return;
    };

    const input = try readInput(allocator);
    defer allocator.free(input); // Free memory

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
        try replaceWord(allocator, input, old, new);
    } else {
        std.debug.print("❌ Unknown command: '{s}'\n", .{command});
    }
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

fn replaceWord(allocator: std.mem.Allocator, text: []const u8, old: []const u8, new: []const u8) !void {
    const replaced = try std.mem.replaceOwned(u8, allocator, text, old, new);
    defer allocator.free(replaced);
    std.debug.print("✅ Replaced text:\n{s}\n", .{replaced});
}
