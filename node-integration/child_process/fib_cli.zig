const std = @import("std");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    if (args.len < 2) {
        std.debug.print("Usage: fib <n>\n", .{});
        return;
    }

    const n = try std.fmt.parseInt(u64, args[1], 10);
    const result = fibonacci(n);

    // Use stdout writer explicitly
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{}\n", .{result});
}

fn fibonacci(n: u64) u64 {
    if (n == 0) return 0;
    if (n == 1) return 1;

    var a: u64 = 0;
    var b: u64 = 1;
    var i: u64 = 2;

    while (i <= n) : (i += 1) {
        const next = a + b;
        a = b;
        b = next;
    }

    return b;
}
