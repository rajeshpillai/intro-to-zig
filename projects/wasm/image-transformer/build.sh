# zig build-exe src/main.zig -target wasm32-freestanding \
#     -fno-entry \
#     --import-memory \
#     --export=grayscale \
#     --export=alloc \
#     --export=free \
#     -O ReleaseFast \
#     -femit-bin=public/image_transformer.wasm

zig build-exe src/main.zig \
  -target wasm32-freestanding \
  --import-memory \
  -fno-entry \
  --export=alloc \
  --export=free \
  --export=grayscale \
  -O ReleaseFast \
  -femit-bin=public/image_transformer.wasm
