const std = @import("std");

var allocator = std.heap.wasm_allocator;

const Particle = struct {
    x: f32,
    y: f32,
    vx: f32,
    vy: f32,
    color: u32,
};

var particles: []Particle = &[_]Particle{};
var width: u32 = 0;
var height: u32 = 0;
var pixel_buffer: []u8 = &[_]u8{};

// PRNG state
var prng_state: u64 = 12345;
fn random_f32() f32 {
    prng_state = prng_state *% 6364136223846793005 +% 1442695040888963407;
    const val: u32 = @intCast(prng_state >> 32);
    return @as(f32, @floatFromInt(val)) / @as(f32, @floatFromInt(std.math.maxInt(u32)));
}

pub export fn init(w: u32, h: u32, count: u32) void {
    width = w;
    height = h;

    // Free existing memory if any
    if (particles.len > 0) allocator.free(particles);
    if (pixel_buffer.len > 0) allocator.free(pixel_buffer);

    // Allocate particle array
    particles = allocator.alloc(Particle, count) catch unreachable;

    // Allocate pixel buffer (RGBA)
    pixel_buffer = allocator.alloc(u8, w * h * 4) catch unreachable;

    // Initialize particles
    for (particles) |*p| {
        p.x = random_f32() * @as(f32, @floatFromInt(w));
        p.y = random_f32() * @as(f32, @floatFromInt(h));
        p.vx = (random_f32() - 0.5) * 4.0;
        p.vy = (random_f32() - 0.5) * 4.0;
        
        // Random bright color
        const r: u32 = @intFromFloat(150.0 + random_f32() * 105.0);
        const g: u32 = @intFromFloat(150.0 + random_f32() * 105.0);
        const b: u32 = @intFromFloat(150.0 + random_f32() * 105.0);
        p.color = (0xFF << 24) | (b << 16) | (g << 8) | r;
    }
}

pub export fn update(dt: f32, gravity: f32) void {
    const fw = @as(f32, @floatFromInt(width));
    const fh = @as(f32, @floatFromInt(height));

    // Clear buffer (fade to black for trail effect)
    // To make it simpler for now, just clear to black
    @memset(pixel_buffer, 0);

    for (particles) |*p| {
        // Apply physics
        p.vy += gravity * dt;
        p.x += p.vx;
        p.y += p.vy;

        // Bounds checking with bounce
        if (p.x < 0) {
            p.x = 0;
            p.vx *= -0.8;
        } else if (p.x >= fw) {
            p.x = fw - 1;
            p.vx *= -0.8;
        }

        if (p.y < 0) {
            p.y = 0;
            p.vy *= -0.8;
        } else if (p.y >= fh) {
            p.y = fh - 1;
            p.vy *= -0.8;
        }

        // Draw particle (one pixel for now, for speed)
        const ix: i32 = @intFromFloat(p.x);
        const iy: i32 = @intFromFloat(p.y);
        
        if (ix >= 0 and ix < @as(i32, @intCast(width)) and iy >= 0 and iy < @as(i32, @intCast(height))) {
            const base_idx = (@as(usize, @intCast(iy)) * width + @as(usize, @intCast(ix))) * 4;
            
            const r: u8 = @intCast(p.color & 0xFF);
            const g: u8 = @intCast((p.color >> 8) & 0xFF);
            const b: u8 = @intCast((p.color >> 16) & 0xFF);
            const a: u8 = @intCast((p.color >> 24) & 0xFF);

            pixel_buffer[base_idx] = r;
            pixel_buffer[base_idx + 1] = g;
            pixel_buffer[base_idx + 2] = b;
            pixel_buffer[base_idx + 3] = a;
        }
    }
}

pub export fn getBufferPtr() [*]u8 {
    return pixel_buffer.ptr;
}

pub export fn getBufferSize() usize {
    return pixel_buffer.len;
}
