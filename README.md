# Gigawatt Galaxy

An incremental n-body gravity simulation game built with Odin and Raylib. 

## Quick Start

### Native (Windows, macOS, Linux)

```bash
make run       # build and run
make build     # build only (outputs `nbody` binary)
make debug     # build with debug flags
make clean     # remove binary
```

Requires [Odin](https://odin-lang.org/).

### Web (WASM)

```bash
./scripts/build_web.sh
```

Requires Odin, emsdk (v5.0.7), and the Raylib WASM library (`vendor/raylib/libraylib.wasm.a`). Outputs to `build/web/`.

