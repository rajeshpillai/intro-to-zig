let wasm;
let memory;

let canvas, ctx;
let canvasGray, ctxGray;
let originalData;
let width, height;

async function initWasm() {
  const response = await fetch("image_transformer.wasm");
  const bytes = await response.arrayBuffer();

  // Create memory
  memory = new WebAssembly.Memory({
    initial: 256,
    maximum: 512,
  });

  // Instantiate WASM with memory buffer
  const result = await WebAssembly.instantiate(bytes, {
    env: {
      memory: memory, // correct
      memory_base: 0, // optional (ignored)
    },
  });

  wasm = result.instance.exports;
  console.log("WASM Loaded:", Object.keys(wasm));
}

initWasm();

window.onload = () => {
  canvas = document.getElementById("canvasOriginal");
  ctx = canvas.getContext("2d");

  canvasGray = document.getElementById("canvasGray");
  ctxGray = canvasGray.getContext("2d");

  document.getElementById("fileInput").addEventListener("change", handleFile);
};

function handleFile(event) {
  const file = event.target.files[0];
  if (!file) return;

  const img = new Image();
  img.onload = () => {
    width = img.width;
    height = img.height;

    canvas.width = width;
    canvas.height = height;

    canvasGray.width = width;
    canvasGray.height = height;

    ctx.drawImage(img, 0, 0);

    originalData = ctx.getImageData(0, 0, width, height);

    console.log("Loaded image:", width, height);
  };

  img.src = URL.createObjectURL(file);
}

function applyGrayscale() {
  if (!originalData) return alert("Load an image first!");

  const grayData = new ImageData(
    new Uint8ClampedArray(originalData.data),
    width,
    height,
  );

  const bytes = grayData.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.grayscale(ptr, len);

  bytes.set(wasmBytes);

  ctxGray.putImageData(grayData, 0, 0);

  wasm.free(ptr, len);

  console.log("Grayscale applied.");
}
