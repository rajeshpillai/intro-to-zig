const { execSync } = require('child_process');
const path = require('path');

function zigFib(n) {
  const exePath = path.resolve(__dirname, 'output/fib.exe');
  const output = execSync(`"${exePath}" ${n}`).toString().trim();
  return BigInt(output);
}

console.time("Zig CLI");
const result = zigFib(93);
console.timeEnd("Zig CLI");

console.log("Zig Fibonacci:", result);