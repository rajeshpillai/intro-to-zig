// Zig allows switch-case for handling multiple cases elegantly.

const std = @import("std");

pub fn main() void {
    const day: i32 = 3;

    switch (day) {
        1 => std.debug.print("Monday\n", .{}),
        2 => std.debug.print("Tuesday\n", .{}),
        3 => std.debug.print("Wednesday\n", .{}),
        else => std.debug.print("Invalid day\n", .{}),
    }
}
