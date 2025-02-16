// Synchronization Using Atomic Operations
// When multiple threads modify shared memory, race conditions can occur.
// Zig provides atomic operations to ensure safe concurrent access.

// Example: Atomic Counter Using std.atomic

const std = @import("std");

var counter: std.atomic.Value(i32) = std.atomic.Value(i32).init(0);

fn worker() void {
    // Uses fetchAdd(1, .seq_cst) to atomically increment counter.
    // Ensures all threads see updates in the same order.
    _ = counter.fetchAdd(1, .seq_cst);
}

pub fn main() !void {
    var threads: [5]std.Thread = undefined;

    // ✔ Creates 5 threads, each running worker().
    // ✔ Each thread increments counter by 1 atomically.

    for (0..5) |i| {
        threads[i] = try std.Thread.spawn(.{}, worker, .{});
    }

    // ✔ Ensures the main thread waits until all threads finish execution.
    for (&threads) |*t| {
        t.join();
    }

    // ✔ Uses counter.load(.seq_cst) to retrieve the final value atomically.
    // ✔ Ensures the read happens after all writes.

    std.debug.print("Final counter value: {}\n", .{counter.load(.seq_cst)});
}
