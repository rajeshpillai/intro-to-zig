const std = @import("std");

// Zig allocator for WASM memory
var allocator = std.heap.wasm_allocator;

// -----------------------------
// Memory Management
// -----------------------------
pub export fn alloc(size: usize) u32 {
    const buf = allocator.alloc(u8, size) catch unreachable;
    const addr = @intFromPtr(buf.ptr);
    return @intCast(addr);
}

pub export fn free(ptr: u32, size: usize) void {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const slice = p[0..size];
    allocator.free(slice);
}

// -----------------------------
// analyzeBrightness(ptr, len) → average brightness (0-255)
// -----------------------------
pub export fn analyzeBrightness(ptr: u32, len: usize) u32 {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    var sum: u64 = 0;
    var count: u64 = 0;
    
    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r: u64 = data[i];
        const g: u64 = data[i + 1];
        const b: u64 = data[i + 2];
        
        // Calculate luminance using standard weights
        const brightness: u64 = (r * 299 + g * 587 + b * 114) / 1000;
        sum += brightness;
        count += 1;
    }
    
    if (count == 0) return 0;
    const avg: u32 = @intCast(sum / count);
    return avg;
}

// -----------------------------
// detectBlur(ptr, len, width, height) → blur score (0-10000)
// Uses Laplacian variance - lower values = more blur
// -----------------------------
pub export fn detectBlur(ptr: u32, len: usize, width: u32, height: u32) u32 {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    
    // Laplacian kernel
    // [ 0  1  0 ]
    // [ 1 -4  1 ]
    // [ 0  1  0 ]
    
    var sum: i64 = 0;
    var sum_sq: i64 = 0;
    var count: i64 = 0;
    
    var y: usize = 1;
    while (y < h - 1) : (y += 1) {
        var x: usize = 1;
        while (x < w - 1) : (x += 1) {
            const idx = (y * w + x) * 4;
            const center: i32 = @intCast(data[idx]); // Use red channel
            
            const top: i32 = @intCast(data[((y - 1) * w + x) * 4]);
            const bottom: i32 = @intCast(data[((y + 1) * w + x) * 4]);
            const left: i32 = @intCast(data[(y * w + (x - 1)) * 4]);
            const right: i32 = @intCast(data[(y * w + (x + 1)) * 4]);
            
            const laplacian: i32 = -4 * center + top + bottom + left + right;
            
            sum += laplacian;
            sum_sq += laplacian * laplacian;
            count += 1;
        }
    }
    
    if (count == 0) return 0;
    
    // Calculate variance
    const mean: i64 = @divTrunc(sum, count);
    const variance: i64 = @divTrunc(sum_sq, count) - (mean * mean);
    
    // Return variance clamped to u32 range
    const result: u32 = @intCast(@min(10000, @max(0, variance)));
    return result;
}

// -----------------------------
// detectSkinTone(ptr, len, width, height) → skin pixel percentage (0-100)
// Simplified skin detection using RGB ranges
// -----------------------------
pub export fn detectSkinTone(ptr: u32, len: usize, width: u32, height: u32) u32 {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    
    var skin_pixels: u32 = 0;
    var total_pixels: u32 = 0;
    
    var y: usize = 0;
    while (y < h) : (y += 1) {
        var x: usize = 0;
        while (x < w) : (x += 1) {
            const idx = (y * w + x) * 4;
            const r: u32 = data[idx];
            const g: u32 = data[idx + 1];
            const b: u32 = data[idx + 2];
            
            // Skin tone detection heuristic (simplified)
            // Typical skin: R > 95, G > 40, B > 20
            // R > G, R > B, |R - G| > 15
            if (r > 95 and g > 40 and b > 20 and
                r > g and r > b and (r - g) > 15) {
                skin_pixels += 1;
            }
            
            total_pixels += 1;
        }
    }
    
    if (total_pixels == 0) return 0;
    
    // Return percentage (0-100)
    const percentage: u32 = (skin_pixels * 100) / total_pixels;
    return percentage;
}

// -----------------------------
// detectFacePresence(ptr, len, width, height) → confidence score (0-100)
// Combines skin tone detection with spatial analysis
// -----------------------------
pub export fn detectFacePresence(ptr: u32, len: usize, width: u32, height: u32) u32 {
    const skin_percentage = detectSkinTone(ptr, len, width, height);
    
    // Face typically occupies 5-30% of frame with skin tones
    // Score based on how close to ideal range
    var score: u32 = 0;
    
    if (skin_percentage >= 5 and skin_percentage <= 30) {
        // Ideal range - high score
        const bonus: u32 = @min(20, skin_percentage - 5);
        score = 80 + bonus;
    } else if (skin_percentage > 30 and skin_percentage <= 50) {
        // Too much skin (maybe too close or multiple people)
        score = 60;
    } else if (skin_percentage > 0 and skin_percentage < 5) {
        // Some skin but maybe far away
        score = 40;
    } else {
        // No skin detected or unrealistic amount
        score = 0;
    }
    
    return score;
}

// -----------------------------
// calculateMotion(ptr, prev_ptr, len) → motion score (0-10000)
// Frame difference to detect movement
// -----------------------------
pub export fn calculateMotion(ptr: u32, prev_ptr: u32, len: usize) u32 {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const prev_addr: usize = @intCast(prev_ptr);
    const prev_p: [*]u8 = @ptrFromInt(prev_addr);
    const prev_data = prev_p[0..len];
    
    var diff_sum: u64 = 0;
    var count: u64 = 0;
    
    var i: usize = 0;
    while (i + 3 < len) : (i += 4) {
        const r_diff: i32 = @as(i32, data[i]) - @as(i32, prev_data[i]);
        const g_diff: i32 = @as(i32, data[i + 1]) - @as(i32, prev_data[i + 1]);
        const b_diff: i32 = @as(i32, data[i + 2]) - @as(i32, prev_data[i + 2]);
        
        const total_diff: u32 = @intCast(@abs(r_diff) + @abs(g_diff) + @abs(b_diff));
        diff_sum += total_diff;
        count += 1;
    }
    
    if (count == 0) return 0;
    
    const avg_diff: u32 = @intCast(diff_sum / count);
    return avg_diff;
}

// -----------------------------
// detectCheating(ptr, len, width, height, prev_ptr, prev_brightness) → bitfield
// Bit 0: Multiple faces (high skin percentage)
// Bit 1: Sudden brightness change
// Bit 2: Excessive motion
// Bit 3: No face detected
// Bit 4: Looking away (face position changed - simplified as high motion)
// -----------------------------
pub export fn detectCheating(
    ptr: u32,
    len: usize,
    width: u32,
    height: u32,
    prev_ptr: u32,
    prev_brightness: u32
) u32 {
    var flags: u32 = 0;
    
    // Check face presence
    const face_score = detectFacePresence(ptr, len, width, height);
    const skin_percentage = detectSkinTone(ptr, len, width, height);
    
    // Bit 3: No face detected
    if (face_score < 30) {
        flags |= (1 << 3);
    }
    
    // Bit 0: Multiple faces (too much skin)
    if (skin_percentage > 40) {
        flags |= (1 << 0);
    }
    
    // Bit 1: Sudden brightness change (screen reflection or lighting change)
    const current_brightness = analyzeBrightness(ptr, len);
    const brightness_diff: i32 = @as(i32, @intCast(current_brightness)) - @as(i32, @intCast(prev_brightness));
    if (@abs(brightness_diff) > 50) {
        flags |= (1 << 1);
    }
    
    // Bit 2 & 4: Excessive motion (looking away or moving around)
    if (prev_ptr != 0) {
        const motion = calculateMotion(ptr, prev_ptr, len);
        
        // Excessive motion threshold
        if (motion > 30) {
            flags |= (1 << 2);
        }
        
        // Very high motion = looking away
        if (motion > 50) {
            flags |= (1 << 4);
        }
    }
    
    return flags;
}

// -----------------------------
// Helper: Count faces in different regions (simplified grid-based)
// Returns number of regions with significant skin tone
// -----------------------------
pub export fn countFaceRegions(ptr: u32, len: usize, width: u32, height: u32) u32 {
    const addr: usize = @intCast(ptr);
    const p: [*]u8 = @ptrFromInt(addr);
    const data = p[0..len];
    
    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    
    // Divide frame into 9 regions (3x3 grid)
    const region_w = w / 3;
    const region_h = h / 3;
    
    var regions_with_faces: u32 = 0;
    
    var ry: usize = 0;
    while (ry < 3) : (ry += 1) {
        var rx: usize = 0;
        while (rx < 3) : (rx += 1) {
            var skin_in_region: u32 = 0;
            var total_in_region: u32 = 0;
            
            const start_y = ry * region_h;
            const end_y = @min((ry + 1) * region_h, h);
            const start_x = rx * region_w;
            const end_x = @min((rx + 1) * region_w, w);
            
            var y = start_y;
            while (y < end_y) : (y += 1) {
                var x = start_x;
                while (x < end_x) : (x += 1) {
                    const idx = (y * w + x) * 4;
                    const r: u32 = data[idx];
                    const g: u32 = data[idx + 1];
                    const b: u32 = data[idx + 2];
                    
                    if (r > 95 and g > 40 and b > 20 and
                        r > g and r > b and (r - g) > 15) {
                        skin_in_region += 1;
                    }
                    total_in_region += 1;
                }
            }
            
            // If region has >10% skin, count as potential face
            if (total_in_region > 0) {
                const region_percentage = (skin_in_region * 100) / total_in_region;
                if (region_percentage > 10) {
                    regions_with_faces += 1;
                }
            }
        }
    }
    
    return regions_with_faces;
}
