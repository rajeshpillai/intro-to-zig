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

// -----------------------------
// invert(ptr, len)
// -----------------------------
pub export fn invert(ptr: u32, len: usize) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);

    var data = p[0..len];

    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        data[i] = 255 - data[i];         // invert R
        data[i + 1] = 255 - data[i + 1]; // invert G
        data[i + 2] = 255 - data[i + 2]; // invert B
        // alpha channel (i+3) remains unchanged
    }
}

// -----------------------------
// brightness(ptr, len, adjustment)
// -----------------------------
pub export fn brightness(ptr: u32, len: usize, adjustment: i32) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);

    var data = p[0..len];

    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        // Adjust each channel and clamp to 0-255
        const r: i32 = @as(i32, data[i]) + adjustment;
        const g: i32 = @as(i32, data[i + 1]) + adjustment;
        const b: i32 = @as(i32, data[i + 2]) + adjustment;

        data[i] = @intCast(@max(0, @min(255, r)));
        data[i + 1] = @intCast(@max(0, @min(255, g)));
        data[i + 2] = @intCast(@max(0, @min(255, b)));
    }
}

// -----------------------------
// threshold(ptr, len, threshold_value)
// -----------------------------
pub export fn threshold(ptr: u32, len: usize, threshold_value: u8) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);

    var data = p[0..len];

    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r = data[i];
        const g = data[i + 1];
        const b = data[i + 2];

        // Convert to grayscale first
        const gray: u8 = @intCast((r + g + b) / 3);

        // Apply threshold: black or white
        const result: u8 = if (gray >= threshold_value) 255 else 0;

        data[i] = result;
        data[i + 1] = result;
        data[i + 2] = result;
    }
}

// -----------------------------
// sepia(ptr, len)
// -----------------------------
pub export fn sepia(ptr: u32, len: usize) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);

    var data = p[0..len];

    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r: f32 = @floatFromInt(data[i]);
        const g: f32 = @floatFromInt(data[i + 1]);
        const b: f32 = @floatFromInt(data[i + 2]);

        // Sepia transformation matrix
        const new_r: f32 = (r * 0.393) + (g * 0.769) + (b * 0.189);
        const new_g: f32 = (r * 0.349) + (g * 0.686) + (b * 0.168);
        const new_b: f32 = (r * 0.272) + (g * 0.534) + (b * 0.131);

        // Clamp to 0-255
        data[i] = @intFromFloat(@min(255.0, new_r));
        data[i + 1] = @intFromFloat(@min(255.0, new_g));
        data[i + 2] = @intFromFloat(@min(255.0, new_b));
    }
}