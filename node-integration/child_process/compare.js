const { execSync } = require('child_process');
const path = require('path');

function jsFibonacci(n) {
  if (n === 0n) return 0n;
  if (n === 1n) return 1n;

  let a = 0n, b = 1n;
  for (let i = 2n; i <= n; i++) {
    const next = a + b;
    a = b;
    b = next;
  }
  return b;
}

function zigFibonacci(n) {
  const exePath = path.resolve(__dirname, 'output/fib.exe');
  const output = execSync(`"${exePath}" ${n}`).toString().trim();
  return BigInt(output);
}

const input = 93n;

// ➤ JS Benchmark
console.time("JS Fibonacci");
const jsResult = jsFibonacci(input);
console.timeEnd("JS Fibonacci");

// ➤ Zig Benchmark
console.time("Zig Fibonacci (CLI)");
const zigResult = zigFibonacci(Number(input));
console.timeEnd("Zig Fibonacci (CLI)");

console.log("JS Result:  ", jsResult);
console.log("Zig Result: ", zigResult);
console.log("✅ Match:   ", jsResult === zigResult);
