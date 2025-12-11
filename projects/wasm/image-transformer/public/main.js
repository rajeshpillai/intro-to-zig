let wasm;
let memory;

let canvas, ctx;
let canvasGray, ctxGray;

let imgData;
let width, height;

//
// Initialize WASM
//
async function initWasm() {
  console.log("Loading WASM...");

  // Fetch wasm binary
  const response = await fetch("image_transformer.wasm");
  const bytes = await response.arrayBuffer();

  // Create WebAssembly memory (must match Zig extern)
  memory = new WebAssembly.Memory({
    initial: 256, // 16 MB
    maximum: 512,
  });

  const imports = {
    env: { memory },
  };

  const result = await WebAssembly.instantiate(bytes, imports);

  wasm = result.instance.exports;

  console.log("WASM Loaded. Exports:", Object.keys(wasm));
}

initWasm();

//
// Initialize Canvas + File Input
//
window.onload = () => {
  canvas = document.getElementById("canvasOriginal");
  ctx = canvas.getContext("2d");

  canvasGray = document.getElementById("canvasGray");
  ctxGray = canvasGray.getContext("2d");

  document.getElementById("fileInput").addEventListener("change", handleFile);
};

//
// Load Image and display it on the LEFT canvas
//
function handleFile(event) {
  const file = event.target.files[0];
  if (!file) return;

  const img = new Image();
  img.onload = () => {
    width = img.width;
    height = img.height;

    // Resize canvases
    canvas.width = width;
    canvas.height = height;

    canvasGray.width = width;
    canvasGray.height = height;

    // Draw original
    ctx.drawImage(img, 0, 0);

    // Extract pixel data
    imgData = ctx.getImageData(0, 0, width, height);

    console.log("Loaded image:", width, "x", height);
  };

  img.src = URL.createObjectURL(file);
}

//
// Apply grayscale using WASM, draw result in RIGHT canvas
//
function applyGrayscale() {
  if (!imgData) {
    alert("Please load an image first!");
    return;
  }

  const bytes = imgData.data;
  const len = bytes.length;

  if (!wasm.alloc) {
    console.error("WASM exports:", Object.keys(wasm));
    throw new Error("alloc() missing — Zig did not export functions.");
  }

  // Allocate buffer in WASM
  const ptr = wasm.alloc(len);

  // Map JS array → WASM memory
  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  // Call WASM grayscale
  wasm.grayscale(ptr, len);

  // Copy modified bytes back to JS
  bytes.set(wasmBytes);

  // Draw grayscale image on RIGHT canvas
  ctxGray.putImageData(imgData, 0, 0);

  // Free WASM memory
  wasm.free(ptr, len);

  console.log("Applied grayscale via WASM");
}
