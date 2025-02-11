const std = @import("std");

// Trimming spaces from both ends of a string
fn trimString(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " ");
}

// Concatenating multiple strings
fn concatenateStrings(allocator: std.mem.Allocator, strings: []const []const u8) ![]const u8 {
    return try std.mem.concat(allocator, u8, strings);
}

// Convert to uppercase (Fix: Use dynamic allocation)
fn toUpperCase(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, text.len);
    @memcpy(result, text);
    _ = std.ascii.upperString(result, result);
    return result;
}

// Convert to lowercase (Fix: Use dynamic allocation)
fn toLowerCase(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, text.len);
    @memcpy(result, text);
    _ = std.ascii.lowerString(result, result);
    return result;
}

// Reverse a string
fn reverseString(text: []u8) void {
    var left: usize = 0;
    var right: usize = text.len - 1;

    while (left < right) {
        const temp = text[left];
        text[left] = text[right];
        text[right] = temp;

        left += 1;
        right -= 1;
    }
}

// Replacing a substring in a string
fn replaceSubstring(allocator: std.mem.Allocator, text: []const u8, old: []const u8, new: []const u8) ![]const u8 {
    return try std.mem.replaceOwned(u8, allocator, text, old, new);
}

// Convert string to integer
fn parseInteger(text: []const u8) ?i32 {
    return std.fmt.parseInt(i32, text, 10) catch null;
}

// Convert string to float
fn parseFloat(text: []const u8) ?f64 {
    return std.fmt.parseFloat(f64, text) catch null;
}

// Check if a string contains only numbers
fn isNumeric(text: []const u8) bool {
    for (text) |char| {
        if (!std.ascii.isDigit(char) and char != '.' and char != '-') {
            return false;
        }
    }
    return true;
}

// Main function to demonstrate string operations
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const text = "   Zig is great!   ";
    const trimmed = trimString(text);
    std.debug.print("Trimmed: '{s}'\n", .{trimmed});

    const part1 = "Hello, ";
    const part2 = "Zig!";
    const concatenated = try concatenateStrings(allocator, &[_][]const u8{ part1, part2 });
    defer allocator.free(concatenated);
    std.debug.print("Concatenated: '{s}'\n", .{concatenated});

    const upper = try toUpperCase(allocator, "zig");
    defer allocator.free(upper);

    const lower = try toLowerCase(allocator, "ZIG");
    defer allocator.free(lower);

    std.debug.print("Upper: '{s}', Lower: '{s}'\n", .{ upper, lower });
    var textToReverse = "ZigLang".*; // Convert to mutable array
    reverseString(&textToReverse);
    std.debug.print("Reversed: '{s}'\n", .{textToReverse});

    const original = "Zig is fun";
    const replaced = try replaceSubstring(allocator, original, "fun", "powerful");
    defer allocator.free(replaced);
    std.debug.print("Replaced: '{s}'\n", .{replaced});

    const numText = "1234";
    const parsedInt = parseInteger(numText);
    std.debug.print("Parsed Integer: {?}\n", .{parsedInt});

    const floatText = "3.14159";
    const parsedFloat = parseFloat(floatText);
    std.debug.print("Parsed Float: {?}\n", .{parsedFloat});

    const numericCheck1 = isNumeric("1234");
    const numericCheck2 = isNumeric("12abc");
    std.debug.print("Is '1234' numeric? {}\n", .{numericCheck1});
    std.debug.print("Is '12abc' numeric? {}\n", .{numericCheck2});
}
