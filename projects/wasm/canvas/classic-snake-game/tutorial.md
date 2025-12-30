# Step-by-Step: Building a Classic Snake Game with Zig and WASM

This tutorial provides a complete, beginner-friendly guide to building a high-performance Snake game. You will learn how to handle game logic, state, and pixel-level rendering entirely in **Zig**, using **Shared Memory** to display the results in the browser.

---

## Step 1: Initialize the Project Folders
Set up the directory structure for your game:

```bash
mkdir -p classic-snake-game/src classic-snake-game/public
cd classic-snake-game
```

---

## Step 2: Create the Build Script
Create a file named `build.sh` in the `classic-snake-game/` folder:

```bash
#!/bin/bash

# Compile Zig to WebAssembly
zig build-exe src/main.zig \
  -target wasm32-freestanding \
  --import-memory \
  -fno-entry \
  --export=init \
  --export=update \
  --export=setDirection \
  --export=getBufferPtr \
  --export=getBufferSize \
  --export=getScore \
  --export=isGameOver \
  -O ReleaseSmall \
  -femit-bin=public/snake.wasm

echo "✅ Snake WASM built successfully: public/snake.wasm"
```

**Make it executable:**
```bash
chmod +x build.sh
```

---

## Step 3: Implement the Game Engine (Zig)
Create `src/main.zig`. This is where all the game logic and pixel rendering happens.

```zig
const std = @import("std");

var allocator = std.heap.wasm_allocator;

const GridSize = 20;
const CellSize = 20;
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

// Random Number Generator
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

    // Allocate pixel buffer if not already done
    if (pixel_buffer.len == 0) {
        pixel_buffer = allocator.alloc(u8, Width * Height * 4) catch unreachable;
    }
}

fn spawnFood() void {
    food.x = random_range(0, GridSize);
    food.y = random_range(0, GridSize);
}

pub export fn setDirection(dir: u8) void {
    const new_dir: Direction = @enumFromInt(dir);
    // Prevent 180-degree turns
    if ((direction == .up and new_dir != .down) or
        (direction == .down and new_dir != .up) or
        (direction == .left and new_dir != .right) or
        (direction == .right and new_dir != .left)) {
        direction = new_dir;
    }
}

pub export fn update() bool {
    if (game_over) return false;

    var head = snake[0];
    switch (direction) {
        .up => head.y -= 1,
        .right => head.x += 1,
        .down => head.y += 1,
        .left => head.x -= 1,
    }

    // Collision Detection
    if (head.x < 0 or head.x >= GridSize or head.y < 0 or head.y >= GridSize) {
        game_over = true;
        return false;
    }

    var i: usize = 0;
    while (i < snake_len) : (i += 1) {
        if (snake[i].x == head.x and snake[i].y == head.y) {
            game_over = true;
            return false;
        }
    }

    // Move Body
    i = snake_len;
    while (i > 0) : (i -= 1) {
        snake[i] = snake[i - 1];
    }
    snake[0] = head;

    // Eat Food
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
            const idx = (@as(usize, @intCast(py)) * Width + @as(usize, @intCast(px))) * 4;
            pixel_buffer[idx] = r;
            pixel_buffer[idx + 1] = g;
            pixel_buffer[idx + 2] = b;
            pixel_buffer[idx + 3] = 255;
        }
    }
}

fn render() void {
    // Clear to dark green
    @memset(pixel_buffer, 20); // Quick fill
    var j: usize = 0;
    while (j < snake_len) : (j += 1) {
        const color_g: u8 = if (j == 0) 255 else 200;
        drawRect(snake[j].x * CellSize, snake[j].y * CellSize, CellSize - 1, CellSize - 1, 50, color_g, 50);
    }
    drawRect(food.x * CellSize, food.y * CellSize, CellSize - 1, CellSize - 1, 255, 50, 50);
}

pub export fn getBufferPtr() [*]u8 { return pixel_buffer.ptr; }
pub export fn getBufferSize() usize { return pixel_buffer.len; }
pub export fn getScore() u32 { return score; }
pub export fn isGameOver() bool { return game_over; }
```

---

## Step 4: Create the User Interface
Create `public/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Wasm Snake</title>
    <link rel="stylesheet" href="index.css">
</head>
<body>
    <div class="container">
        <h1>🐍 Wasm Snake</h1>
        <div class="game-area">
            <div class="canvas-wrapper">
                <canvas id="gameCanvas"></canvas>
                <div id="overlay" class="hidden">
                    <h2>GAME OVER</h2>
                    <button onclick="resetGame()">Try Again</button>
                </div>
            </div>
            <div class="score-card">
                <span class="label">Score</span>
                <span id="scoreValue" class="value">0</span>
            </div>
        </div>
    </div>
    <script src="main.js"></script>
</body>
</html>
```

---

## Step 5: Add the Styles
Create `public/index.css`:

```css
body { background: #0a0e14; color: #fff; font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
.container { text-align: center; }
.game-area { display: flex; gap: 20px; align-items: flex-start; }
.canvas-wrapper { position: relative; border: 4px solid #30363d; border-radius: 8px; }
canvas { width: 400px; height: 400px; image-rendering: pixelated; }
#overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.8); display: flex; flex-direction: column; justify-content: center; align-items: center; }
#overlay.hidden { display: none; }
.score-card { background: #151b23; padding: 20px; border-radius: 12px; border: 1px solid #30363d; min-width: 100px; }
.value { display: block; font-size: 3rem; color: #4ade80; }
button { background: #4ade80; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; font-weight: bold; }
```

---

## Step 6: Create the JavaScript Glue
Create `public/main.js`:

```javascript
let wasm, memory, ctx;
const tickInterval = 150;
let lastTick = 0;

async function init() {
    const response = await fetch('snake.wasm');
    const bytes = await response.arrayBuffer();
    memory = new WebAssembly.Memory({ initial: 32 });
    const result = await WebAssembly.instantiate(bytes, { env: { memory: memory } });
    wasm = result.instance.exports;

    const canvas = document.getElementById('gameCanvas');
    canvas.width = 400;
    canvas.height = 400;
    ctx = canvas.getContext('2d');

    window.addEventListener('keydown', (e) => {
        const key = e.key.toLowerCase();
        if (key === 'arrowup' || key === 'w') wasm.setDirection(0);
        if (key === 'arrowright' || key === 'd') wasm.setDirection(1);
        if (key === 'arrowdown' || key === 's') wasm.setDirection(2);
        if (key === 'arrowleft' || key === 'a') wasm.setDirection(3);
    });

    wasm.init();
    requestAnimationFrame(gameLoop);
}

function gameLoop(time) {
    if (time - lastTick > tickInterval) {
        lastTick = time;
        const running = wasm.update();
        if (!running && wasm.isGameOver()) {
            document.getElementById('overlay').classList.remove('hidden');
        }
        document.getElementById('scoreValue').textContent = wasm.getScore();
        
        // Render from Wasm Memory
        const ptr = wasm.getBufferPtr();
        const size = wasm.getBufferSize();
        const pixels = new Uint8ClampedArray(memory.buffer, ptr, size);
        ctx.putImageData(new ImageData(pixels, 400, 400), 0, 0);
    }
    requestAnimationFrame(gameLoop);
}

function resetGame() {
    document.getElementById('overlay').classList.add('hidden');
    wasm.init();
}

init().catch(console.error);
```

---

## Step 7: Build and Play
1. **Compile**: `./build.sh`
2. **Serve**: Use `npx serve public` or `python3 -m http.server 8000`.
3. **Open**: Navigate to `http://localhost:8000`.

---

## Technical Summary
By using Zig to write raw pixel data to a shared WASM memory buffer, we eliminate the need for thousands of JavaScript calls per frame. This makes the game incredibly efficient, even if you were to scale the grid to thousands of cells.
