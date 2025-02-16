// Let’s build a multi-threaded number processor that distributes
// work across multiple threads.

const std = @import("std");

fn process_number(id: usize, number: i32) void {
    std.debug.print("Worker {} processed number {}\n", .{ id, number });
}

pub fn main() !void {
    const numbers = [_]i32{ 10, 20, 30, 40, 50 };
    var threads: [5]std.Thread = undefined;

    for (numbers, 0..) |num, i| {
        threads[i] = try std.Thread.spawn(.{}, process_number, .{ i, num });
    }

    for (&threads) |*t| {
        t.join();
    }

    std.debug.print("Processing completed\n", .{});
}
