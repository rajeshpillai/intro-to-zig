const fs = require("fs");
const path = require("path");

async function loadWasm() {
  const wasmPath = path.resolve(__dirname, "output/fib.wasm");
  const buffer = fs.readFileSync(wasmPath);

  const { instance } = await WebAssembly.instantiate(buffer, {
    env: { }
  });
  console.log("IE: ", instance.exports);
  return instance.exports;
}

(async () => {
  // const wasm = await loadWasm();

  // console.time("Zig WASM Fibonacci");
  // const result = wasm.fibonacci(93);
  // console.timeEnd("Zig WASM Fibonacci");

  // console.log("Fibonacci(93):", BigInt(result));

  const wasmPath = path.resolve(__dirname, "output/fib.wasm");
  const buffer = fs.readFileSync(wasmPath);
  WebAssembly.instantiate(buffer, {
    env: {}
  }).then(result => {
    // do wasm things here!
    var add_two = result.instance.exports.fibonacci;
    console.log(fibonacci(93));
  });
})();
