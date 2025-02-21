const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var scratch = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const f = try std.fs.cwd().openFile("test.md", .{});
    const scratch_data = try f.readToEndAlloc(scratch.allocator(), 1 * 1024 * 1024);

    const markdown_content = try arena.allocator().dupe(u8, scratch_data);
    _ = scratch.reset(.retain_capacity);

    std.debug.print("{s}\n", .{markdown_content});
}
