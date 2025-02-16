// Zig has two types of variables:
// 🔹 Mutable (var) – Can be changed after declaration.
// 🔹 Immutable (const) – Cannot be modified after assignment.

const std = @import("std");

pub fn main() void {
    var age: i32 = 25; // Mutable
    const name: []const u8 = "Alice"; // Immutable

    age += 5; // Allowed
    // name = "Bob"; // Error! Cannot modify a constant

    std.debug.print("Name: {s}, Age: {}\n", .{ name, age });
}
