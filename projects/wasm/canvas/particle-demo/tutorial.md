# Step-by-Step: Building a High-Performance Wasm Canvas Demo

This guide provides a comprehensive, beginner-friendly path to creating a high-performance particle simulation using Zig and WebAssembly. You will learn how to bypass common JavaScript bottlenecks by using **Shared Memory**.

---

## Step 1: Initialize the Project Folders
Open your terminal and create the following directory structure:

```bash
mkdir -p particle-demo/src particle-demo/public
cd particle-demo
```

Your folder structure should now look like this:
- `particle-demo/`
  - `src/` (Where our Zig code lives)
  - `public/` (Where our web assets and compiled WASM live)

---

## Step 2: Create the Build Script
WASM targets in Zig require specific flags. We'll create a shell script to simplify the compilation.

Create a file named `build.sh` in the `particle-demo/` folder:

```bash
#!/bin/bash

# Compile Zig to WebAssembly
zig build-exe src/main.zig \
  -target wasm32-freestanding \
  --import-memory \
  -fno-entry \
  --export=init \
  --export=update \
  --export=getBufferPtr \
  --export=getBufferSize \
  -O ReleaseSmall \
  -femit-bin=public/canvas.wasm

echo "✅ WASM built successfully: public/canvas.wasm"
```

**What do these flags mean?**
- `-target wasm32-freestanding`: Targets a generic WASM environment (Web browser).
- `--import-memory`: Tells Zig that JavaScript will provide the memory slab.
- `-fno-entry`: Disables the need for a `main()` function.
- `--export=...`: Explicitly tells the compiler to make these functions visible to JavaScript.
- `-O ReleaseSmall`: Optimizes the final WASM file for small size.

**Important**: Make the script executable:
```bash
chmod +x build.sh
```

---

## Step 3: Write the Zig Logic
Create `src/main.zig`. This file contains the physics engine and the pixel-sharing logic.

```zig
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

// Simple Random Number Generator
var prng_state: u64 = 12345;
fn random_f32() f32 {
    prng_state = prng_state *% 6364136223846793005 +% 1442695040888963407;
    const val: u32 = @intCast(prng_state >> 32);
    return @as(f32, @floatFromInt(val)) / @as(f32, @floatFromInt(std.math.maxInt(u32)));
}

pub export fn init(w: u32, h: u32, count: u32) void {
    width = w;
    height = h;

    // Free existing memory if resetting
    if (particles.len > 0) allocator.free(particles);
    if (pixel_buffer.len > 0) allocator.free(pixel_buffer);

    // Allocate memory for data
    particles = allocator.alloc(Particle, count) catch unreachable;
    pixel_buffer = allocator.alloc(u8, w * h * 4) catch unreachable;

    // Initialize particles with random positions and velocities
    for (particles) |*p| {
        p.x = random_f32() * @as(f32, @floatFromInt(w));
        p.y = random_f32() * @as(f32, @floatFromInt(h));
        p.vx = (random_f32() - 0.5) * 4.0;
        p.vy = (random_f32() - 0.5) * 4.0;
        
        // Random bright color (0xAABBGGRR format for Canvas)
        const r: u32 = @intFromFloat(150.0 + random_f32() * 105.0);
        const g: u32 = @intFromFloat(150.0 + random_f32() * 105.0);
        const b: u32 = @intFromFloat(150.0 + random_f32() * 105.0);
        p.color = (0xFF << 24) | (b << 16) | (g << 8) | r;
    }
}

pub export fn update(dt: f32, gravity: f32) void {
    const fw = @as(f32, @floatFromInt(width));
    const fh = @as(f32, @floatFromInt(height));

    // Clear the pixel buffer to black
    @memset(pixel_buffer, 0);

    for (particles) |*p| {
        // Physics update
        p.vy += gravity * dt;
        p.x += p.vx;
        p.y += p.vy;

        // Bounce off walls
        if (p.x < 0) { p.x = 0; p.vx *= -0.8; }
        else if (p.x >= fw) { p.x = fw - 1; p.vx *= -0.8; }
        if (p.y < 0) { p.y = 0; p.vy *= -0.8; }
        else if (p.y >= fh) { p.y = fh - 1; p.vy *= -0.8; }

        // Render particle into pixel buffer
        const ix: i32 = @intFromFloat(p.x);
        const iy: i32 = @intFromFloat(p.y);
        
        if (ix >= 0 and ix < @as(i32, @intCast(width)) and iy >= 0 and iy < @as(i32, @intCast(height))) {
            const base_idx = (@as(usize, @intCast(iy)) * width + @as(usize, @intCast(ix))) * 4;
            
            // Write RGBA bytes directly
            pixel_buffer[base_idx] = @intCast(p.color & 0xFF);
            pixel_buffer[base_idx + 1] = @intCast((p.color >> 8) & 0xFF);
            pixel_buffer[base_idx + 2] = @intCast((p.color >> 16) & 0xFF);
            pixel_buffer[base_idx + 3] = @intCast((p.color >> 24) & 0xFF);
        }
    }
}

// These allow JavaScript to find exactly where the results are located in memory
pub export fn getBufferPtr() [*]u8 { return pixel_buffer.ptr; }
pub export fn getBufferSize() usize { return pixel_buffer.len; }
```

---

## Step 4: Create the Frontend Structure
Create `public/index.html`. This is the user interface.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Zig Wasm Canvas</title>
    <link rel="stylesheet" href="index.css">
</head>
<body>
    <div class="container">
        <h1>⚡ Zig Wasm Canvas</h1>
        <div class="main-layout">
            <div class="canvas-container">
                <canvas id="particleCanvas"></canvas>
                <div id="stats">FPS: <span id="fpsValue">0</span> | MS: <span id="msValue">0</span></div>
            </div>
            <div class="sidebar">
                <label>Particles: <span id="countDisplay">20000</span></label>
                <input type="range" id="particleCount" min="1000" max="100000" value="20000">
                <label>Gravity: <span id="gravityDisplay">0.5</span></label>
                <input type="range" id="gravity" min="0" max="2" step="0.1" value="0.5">
                <button id="resetBtn">Reset</button>
            </div>
        </div>
    </div>
    <script src="main.js"></script>
</body>
</html>
```

---

## Step 5: Add the Styles
Create `public/index.css`.

```css
body { background: #0d1117; color: #c9d1d9; font-family: sans-serif; display: flex; justify-content: center; height: 100vh; margin: 0; }
.container { width: 1000px; padding: 20px; }
.main-layout { display: flex; gap: 20px; }
.canvas-container { position: relative; background: #000; border: 1px solid #30363d; border-radius: 8px; }
canvas { width: 800px; height: 450px; image-rendering: pixelated; }
#stats { position: absolute; top: 10px; left: 10px; background: rgba(0,0,0,0.5); padding: 5px; font-family: monospace; }
.sidebar { flex: 1; display: flex; flex-direction: column; gap: 10px; background: #161b22; padding: 20px; border-radius: 8px; }
input { width: 100%; }
button { padding: 10px; background: #58a6ff; border: none; color: white; border-radius: 4px; cursor: pointer; }
```

---

## Step 6: Connect JS to Wasm
Create `public/main.js`. This is the glue between Zig's memory and the Canvas API.

```javascript
let wasm, canvas, ctx, memory;
const width = 1200;
const height = 675;
let particleCount = 20000;
let gravity = 0.5;
let lastTime = 0, frames = 0, fpsLastTime = 0;

async function init() {
    // 1. Load the WASM binary
    const response = await fetch('canvas.wasm');
    const bytes = await response.arrayBuffer();
    
    // 2. Setup shared memory (8MB initial)
    memory = new WebAssembly.Memory({ initial: 128 });
    
    // 3. Instantiate the module
    const result = await WebAssembly.instantiate(bytes, { env: { memory: memory } });
    wasm = result.instance.exports;

    // 4. Setup Canvas
    canvas = document.getElementById('particleCanvas');
    canvas.width = width;
    canvas.height = height;
    ctx = canvas.getContext('2d');

    // 5. Setup UI Event Listeners
    document.getElementById('particleCount').addEventListener('input', (e) => {
        particleCount = parseInt(e.target.value);
        document.getElementById('countDisplay').textContent = particleCount;
    });
    document.getElementById('gravity').addEventListener('input', (e) => {
        gravity = parseFloat(e.target.value);
        document.getElementById('gravityDisplay').textContent = gravity.toFixed(1);
    });
    document.getElementById('resetBtn').addEventListener('click', () => wasm.init(width, height, particleCount));

    // 6. Start the Simulation
    wasm.init(width, height, particleCount);
    requestAnimationFrame(loop);
}

function loop(time) {
    const dt = (time - lastTime) / 16.66;
    lastTime = time;

    const start = performance.now();
    
    // Step A: Let Zig update physics and pixels
    wasm.update(dt, gravity);
    
    // Step B: View the resulting pixels in Zig's memory
    const ptr = wasm.getBufferPtr();
    const size = wasm.getBufferSize();
    const pixels = new Uint8ClampedArray(memory.buffer, ptr, size);
    
    // Step C: Display those pixels on the canvas
    const imageData = new ImageData(pixels, width, height);
    ctx.putImageData(imageData, 0, 0);

    const processTime = performance.now() - start;

    // Optional: Stats tracking
    frames++;
    if (time > fpsLastTime + 1000) {
        document.getElementById('fpsValue').textContent = frames;
        frames = 0;
        fpsLastTime = time;
    }
    document.getElementById('msValue').textContent = processTime.toFixed(2);

    requestAnimationFrame(loop);
}

init().catch(console.error);
```

---

## Step 7: Build and Run
1. Run the build script:
   ```bash
   ./build.sh
   ```
2. Start a local server in the `public` directory:
   ```bash
   cd public
   python3 -m http.server 8000
   ```
3. Open `http://localhost:8000` in your browser.

---

## Why is this so fast?
In standard Canvas code, you would use `ctx.fillRect()` 20,000 times. Each of those calls has a heavy overhead. In this demo, Zig writes to a raw array (extremely fast) and JS draws the entire array at once using `putImageData` (extremely fast). You are effectively talking to the GPU in a single "sentence" rather than 20,000 "words".
