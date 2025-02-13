const std = @import("std");
const builtin = @import("builtin");

pub const String = struct {
    buffer: ?[]u8,
    allocator: std.mem.Allocator,
    size: usize,

    /// Errors that may occur when using String
    pub const Error = error{
        OutOfMemory,
        InvalidRange,
    };

    pub fn init(allocator: std.mem.Allocator) String {
        // for windows non-ascii characters
        // check if the system is windows
        if (builtin.os.tag == std.Target.Os.Tag.windows) {
            _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
        }

        return .{
            .buffer = null,
            .allocator = allocator,
            .size = 0,
        };
    }

    /// Returns the UTF-8 character's size
    inline fn getUTF8Size(char: u8) u3 {
        return std.unicode.utf8ByteSequenceLength(char) catch {
            return 1;
        };
    }

    /// Deallocates the internal buffer
    /// ### usage:
    /// ```zig
    /// var str = String.init(allocator);
    /// // deinit after the closure
    /// defer _ = str.deinit();
    /// ```
    pub fn deinit(self: *String) void {
        if (self.buffer) |buffer| self.allocator.free(buffer);
    }

    /// Allocates space for the internal buffer
    pub fn allocate(self: *String, bytes: usize) Error!void {
        if (self.buffer) |buffer| {
            if (bytes < self.size) self.size = bytes; // Clamp size to capacity
            self.buffer = self.allocator.realloc(buffer, bytes) catch {
                return Error.OutOfMemory;
            };
        } else {
            self.buffer = self.allocator.alloc(u8, bytes) catch {
                return Error.OutOfMemory;
            };
        }
    }

    /// Returns amount of characters in the String
    pub fn len(self: String) usize {
        if (self.buffer) |buffer| {
            var length: usize = 0;
            var i: usize = 0;

            while (i < self.size) {
                i += String.getUTF8Size(buffer[i]);
                length += 1;
            }

            return length;
        } else {
            return 0;
        }
    }

    /// Returns the real index of a unicode string literal
    fn getIndex(unicode: []const u8, index: usize, real: bool) ?usize {
        var i: usize = 0;
        var j: usize = 0;
        while (i < unicode.len) {
            if (real) {
                if (j == index) return i;
            } else {
                if (i == index) return j;
            }
            i += String.getUTF8Size(unicode[i]);
            j += 1;
        }

        return null;
    }

    /// Inserts a string literal into the String at an index
    pub fn insert(self: *String, literal: []const u8, index: usize) Error!void {
        // Make sure buffer has enough space
        if (self.buffer) |buffer| {
            if (self.size + literal.len > buffer.len) {
                try self.allocate((self.size + literal.len) * 2);
            }
        } else {
            try self.allocate((literal.len) * 2);
        }

        const buffer = self.buffer.?;

        // If the index is >= len, then simply push to the end.
        // If not, then copy contents over and insert literal.
        if (index == self.len()) {
            var i: usize = 0;
            while (i < literal.len) : (i += 1) {
                buffer[self.size + i] = literal[i];
            }
        } else {
            if (String.getIndex(buffer, index, true)) |k| {
                // Move existing contents over
                var i: usize = buffer.len - 1;
                while (i >= k) : (i -= 1) {
                    if (i + literal.len < buffer.len) {
                        buffer[i + literal.len] = buffer[i];
                    }

                    if (i == 0) break;
                }

                i = 0;
                while (i < literal.len) : (i += 1) {
                    buffer[index + i] = literal[i];
                }
            }
        }

        self.size += literal.len;
    }

    pub fn insert_optimized(self: *String, literal: []const u8, index: usize) Error!void {
        const insert_len = literal.len;

        // Ensure enough space in buffer
        if (self.buffer) |buffer| {
            if (self.size + insert_len > buffer.len) {
                try self.allocate((self.size + insert_len) * 2);
            }
        } else {
            try self.allocate(insert_len * 2);
        }

        const buffer = self.buffer.?;

        // If inserting at the end, just append directly
        if (index == self.len()) {
            @memcpy(buffer[self.size .. self.size + insert_len], literal);
        } else {
            if (String.getIndex(buffer, index, true)) |k| {
                // Use `memmove()` for efficient shifting
                std.mem.copyBackwards(u8, buffer[k + insert_len ..], buffer[k..self.size]);

                // Copy the new text into place
                @memcpy(buffer[k .. k + insert_len], literal);
            }
        }

        self.size += insert_len;
    }

    /// Appends a character onto the end of the String
    pub fn concat(self: *String, char: []const u8) Error!void {
        //try self.insert(char, self.len());
        try self.insert_optimized(char, self.len());
    }
};
