//  Spawning Multiple Threads

const std = @import("std");

fn worker(id: usize) void {
    std.debug.print("Worker {} started\n", .{id});
}

pub fn main() !void {
    var threads: [5]std.Thread = undefined;

    for (0..5) |i| {
        threads[i] = try std.Thread.spawn(.{}, worker, .{i}); // Convert usize → i32
    }

    // Pass &threads in for (&threads) |*t|
    // The & ensures we're iterating over a reference to threads.
    // This allows |*t| to capture each element by reference.
    for (&threads) |*t| {
        t.join(); // Wait for all threads to finish
    }

    std.debug.print("All threads completed\n", .{});
}
