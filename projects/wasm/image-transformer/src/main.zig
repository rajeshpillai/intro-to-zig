const std = @import("std");

// JS provides the WebAssembly linear memory
extern "env" var memory: *anyopaque;

var allocator = std.heap.wasm_allocator;

// -------------------------------
// Helper: convert env.memory → many-pointer
// -------------------------------
fn wasmMem() [*]u8 {
    return @as([*]u8, @ptrCast(memory));
}

// -------------------------------
// alloc(size) → u32 pointer offset
// -------------------------------
pub export fn alloc(size: usize) u32 {
    const buf = allocator.alloc(u8, size) catch unreachable;

    const addr_usize = @intFromPtr(buf.ptr);
    const addr_u32: u32 = @intCast(addr_usize);

    return addr_u32;
}

// -------------------------------
// free(ptr, size)
// -------------------------------
pub export fn free(ptr: u32, size: usize) void {
    const addr: usize = @intCast(ptr);

    // convert to many-pointer
    const p_many: [*]u8 = @as([*]u8, @ptrFromInt(addr));

    const slice = p_many[0..size];
    allocator.free(slice);
}

// -------------------------------
// grayscale(ptr, len)
// -------------------------------
pub export fn grayscale(ptr: u32, len: usize) void {
    const addr: usize = @intCast(ptr);

    // convert to many-pointer (CRITICAL!)
    const p_many: [*]u8 = @as([*]u8, @ptrFromInt(addr));
    var data = p_many[0..len];

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
