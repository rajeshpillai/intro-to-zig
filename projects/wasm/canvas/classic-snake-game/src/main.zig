const std = @import("std");

var allocator = std.heap.wasm_allocator;

const GridSize = 20;
const CellSize = 20; // Pixels per cell
const Width = GridSize * CellSize;
const Height = GridSize * CellSize;

const Direction = enum(u8) {
    up = 0,
    right = 1,
    down = 2,
    left = 3,
};

const Point = struct {
    x: i32,
    y: i32,
};

var snake: [400]Point = undefined;
var snake_len: usize = 3;
var direction: Direction = .right;
var food: Point = .{ .x = 10, .y = 10 };
var pixel_buffer: []u8 = &[_]u8{};
var score: u32 = 0;
var game_over: bool = false;

// PRNG state
var prng_state: u64 = 12345;
fn random_range(min: i32, max: i32) i32 {
    prng_state = prng_state *% 6364136223846793005 +% 1442695040888963407;
    const val: u32 = @intCast(prng_state >> 32);
    return min + @as(i32, @intCast(val % @as(u32, @intCast(max - min))));
}

pub export fn init() void {
    snake_len = 3;
    snake[0] = .{ .x = 5, .y = 5 };
    snake[1] = .{ .x = 4, .y = 5 };
    snake[2] = .{ .x = 3, .y = 5 };
    direction = .right;
    score = 0;
    game_over = false;
    spawnFood();

    if (pixel_buffer.len == 0) {
        pixel_buffer = allocator.alloc(u8, Width * Height * 4) catch unreachable;
    }
    @memset(pixel_buffer, 0);
}

fn spawnFood() void {
    food.x = random_range(0, GridSize);
    food.y = random_range(0, GridSize);
}

pub export fn setDirection(dir: u8) void {
    const new_dir: Direction = @enumFromInt(dir);
    // Prevent 180 degree turns
    const is_opposite = case: {
        if (direction == .up and new_dir == .down) break :case true;
        if (direction == .down and new_dir == .up) break :case true;
        if (direction == .left and new_dir == .right) break :case true;
        if (direction == .right and new_dir == .left) break :case true;
        break :case false;
    };
    if (!is_opposite) direction = new_dir;
}

pub export fn update() bool {
    if (game_over) return false;

    // Head position
    var head = snake[0];
    switch (direction) {
        .up => head.y -= 1,
        .right => head.x += 1,
        .down => head.y += 1,
        .left => head.x -= 1,
    }

    // Boundary check
    if (head.x < 0 or head.x >= GridSize or head.y < 0 or head.y >= GridSize) {
        game_over = true;
        return false;
    }

    // Self collision
    var i: usize = 0;
    while (i < snake_len) : (i += 1) {
        if (snake[i].x == head.x and snake[i].y == head.y) {
            game_over = true;
            return false;
        }
    }

    // Move body
    i = snake_len;
    while (i > 0) : (i -= 1) {
        snake[i] = snake[i - 1];
    }
    snake[0] = head;

    // Food check
    if (head.x == food.x and head.y == food.y) {
        snake_len += 1;
        score += 10;
        spawnFood();
    }

    render();
    return true;
}

fn drawRect(x: i32, y: i32, w: i32, h: i32, r: u8, g: u8, b: u8) void {
    var py = y;
    while (py < y + h) : (py += 1) {
        var px = x;
        while (px < x + w) : (px += 1) {
            if (px >= 0 and px < Width and py >= 0 and py < Height) {
                const idx = (@as(usize, @intCast(py)) * Width + @as(usize, @intCast(px))) * 4;
                pixel_buffer[idx] = r;
                pixel_buffer[idx + 1] = g;
                pixel_buffer[idx + 2] = b;
                pixel_buffer[idx + 3] = 255;
            }
        }
    }
}

fn render() void {
    // Clear screen to dark green
    var i: usize = 0;
    while (i < pixel_buffer.len) : (i += 4) {
        pixel_buffer[i] = 10;
        pixel_buffer[i + 1] = 20;
        pixel_buffer[i + 2] = 10;
        pixel_buffer[i + 3] = 255;
    }

    // Draw snake
    var j: usize = 0;
    while (j < snake_len) : (j += 1) {
        const r: u8 = if (j == 0) 100 else 50;
        const g: u8 = if (j == 0) 255 else 200;
        drawRect(snake[j].x * CellSize, snake[j].y * CellSize, CellSize - 1, CellSize - 1, r, g, 50);
    }

    // Draw food
    drawRect(food.x * CellSize, food.y * CellSize, CellSize - 1, CellSize - 1, 255, 50, 50);
}

pub export fn getBufferPtr() [*]u8 {
    return pixel_buffer.ptr;
}

pub export fn getBufferSize() usize {
    return pixel_buffer.len;
}

pub export fn getScore() u32 {
    return score;
}

pub export fn isGameOver() bool {
    return game_over;
}
