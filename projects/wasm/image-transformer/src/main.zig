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

// -----------------------------
// sobel(ptr, len, width, height) - Edge Detection
// -----------------------------
pub export fn sobel(ptr: u32, len: usize, width: u32, height: u32) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    
    // Allocate temporary buffer on heap
    const temp = allocator.alloc(u8, len) catch return;
    defer allocator.free(temp);
    
    // Copy original data
    for (data, 0..) |val, i| {
        temp[i] = val;
    }
    
    // Sobel kernels
    const gx = [_]i32{ -1, 0, 1, -2, 0, 2, -1, 0, 1 };
    const gy = [_]i32{ -1, -2, -1, 0, 0, 0, 1, 2, 1 };
    
    var y: usize = 1;
    while (y < h - 1) : (y += 1) {
        var x: usize = 1;
        while (x < w - 1) : (x += 1) {
            var pixel_x: i32 = 0;
            var pixel_y: i32 = 0;
            
            // Apply kernels
            var ky: usize = 0;
            while (ky < 3) : (ky += 1) {
                var kx: usize = 0;
                while (kx < 3) : (kx += 1) {
                    const px = x + kx - 1;
                    const py = y + ky - 1;
                    const idx = (py * w + px) * 4;
                    const gray: i32 = @intCast(temp[idx]);
                    
                    const k_idx = ky * 3 + kx;
                    pixel_x += gray * gx[k_idx];
                    pixel_y += gray * gy[k_idx];
                }
            }
            
            const magnitude: i32 = @intCast(@abs(pixel_x) + @abs(pixel_y));
            const edge: u8 = @intCast(@min(255, magnitude));
            
            const idx = (y * w + x) * 4;
            data[idx] = edge;
            data[idx + 1] = edge;
            data[idx + 2] = edge;
        }
    }
}

// -----------------------------
// gaussian(ptr, len, width, height) - Blur
// -----------------------------
pub export fn gaussian(ptr: u32, len: usize, width: u32, height: u32) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    
    // Allocate temporary buffer on heap
    const temp = allocator.alloc(u8, len) catch return;
    defer allocator.free(temp);
    
    for (data, 0..) |val, i| {
        temp[i] = val;
    }
    
    // Gaussian kernel (normalized)
    const kernel = [_]f32{ 1.0, 2.0, 1.0, 2.0, 4.0, 2.0, 1.0, 2.0, 1.0 };
    const kernel_sum: f32 = 16.0;
    
    var y: usize = 1;
    while (y < h - 1) : (y += 1) {
        var x: usize = 1;
        while (x < w - 1) : (x += 1) {
            var sum_r: f32 = 0;
            var sum_g: f32 = 0;
            var sum_b: f32 = 0;
            
            var ky: usize = 0;
            while (ky < 3) : (ky += 1) {
                var kx: usize = 0;
                while (kx < 3) : (kx += 1) {
                    const px = x + kx - 1;
                    const py = y + ky - 1;
                    const idx = (py * w + px) * 4;
                    
                    const k_idx = ky * 3 + kx;
                    const k_val = kernel[k_idx];
                    
                    sum_r += @as(f32, @floatFromInt(temp[idx])) * k_val;
                    sum_g += @as(f32, @floatFromInt(temp[idx + 1])) * k_val;
                    sum_b += @as(f32, @floatFromInt(temp[idx + 2])) * k_val;
                }
            }
            
            const idx = (y * w + x) * 4;
            data[idx] = @intFromFloat(sum_r / kernel_sum);
            data[idx + 1] = @intFromFloat(sum_g / kernel_sum);
            data[idx + 2] = @intFromFloat(sum_b / kernel_sum);
        }
    }
}

// -----------------------------
// color_matrix(ptr, len, matrix_ptr) - Generic Color Transform
// -----------------------------
pub export fn color_matrix(ptr: u32, len: usize, matrix_ptr: u32) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const m_addr: usize = @intCast(matrix_ptr);
    const m_p: [*]u8 = @ptrFromInt(m_addr);
    const matrix = m_p[0..9];
    
    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r: f32 = @floatFromInt(data[i]);
        const g: f32 = @floatFromInt(data[i + 1]);
        const b: f32 = @floatFromInt(data[i + 2]);
        
        // Convert matrix values back to floats (they were scaled in JS)
        const m0: f32 = @as(f32, @floatFromInt(matrix[0])) * 1.3 / 255.0;
        const m1: f32 = @as(f32, @floatFromInt(matrix[1])) * 1.3 / 255.0;
        const m2: f32 = @as(f32, @floatFromInt(matrix[2])) * 1.3 / 255.0;
        const m3: f32 = @as(f32, @floatFromInt(matrix[3])) * 1.3 / 255.0;
        const m4: f32 = @as(f32, @floatFromInt(matrix[4])) * 1.3 / 255.0;
        const m5: f32 = @as(f32, @floatFromInt(matrix[5])) * 1.3 / 255.0;
        const m6: f32 = @as(f32, @floatFromInt(matrix[6])) * 1.3 / 255.0;
        const m7: f32 = @as(f32, @floatFromInt(matrix[7])) * 1.3 / 255.0;
        const m8: f32 = @as(f32, @floatFromInt(matrix[8])) * 1.3 / 255.0;
        
        const new_r = (r * m0) + (g * m1) + (b * m2);
        const new_g = (r * m3) + (g * m4) + (b * m5);
        const new_b = (r * m6) + (g * m7) + (b * m8);
        
        data[i] = @intFromFloat(@min(255.0, @max(0.0, new_r)));
        data[i + 1] = @intFromFloat(@min(255.0, @max(0.0, new_g)));
        data[i + 2] = @intFromFloat(@min(255.0, @max(0.0, new_b)));
    }
}

// -----------------------------
// contrast(ptr, len, factor) - Adjust Contrast
// -----------------------------
pub export fn contrast(ptr: u32, len: usize, factor: i32) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    // Convert factor to multiplier (factor: -100 to 100)
    const f: f32 = @as(f32, @floatFromInt(factor)) / 100.0;
    const contrast_factor: f32 = (259.0 * (f * 100.0 + 255.0)) / (255.0 * (259.0 - f * 100.0));
    
    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r: f32 = @floatFromInt(data[i]);
        const g: f32 = @floatFromInt(data[i + 1]);
        const b: f32 = @floatFromInt(data[i + 2]);
        
        const new_r = contrast_factor * (r - 128.0) + 128.0;
        const new_g = contrast_factor * (g - 128.0) + 128.0;
        const new_b = contrast_factor * (b - 128.0) + 128.0;
        
        data[i] = @intFromFloat(@min(255.0, @max(0.0, new_r)));
        data[i + 1] = @intFromFloat(@min(255.0, @max(0.0, new_g)));
        data[i + 2] = @intFromFloat(@min(255.0, @max(0.0, new_b)));
    }
}

// -----------------------------
// saturation(ptr, len, factor) - Adjust Saturation
// -----------------------------
pub export fn saturation(ptr: u32, len: usize, factor: i32) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const sat: f32 = 1.0 + (@as(f32, @floatFromInt(factor)) / 100.0);
    
    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r: f32 = @floatFromInt(data[i]);
        const g: f32 = @floatFromInt(data[i + 1]);
        const b: f32 = @floatFromInt(data[i + 2]);
        
        // Calculate luminance
        const gray: f32 = 0.299 * r + 0.587 * g + 0.114 * b;
        
        // Interpolate between gray and original color
        const new_r = gray + sat * (r - gray);
        const new_g = gray + sat * (g - gray);
        const new_b = gray + sat * (b - gray);
        
        data[i] = @intFromFloat(@min(255.0, @max(0.0, new_r)));
        data[i + 1] = @intFromFloat(@min(255.0, @max(0.0, new_g)));
        data[i + 2] = @intFromFloat(@min(255.0, @max(0.0, new_b)));
    }
}

// -----------------------------
// nashville(ptr, len) - Instagram Nashville Filter
// -----------------------------
pub export fn nashville(ptr: u32, len: usize) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r: f32 = @floatFromInt(data[i]);
        const g: f32 = @floatFromInt(data[i + 1]);
        const b: f32 = @floatFromInt(data[i + 2]);
        
        // Warm pink/orange tint with slight desaturation
        const new_r = r * 1.2 + 20.0;
        const new_g = g * 1.05 + 10.0;
        const new_b = b * 0.9;
        
        data[i] = @intFromFloat(@min(255.0, new_r));
        data[i + 1] = @intFromFloat(@min(255.0, new_g));
        data[i + 2] = @intFromFloat(@min(255.0, new_b));
    }
}

// -----------------------------
// valencia(ptr, len) - Instagram Valencia Filter
// -----------------------------
pub export fn valencia(ptr: u32, len: usize) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r: f32 = @floatFromInt(data[i]);
        const g: f32 = @floatFromInt(data[i + 1]);
        const b: f32 = @floatFromInt(data[i + 2]);
        
        // Warm, faded look with yellow tint
        const new_r = r * 1.08 + 8.0;
        const new_g = g * 1.08 + 8.0;
        const new_b = b * 0.95;
        
        data[i] = @intFromFloat(@min(255.0, new_r));
        data[i + 1] = @intFromFloat(@min(255.0, new_g));
        data[i + 2] = @intFromFloat(@min(255.0, new_b));
    }
}

// -----------------------------
// inkwell(ptr, len) - High Contrast B&W
// -----------------------------
pub export fn inkwell(ptr: u32, len: usize) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r: f32 = @floatFromInt(data[i]);
        const g: f32 = @floatFromInt(data[i + 1]);
        const b: f32 = @floatFromInt(data[i + 2]);
        
        // High contrast grayscale
        const gray: f32 = 0.299 * r + 0.587 * g + 0.114 * b;
        const contrast_val: f32 = 1.3 * (gray - 128.0) + 128.0;
        const result: u8 = @intFromFloat(@min(255.0, @max(0.0, contrast_val)));
        
        data[i] = result;
        data[i + 1] = result;
        data[i + 2] = result;
    }
}

// -----------------------------
// lomo(ptr, len, width, height) - Lomo Effect
// -----------------------------
pub export fn lomo(ptr: u32, len: usize, width: u32, height: u32) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    const center_x: f32 = @as(f32, @floatFromInt(w)) / 2.0;
    const center_y: f32 = @as(f32, @floatFromInt(h)) / 2.0;
    const max_dist: f32 = @sqrt(center_x * center_x + center_y * center_y);
    
    var y: usize = 0;
    while (y < h) : (y += 1) {
        var x: usize = 0;
        while (x < w) : (x += 1) {
            const idx = (y * w + x) * 4;
            
            // Calculate distance from center
            const dx: f32 = @as(f32, @floatFromInt(x)) - center_x;
            const dy: f32 = @as(f32, @floatFromInt(y)) - center_y;
            const dist: f32 = @sqrt(dx * dx + dy * dy);
            const vignette_factor: f32 = 1.0 - (dist / max_dist) * 0.6;
            
            const r: f32 = @floatFromInt(data[idx]);
            const g: f32 = @floatFromInt(data[idx + 1]);
            const b: f32 = @floatFromInt(data[idx + 2]);
            
            // High contrast + vignette
            const new_r = (1.3 * (r - 128.0) + 128.0) * vignette_factor;
            const new_g = (1.3 * (g - 128.0) + 128.0) * vignette_factor;
            const new_b = (1.3 * (b - 128.0) + 128.0) * vignette_factor;
            
            data[idx] = @intFromFloat(@min(255.0, @max(0.0, new_r)));
            data[idx + 1] = @intFromFloat(@min(255.0, @max(0.0, new_g)));
            data[idx + 2] = @intFromFloat(@min(255.0, @max(0.0, new_b)));
        }
    }
}

// -----------------------------
// vignette(ptr, len, width, height) - Vignette Effect
// -----------------------------
pub export fn vignette(ptr: u32, len: usize, width: u32, height: u32) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    const center_x: f32 = @as(f32, @floatFromInt(w)) / 2.0;
    const center_y: f32 = @as(f32, @floatFromInt(h)) / 2.0;
    const max_dist: f32 = @sqrt(center_x * center_x + center_y * center_y);
    
    var y: usize = 0;
    while (y < h) : (y += 1) {
        var x: usize = 0;
        while (x < w) : (x += 1) {
            const idx = (y * w + x) * 4;
            
            const dx: f32 = @as(f32, @floatFromInt(x)) - center_x;
            const dy: f32 = @as(f32, @floatFromInt(y)) - center_y;
            const dist: f32 = @sqrt(dx * dx + dy * dy);
            const factor: f32 = 1.0 - (dist / max_dist) * 0.7;
            
            const r: f32 = @floatFromInt(data[idx]);
            const g: f32 = @floatFromInt(data[idx + 1]);
            const b: f32 = @floatFromInt(data[idx + 2]);
            
            data[idx] = @intFromFloat(r * factor);
            data[idx + 1] = @intFromFloat(g * factor);
            data[idx + 2] = @intFromFloat(b * factor);
        }
    }
}