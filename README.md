# N-Body Forge

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

### Deploy

Trigger the `itch.io deploy` GitHub Actions workflow (`workflow_dispatch`). Uploads `build/web/` to itch.io.

## Project Structure

```
main.odin           # Native entry point
main_web.odin       # WASM entry point
game.odin           # Game loop + system orchestration
ecs.odin            # ECS core
types.odin          # Shared types
constants.odin      # Game constants
assets.odin         # Asset loading
sys_*.odin          # Systems (input, physics, render, etc.)
utils_*.odin        # Helper utilities
vendor/raylib/      # Vendored Raylib
scripts/            # Build scripts
web/                # WASM shell HTML
assets/             # Game assets
```
