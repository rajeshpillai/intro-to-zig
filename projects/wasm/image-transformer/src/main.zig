const std = @import("std");

// Import the JS-provided WebAssembly memory buffer
extern "env" var memory_base: [*]u8;

// Zig allocator for WASM memory
var allocator = std.heap.wasm_allocator;

// -----------------------------
// alloc(size) → pointer offset
// -----------------------------
pub export fn alloc(size: usize) u32 {
    const buf = allocator.alloc(u8, size) catch unreachable;

    const addr = @intFromPtr(buf.ptr);
    return @intCast(addr);
}

// -----------------------------
// free(ptr, size)
// -----------------------------
pub export fn free(ptr: u32, size: usize) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);

    const slice = p[0..size];
    allocator.free(slice);
}

// -----------------------------
// grayscale(ptr, len)
// -----------------------------
pub export fn grayscale(ptr: u32, len: usize) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);

    var data = p[0..len];

    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r = data[i];
        const g = data[i + 1];
        const b = data[i + 2];

        const gray: u8 = @intCast((r + g + b) / 3);

        data[i] = gray;
        data[i + 1] = gray;
        data[i + 2] = gray;
    }
}
