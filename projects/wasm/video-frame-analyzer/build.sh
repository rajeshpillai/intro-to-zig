#!/bin/bash

zig build-exe src/main.zig \
  -target wasm32-freestanding \
  --import-memory \
  -fno-entry \
  --export=alloc \
  --export=free \
  --export=analyzeBrightness \
  --export=detectBlur \
  --export=detectSkinTone \
  --export=detectFacePresence \
  --export=calculateMotion \
  --export=detectCheating \
  --export=countFaceRegions \
  -O ReleaseSmall \
  -femit-bin=public/video_frame_analyzer.wasm

echo "✅ WASM built successfully: public/video_frame_analyzer.wasm"
