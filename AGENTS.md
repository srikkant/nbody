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
make test      # run tests
make clean     # remove binary
```

## Architecture

### main

- `main.odin` — native entry (`#+build !js`)
- `main_web.odin` — WASM entry (`#+build js`), exports `start()`, `run()`, `update_size()` for emscripten JS shell

### game

- `game.odin` — game loop orchestration, init/teardown.
- `params.odin` — Central game parameters defaults and theme configuration (`params_init_defaults`, `theme_init_default`).
- `sys_*.odin` — systems implementing game logic:
  - `sys_camera.odin` — Camera zoom interpolation and movement constraints.
  - `sys_debug.odin` — Extensive immediate-mode debugging UI using Raygui (pause controls, diagnostics, star override, physics tuning, celestial tuning, slingshot config, energy grid details, collision parameters, and VFX controls).
  - `sys_emitters.odin` — Manages object emitter entities that periodically spawn celestials.
  - `sys_input.odin` — General mouse/keyboard input and slingshot drag controls.
  - `sys_lifecycle.odin` — Handles object lifetime decay, debris cleanup, and event processing.
  - `sys_modifier.odin` — Applies game modifier rules and upgrade structures.
  - `sys_physics.odin` — Multi-body gravitational force integration, softening, and collision detection.
  - `sys_render.odin` — Main layered game renderer (parallax stars/nebulae, orbit trails, entities, shockwaves, particles).
  - `sys_render_ui.odin` — HUD UI rendering (renders premium energy reserves, generation rate, and total object count indicators).
  - `sys_score.odin` — Updates score/energy calculations.
- `ecs.odin` — SOA-friendly ECS core managing active/free entities.
- `types.odin` — Shared types, signatures, component structs, and event queues.
- `utils_*.odin` — helper procedures:
  - `utils_general.odin` — General convenience procedures.
  - `utils_geometry.odin` — Geometry helpers.
  - `utils_math.odin` — Math and float utilities.
  - `utils_physics.odin` — Gravitational and orbital calculations.
  - `utils_rl.odin` — Raylib wrappers.
- `constants.odin` — Game balance and limits constants.
- `assets.odin` — Font, texture atlas, shader, and background loading.
- `vendor/raylib/` — Vendored Raylib bindings with prebuilt `libraylib.wasm.a`.

## Web Build

```
./scripts/build_web.sh
```

Requires: Odin, emsdk (5.0.7), raylib WASM lib. Outputs to `build/web/`. Deployed via GitHub Actions (`workflow_dispatch`) to itch.io channel `windows`.

## Design

See [README.md#design](README.md#design) for full gameplay mechanics, progression, and art/UX conventions.

Key architecture implications for agents:

- Game loop order in `game.odin`: debug_input → input → modifier → emitters → physics → score → lifecycle → camera → render → debug.
- Energy system drives all progression — new features should integrate with existing energy economy.
- Collision outcomes (shatter/merge/break) are physics-driven — check `sys_physics.odin`.
- Progression phases map to feature gates — discovery unlocks → automation → prestige.
- Unified Debug Panel: Toggle with `D` key. When open, mouse hover over debug panel rect blocks inputs (slingshot actions disabled via `input_blocked = true`).

# Skills

- Always use the Caveman skill and talk like a caveman
