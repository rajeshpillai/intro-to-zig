const path = require("path");
const ffi = require('ffi-napi');

const lib = ffi.Library(path.resolve(__dirname,'./output/greetings.dll'), {
  greet: ['void', []],
});

lib.greet(); // 👋 Calls Zig function
