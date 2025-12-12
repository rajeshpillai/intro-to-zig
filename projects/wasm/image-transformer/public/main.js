let wasm;
let memory;

let canvasOriginal, ctxOriginal;
let canvasOutput, ctxOutput;

let originalData;
let width, height;

// -------------------------------
// Init WASM
// -------------------------------
async function initWasm() {
  console.log("Loading WASM...");

  const response = await fetch("image_transformer.wasm");
  const bytes = await response.arrayBuffer();

  memory = new WebAssembly.Memory({
    initial: 256,
    maximum: 512
  });

  const result = await WebAssembly.instantiate(bytes, {
    env: { memory },
  });

  wasm = result.instance.exports;

  console.log("WASM Loaded. Exports:", Object.keys(wasm));
}

initWasm();


// -------------------------------
// Setup UI + Canvas
// -------------------------------
window.onload = () => {
  canvasOriginal = document.getElementById("canvasOriginal");
  ctxOriginal = canvasOriginal.getContext("2d");

  canvasOutput = document.getElementById("canvasOutput");
  ctxOutput = canvasOutput.getContext("2d");

  document.getElementById("fileInput").addEventListener("change", handleFile);
};


// -------------------------------
// Load Image (save ORIGINAL ONLY)
// -------------------------------
function handleFile(event) {
  const file = event.target.files[0];
  if (!file) return;

  const img = new Image();
  img.onload = () => {
    width = img.width;
    height = img.height;

    canvasOriginal.width = width;
    canvasOriginal.height = height;

    canvasOutput.width = width;
    canvasOutput.height = height;

    ctxOriginal.drawImage(img, 0, 0);

    originalData = ctxOriginal.getImageData(0, 0, width, height);

    console.log("Loaded image:", width, "x", height);
  };

  img.src = URL.createObjectURL(file);
}


// -------------------------------
// Helper: copy original → working buffer
// -------------------------------
function makeWorkingCopy() {
  return new ImageData(
    new Uint8ClampedArray(originalData.data),
    width,
    height
  );
}


// -------------------------------
// Helper: Run ANY wasm filter
// -------------------------------
function runWasmFilter(ptr, len, fn) {
  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(new Uint8Array(originalData.data));

  fn(ptr, len);

  return wasmBytes;
}


// =============================================================
// FILTER DISPATCHER — ALL BUTTONS CALL applyFilter("filterName")
// =============================================================
function applyFilter(name, param) {
  switch (name) {
    case "grayscale": return applyGrayscale();
    case "invert": return applyInvert();
    case "brightness": return applyBrightness(param || 0);
    case "threshold": return applyThreshold(param || 128);
    case "sepia": return applySepia();
    case "sobel": return applySobel();
    case "gaussian": return applyGaussian();
    case "vintage": return applyVintage();
    case "clarendon": return applyClarendon();
    case "cool": return applyCoolTone();
    case "contrast": return applyContrast(param || 0);
    case "saturation": return applySaturation(param || 0);
    case "nashville": return applyNashville();
    case "valencia": return applyValencia();
    case "inkwell": return applyInkwell();
    case "lomo": return applyLomo();
    case "vignette": return applyVignette();
    default: alert("Unknown filter: " + name);
  }
}


// =============================================================
// INDIVIDUAL FILTER FUNCTIONS (CALL WASM)
// =============================================================

// ---- GRAYSCALE ----
function applyGrayscale() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.grayscale(ptr, len);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Grayscale applied");
}


// ---- INVERT ----
function applyInvert() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.invert(ptr, len);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Invert applied");
}


// ---- BRIGHTNESS ----
function applyBrightness(adjustment) {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.brightness(ptr, len, adjustment);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Brightness applied:", adjustment);
}


// ---- THRESHOLD ----
function applyThreshold(value) {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.threshold(ptr, len, value);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Threshold applied:", value);
}


// ---- SEPIA ----
function applySepia() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.sepia(ptr, len);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Sepia applied");
}


// ---- SOBEL EDGE DETECTION ----
function applySobel() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const len = copy.data.length;

  const ptr = wasm.alloc(len);

  let wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(copy.data);

  wasm.sobel(ptr, len, width, height);

  // Re-get buffer reference in case memory grew
  wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  copy.data.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Sobel applied");
}


// ---- GAUSSIAN BLUR ----
function applyGaussian() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const len = copy.data.length;

  const ptr = wasm.alloc(len);

  let wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(copy.data);

  wasm.gaussian(ptr, len, width, height);

  // Re-get buffer reference in case memory grew
  wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  copy.data.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Gaussian blur applied");
}


// ---- COLOR MATRIX: VINTAGE ----
function applyVintage() {
  applyColorMatrix([
    0.9, 0.5, 0.1,
    0.3, 0.9, 0.2,
    0.2, 0.3, 0.8
  ]);
}

// ---- COLOR MATRIX: CLARENDON ----
function applyClarendon() {
  applyColorMatrix([
    1.2, 0.1, 0.1,
    0.1, 1.1, 0.1,
    0.1, 0.1, 1.2
  ]);
}

// ---- COLOR MATRIX: COOL BLUE ----
function applyCoolTone() {
  applyColorMatrix([
    0.9, 0.1, 0.1,
    0.2, 0.9, 0.2,
    0.3, 0.3, 1.3
  ]);
}


// -------------------------------
// COLOR MATRIX DRIVER
// -------------------------------
function applyColorMatrix(matrix) {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const mPtr = wasm.alloc(9); // 3×3 matrix
  const matrixArr = new Uint8Array(memory.buffer, mPtr, 9);

  for (let i = 0; i < 9; i++) {
    matrixArr[i] = matrix[i] * 255 / 1.3;
  }

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.color_matrix(ptr, len, mPtr);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  wasm.free(mPtr, 9);

  console.log("Color matrix filter applied");
}


// ---- CONTRAST ----
function applyContrast(factor) {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.contrast(ptr, len, factor);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Contrast applied:", factor);
}


// ---- SATURATION ----
function applySaturation(factor) {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.saturation(ptr, len, factor);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Saturation applied:", factor);
}


// ---- NASHVILLE ----
function applyNashville() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.nashville(ptr, len);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Nashville filter applied");
}


// ---- VALENCIA ----
function applyValencia() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.valencia(ptr, len);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Valencia filter applied");
}


// ---- INKWELL ----
function applyInkwell() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const bytes = copy.data;
  const len = bytes.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(bytes);

  wasm.inkwell(ptr, len);

  bytes.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Inkwell filter applied");
}


// ---- LOMO ----
function applyLomo() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const len = copy.data.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(copy.data);

  wasm.lomo(ptr, len, width, height);

  copy.data.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Lomo filter applied");
}


// ---- VIGNETTE ----
function applyVignette() {
  if (!originalData) return alert("Load an image first!");

  const copy = makeWorkingCopy();
  const len = copy.data.length;

  const ptr = wasm.alloc(len);

  const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
  wasmBytes.set(copy.data);

  wasm.vignette(ptr, len, width, height);

  copy.data.set(wasmBytes);
  ctxOutput.putImageData(copy, 0, 0);

  wasm.free(ptr, len);
  console.log("Vignette applied");
}
