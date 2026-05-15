# N-Body Forge — Agent Guide

## Project
Odin + Raylib n-body gravity simulation game. 

## Targets
- Windows, MacOS, Linux as standard builds
- Deploys to itch.io as WASM.

## Commands
```
make run       # build + run native
make build     # build native only (outputs `nbody` binary)
make debug     # build with -debug flag
make test      # run tests (tests/ dir does not exist yet)
make clean     # remove binary
```

## Architecture
- `main.odin` — native entry (`#+build !js`)
- `main_web.odin` — WASM entry (`#+build js`), exports `start()`, `run()`, `update_size()` for emscripten JS shell
- `game.odin` — game loop, init/teardown, params. Calls systems in order: input → modifier → emitters → physics → score → lifecycle → render
- `sys_*.odin` — systems (camera, emitters, input, lifecycle, modifier, physics, render, score)
- `ecs.odin` — ECS core
- `types.odin` — shared types (Celestial, events, etc.)
- `utils_*.odin` — math, geometry, physics helpers
- `constants.odin` — game constants
- `assets.odin` — texture/shader/bg loading
- `vendor/raylib/` — vendored raylib with prebuilt `libraylib.wasm.a`. Just for WASM builds.

## Web Build
```
./scripts/build_web.sh
```
Requires: Odin, emsdk (5.0.7), raylib WASM lib. Outputs to `build/web/`. Deployed via GitHub Actions (`workflow_dispatch`) to itch.io channel `windows`.

## Design
See [README.md#design](README.md#design) for full gameplay mechanics, progression, and art/UX conventions.

Key architecture implications for agents:
- Game loop order in `game.odin`: input → modifier → emitters → physics → score → lifecycle → render
- Energy system drives all progression — new features should integrate with existing energy economy
- Collision outcomes (shatter/merge/break) are physics-driven — check `sys_physics.odin`
- Progression phases map to feature gates — discovery unlocks → automation → prestige
