const path = require('path');
const ffi = require('ffi-napi');
const ref = require('ref-napi')


// Define uint64 as a buffer (to preserve full 64-bit integer)
const uint64 = ref.types.uint64;

const lib = ffi.Library(path.resolve(__dirname, 'output/fib.dll'), {
  fibonacci: [uint64, [uint64]],
});

// JS version
function fibonacci(n) {
  if (n === 0n) return 0n;
  if (n === 1n) return 1n;

  let a = 0n;
  let b = 1n;

  for (let i = 2n; i <= n; i++) {
    const next = a + b;
    a = b;
    b = next;
  }

  return b;
}


// console.log('Fibonacci(0):', lib.fibonacci(0));  // 0
// console.log('Fibonacci(1):', lib.fibonacci(1));  // 1
// console.log('Fibonacci(5):', lib.fibonacci(5));  // 5
// console.log('Fibonacci(10):', lib.fibonacci(10)); // 55
// console.log('Fibonacci(20):', lib.fibonacci(20)); // 6765
// console.log('Fibonacci(50):', lib.fibonacci(50)); // 6765


const input = 93n;  // u64 can working up this number

// Test Zig
// console.time('Zig Fibonacci');
// const zigResult = lib.fibonacci(Number(input)); // input must be JS Number
// console.timeEnd('Zig Fibonacci');
// console.log('Zig Result:', zigResult.toString());



// Test Node
// console.time('JS Fibonacci');
// const jsResult = fibonacci(input);
// console.timeEnd('JS Fibonacci');
// console.log('JS Result:', jsResult.toString());

console.time('Zig total');
for (let i = 0; i < 10000; i++) {
  lib.fibonacci(Number(input));
}
console.timeEnd('Zig total');

console.time('JS total');
for (let i = 0; i < 10000; i++) {
  fibonacci(input);
}
console.timeEnd('JS total');