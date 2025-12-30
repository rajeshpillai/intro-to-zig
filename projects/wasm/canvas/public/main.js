let wasm;
let canvas;
let ctx;
let memory;

const width = 1200;
const height = 675;

let particleCount = 20000;
let gravity = 0.5;

let lastTime = 0;
let frames = 0;
let fpsLastTime = 0;

async function init() {
    console.log("Initializing Wasm...");

    const response = await fetch('canvas.wasm');
    const bytes = await response.arrayBuffer();

    // We need enough memory for the pixel buffer
    // width * height * 4 bytes
    // For 1200x675, that's ~3.2MB. 
    // Wasm pages are 64KB. 3.2MB is ~50 pages.
    // Let's allocate 128 pages (8MB) to be safe for particles too.
    memory = new WebAssembly.Memory({ initial: 128 });

    const result = await WebAssembly.instantiate(bytes, {
        env: {
            memory: memory
        }
    });

    wasm = result.instance.exports;
    console.log("Wasm Loaded");

    canvas = document.getElementById('particleCanvas');
    canvas.width = width;
    canvas.height = height;
    ctx = canvas.getContext('2d');

    // Setup UI
    const countSlider = document.getElementById('particleCount');
    const countDisplay = document.getElementById('countDisplay');
    const gravitySlider = document.getElementById('gravity');
    const gravityDisplay = document.getElementById('gravityDisplay');
    const resetBtn = document.getElementById('resetBtn');

    countSlider.addEventListener('input', (e) => {
        particleCount = parseInt(e.target.value);
        countDisplay.textContent = particleCount;
    });

    gravitySlider.addEventListener('input', (e) => {
        gravity = parseFloat(e.target.value);
        gravityDisplay.textContent = gravity.toFixed(1);
    });

    resetBtn.addEventListener('click', () => {
        wasm.init(width, height, particleCount);
    });

    // Initial simulation setup
    wasm.init(width, height, particleCount);

    requestAnimationFrame(loop);
}

function loop(time) {
    const dt = (time - lastTime) / 16.666;
    lastTime = time;

    const start = performance.now();

    // 1. Update physics and draw to pixel buffer in Zig
    wasm.update(dt, gravity);

    const end = performance.now();
    const processTime = end - start;

    // 2. Get pointer to the pixel buffer
    const ptr = wasm.getBufferPtr();
    const size = wasm.getBufferSize();

    // 3. Create a view into Wasm memory
    const pixels = new Uint8ClampedArray(memory.buffer, ptr, size);

    // 4. Create ImageData and put it on canvas
    const imageData = new ImageData(pixels, width, height);
    ctx.putImageData(imageData, 0, 0);

    // Stats
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
