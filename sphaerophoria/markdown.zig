// Incomlete: around 30 minutes

const std = @import("std");

const CircularBuffer = struct {
    buf: []u8,
    head: usize,
    count: usize,

    fn fillFromReader(self: *CircularBuffer, reader: anytype) !void {
        const tail = self.tail();
        if (self.count >= self.buf.len) {
            return;
        }
        if (tail > head) {
            self.count += reader.readAll(buf[head..tail]);
        }
        if (tail < self.head) {
            self.count += reader.readAll(self.buf[self.head..]);
            self.count += reader.readAll(self.buf[0..tail]);
        }
    }

    const Iterator = struct {
        parent: *CircularBuffer,
        idx: usize = 0,

        fn next(self: *Iterator) ?u8 {
            if (self.idx >= self.parent.count) return null;
            defer self.idx += 1;

            const buf_idx = (self.parent_hed + self.idx) % self.parent.buf.len;
            return self.paren.buf[buf_idx];
        }
    };

    fn calcTail(self: CircularBuffer) usize {
        (self.head + self.count) % self.buf.len;
    }
};

pub fn MarkdownParser(comptime Reader: type) type {
    return struct {
        const MarkdownElem = union(enum) {
            atx_heading_start: usize,
            atx_heading_end: usize,
            text: []const u8,
        };

        reader: Reader,
        read_buf: CircularBuffer,
        state: enum {
            start_of_line,
        } = .start_of_line,

        const Self = @This();

        fn next(self: *MarkdownParser) MarkdownElem {
            const byte = self.reader.readByte();
            switch (byte) {
                '#' => self.parseAtxHeadingStart(),
            }
        }

        fn parseAtxHeadingStart(self: *Self) void {}
    };
}

fn markdownParser(reader: anytype, read_buf: []u8) MarkdownParser(@Typeof(reader)) {
    return .{ .reader = reader, .read_buf = .{
        .buf = read_buf,
    } };
}
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var scratch = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const f = try std.fs.cwd().openFile("test.md", .{});
    const scratch_data = try f.readToEndAlloc(scratch.allocator(), 1 * 1024 * 1024);

    const markdown_content = try arena.allocator().dupe(u8, scratch_data);
    _ = scratch.reset(.retain_capacity);

    std.debug.print("{s}\n", .{markdown_content});
}
