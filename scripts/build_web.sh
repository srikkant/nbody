#!/bin/bash -eu

OUT_DIR="build/web"

mkdir -p $OUT_DIR

odin build . -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -vet -strict-style -out:$OUT_DIR/game.wasm.o -debug

ODIN_PATH=$(odin root)
cp $ODIN_PATH/core/sys/wasm/js/odin.js $OUT_DIR

emcc -o $OUT_DIR/index.html \
    $OUT_DIR/game.wasm.o ./vendor/raylib/libraylib.wasm.a \
    -sEXPORTED_RUNTIME_METHODS=['HEAPF32'] \
    -sUSE_GLFW=3 \
    -sWASM_BIGINT \
    -sWARN_ON_UNDEFINED_SYMBOLS=0 \
    -sASSERTIONS \
    -sINITIAL_MEMORY=134217728 \
    -g \
    --shell-file web/index.html \
    --preload-file assets

rm $OUT_DIR/game.wasm.o

# echo "Web build created in ${OUT_DIR}"
