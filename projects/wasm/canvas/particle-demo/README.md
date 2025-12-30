# Zig Wasm Canvas Demo

This demo showcases the power of **Zig + WebAssembly** in enhancing HTML5 Canvas performance through **Shared Memory**. 

By performing physics calculations and direct pixel manipulation in Zig, we bypass the overhead of calling individual JavaScript Canvas API methods for every single particle.

## Features
- **Massive Particle Count**: Smoothly renders 20,000+ particles at 60 FPS.
- **Shared Memory Rendering**: Maps WASM memory directly to a JavaScript `ImageData` object.
- **Interactive Simulation**: Adjust particle count and gravity in real-time.

## Prerequisites
- [Zig](https://ziglang.org/download/) (tested with 0.13.0)
- A local web server (to avoid CORS issues when loading the WASM file)

## Getting Started

### 1. Build the WASM Binary
Navigate to the `particle-demo` directory and run the build script:
```bash
./build.sh
```
This will generate `public/canvas.wasm`.

### 2. Run a Local Server
You can use any local web server to serve the `public` directory. Here are a few common ways:

**Using Python:**
```bash
cd public
python3 -m http.server 8000
```

**Using Node.js (serve):**
```bash
npx serve public
```

**Using PHP:**
```bash
cd public
php -S localhost:8000
```

### 3. View the Demo
Open your browser and navigate to:
[http://localhost:8000](http://localhost:8000)

## How it Works
1. **Memory Allocation**: A large byte array is allocated in WASM memory to act as a raw pixel buffer (RGBA).
2. **Zig Processing**: On every frame, Zig updates the physics of all particles and writes their colors directly into the pixel buffer.
3. **JS Synchronizaton**: JavaScript gets a pointer to this buffer and wraps it in a `Uint8ClampedArray`, which is then passed to `putImageData`.
4. **Performance**: This approach reduces the JS-to-Native bridge calls from $O(N)$ (where $N$ is the number of particles) to $O(1)$ per frame.
