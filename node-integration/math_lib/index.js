const path = require("path");
const ffi = require('ffi-napi');


const lib = ffi.Library(path.resolve(__dirname,'./output/math.dll'), {
  add: ['int', ['int', 'int']],
  multiply: ['int', ['int', 'int']],
});

console.log('Add: ', lib.add(5, 7)); // prints 12
console.log('Multiply: ', lib.multiply(5, 3)); // Output: 15
