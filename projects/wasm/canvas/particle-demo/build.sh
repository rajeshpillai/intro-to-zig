#!/bin/bash

# Simple build script for Wasm Canvas demo
# Note: Using build-exe for better control over exports in freestanding wasm

zig build-exe src/main.zig \
  -target wasm32-freestanding \
  --import-memory \
  -fno-entry \
  --export=init \
  --export=update \
  --export=getBufferPtr \
  --export=getBufferSize \
  -O ReleaseSmall \
  -femit-bin=public/canvas.wasm

echo "✅ WASM built successfully: public/canvas.wasm"
