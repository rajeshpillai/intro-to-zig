const path = require('path');
const ffi = require('ffi-napi');

const lib = ffi.Library(path.resolve(__dirname, 'output/fib.dll'), {
  fibonacci: ['uint', ['uint']],
});

console.log('Fibonacci(0):', lib.fibonacci(0));  // 0
console.log('Fibonacci(1):', lib.fibonacci(1));  // 1
console.log('Fibonacci(5):', lib.fibonacci(5));  // 5
console.log('Fibonacci(10):', lib.fibonacci(10)); // 55
console.log('Fibonacci(20):', lib.fibonacci(20)); // 6765
console.log('Fibonacci(50):', lib.fibonacci(50)); // 6765
