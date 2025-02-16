// Running Code in a Separate Thread

// Explanation
// ✅ std.Thread.spawn() starts a new thread.
// ✅ worker() runs in a separate thread.
// ✅ thread.join() waits for the thread to finish execution.

// Why is a Pointer Passed Instead of a Value?
// Threads execute independently

// If you pass value by value (i32), the function will get a copy.
// Changes to that copy won’t affect the original value.
// Pointers allow shared access

// Passing &value means the worker function operates on the original variable.
// Multiple threads can share and modify the same data.

const std = @import("std");

fn worker(context: *i32) void {
    std.debug.print("Thread running with value: {}\n", .{context.*});
}

fn worker2(context: i32) void {
    std.debug.print("Thread running with value: {}\n", .{context});
}

pub fn main() !void {
    var value: i32 = 49;

    // Pass pointer
    var thread = try std.Thread.spawn(.{}, worker, .{&value});

    // Pass value
    var thread2 = try std.Thread.spawn(.{}, worker2, .{value});

    thread.join(); // Wait for the thread to finish
    thread2.join();
}
