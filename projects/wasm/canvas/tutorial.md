# Tutorial: Building a High-Performance Wasm Canvas Demo

This tutorial guides you through creating a particle simulation using Zig and WebAssembly to enhance HTML5 Canvas performance.

## Prerequisites
- Basic knowledge of Zig and JavaScript.
- Zig installed on your machine.

---

## Step 1: Project Structure
First, set up a clean directory structure:

```bash
canvas/
├── src/
│   └── main.zig       # Zig logic (physics + rendering)
├── public/
│   ├── index.html     # UI structure
│   ├── index.css      # Styling
│   └── main.js        # JavaScript glue code
└── build.sh           # Build script
```

---

## Step 2: The Core Logic (Zig)
In `src/main.zig`, we define our particle system and the shared pixel buffer.

### 1. Memory Management
We use `std.heap.wasm_allocator` as it's perfectly suited for the Wasm memory model.

### 2. The Data Structure
Define a simple `Particle` struct to hold position, velocity, and color.

### 3. Shared Memory Strategy
This is the most critical part. Instead of JS calling Zig for every particle, Zig writes to a large byte array (`pixel_buffer`) that JS can read directly.

```zig
var pixel_buffer: []u8 = &[_]u8{};

pub export fn getBufferPtr() [*]u8 {
    return pixel_buffer.ptr;
}
```

### 4. Physics and Drawing
The `update` function handles moving particles and setting the correct bytes in `pixel_buffer` for each particle's position.

---

## Step 3: The HTML Dashboard
Create `public/index.html`. The most important element is the `<canvas>` where we will display the rendered pixels.

```html
<canvas id="particleCanvas"></canvas>
```

---

## Step 4: The JavaScript Bridge
In `public/main.js`, we bridge the gap between Zig and the browser.

### 1. Linking Memory
When instantiating the Wasm module, we share the same `WebAssembly.Memory` object.

### 2. The Rendering Loop
In the `requestAnimationFrame` loop, we:
1. Call `wasm.update()` to calculate the next frame in Zig.
2. Get the pointer to the Wasm pixel buffer.
3. Wrap that raw memory in a `Uint8ClampedArray`.
4. Create an `ImageData` object and call `ctx.putImageData()`.

**Why is this fast?** Because `putImageData` is a highly optimized native browser function that copies the entire buffer at once.

---

## Step 5: Building for Wasm
Create `build.sh` to compile your Zig code into WebAssembly.

```bash
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
```

- `--target wasm32-freestanding`: Targets generic browser Wasm.
- `--import-memory`: Allows JS to provide the memory object.
- `-fno-entry`: We don't need a `main` function as this is a library.

---

## Step 6: Running the Demo
Due to browser security (CORS), you cannot open the HTML file directly from your disk. You must use a local server:

```bash
cd public
python3 -m http.server 8000
```

Now open `http://localhost:8000` and watch 20,000 particles fly!

---

## Key Takeaways
- **Zero-Copy Intent**: JavaScript doesn't "copy" the data per se; it views the memory that Zig already filled.
- **Bridge Overhead**: Minimizing calls between JS and Wasm is the secret to performance. One call per frame (`update`) is better than 20,000 calls (`drawParticle`).
- **Zig's Strength**: Manual memory control and small binary sizes make it the ideal companion for web processing tasks.
