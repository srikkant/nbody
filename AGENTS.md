# Agent Guide

## Project Overview

This project is an incremental n-body gravity simulation game written in Odin using Raylib. It features physics-driven celestial mechanics, upgrade progression, automated emitters, and a slingshot mechanic to launch new objects.

## Build and Execution

### Commands

```bash
make run       # build + run native
make build     # build native only (outputs `nbody` binary)
make debug     # build with -debug flag
make test      # run tests
make clean     # remove build artifacts
```

### Targets

- **Native**: Windows, macOS, Linux.
- **Web (WASM)**: Outputs to `build/web/` using `./scripts/build_web.sh`. Requires emsdk (v5.0.7) and the Raylib WASM library (`vendor/raylib/libraylib.wasm.a`). Deployed to itch.io.

---

## Core Architecture

### Entry Points

- `main.odin` (`#+build !js`): Native entry. Sets up context with a tracking allocator for leak checking, initializes game state, and loops `game_run`.
- `main_web.odin` (`#+build js`): Web/WASM entry. Exports `start()`, `run()`, and `update_size()` for emscripten. Implements `emscripten_allocator` on top of libc allocator (`malloc`, `free`, `realloc`, `calloc`) to ensure proper alignment required by maps and SIMD features.

### ECS (Entity Component System)

The project implements a lightweight custom ECS in `game/ecs.odin` and `game/types.odin`.

- **Storage**: Entities are stored in a Struct of Arrays (SOA) structure: `entities: #soa[MAX_ENTITIES]Game_Entity` inside the `Game` struct.
- **Recycling**: Free entity indices are stored on a stack `free_entities` of size `MAX_ENTITIES`. When creating an entity, an index is popped from this stack if `free_entities_count > 0`, otherwise `entities_count` is incremented.
- **Component Bitsets**: Components are toggled and checked using `Signature :: bit_set[ComponentType]`. Systems filter entities by verifying signature inclusion (e.g. `PHYSICS_SIG <= e.sig`).

### Event Queue

- Standard fixed-size array `events: [MAX_ENTITIES]Game_Event` tracked by `events_count`.
- Events are pushed throughout the frame via `push_event`.
- Dispatched and cleared at the end of the game loop in `sys_lifecycle`.

### Game Loop Orchestration

Executed sequentially in `game_run` ([game/game.odin](file:///Users/srikkant/work/srikkant/nbody/game/game.odin)):

- **Frame Setup**: Update delta time (clamped to `max_delta_time_sec`), increment elapsed time, query screen size, and update game timers (`Score`, `Trail`).
- **Input Processing**: Map inputs to abstract actions; process mouse and keyboard interactions (menus, slingshot actions, camera vibration).
- **Loop Phase Execution** (based on `Game_Status`): Runs the main game loop and relevant systems depending on the status.

---

### Code structure

The `game` directory contains all the source code for the game.The code is primarily categorized into the following categories:

- game.odin: Orchestrates the game loop and calls the required systems
- sys_*.odin: Various systems of the ECS. Systems always run sequentially. Systems that are becoming too big can be divided into subsystems by using a prefix based naming convention. For example, sys*ui_menu can be a subsystem of sys_ui. All methods defined in sys* files should be prefixed with sys*{system_name}*
- utils_*.odin: Common utils. All of these methods should be prefixed with the logical namespace like `math_` or `rl_` etc. Before adding a new method, always check the files here. The sys\_\* files should only contain code that is particular to a system. Any calculations that are general purpose should be moved to a utils method.
- frame.odin: Responsible for set up and teardown of a frame. Capped delta time calculation and game-wide timer updates.
- input.odin: Input action matching and handling (slingshot activation, menu triggers, orbit toggle).
- ecs.odin: Contain general ECS specific code like entity management, component attaching etc.
- theme.odin: Theme for the game. The theme object is split into two categories, general design tokens and semantic tokens. Never use general design tokens directly. Always rely on semantic tokens.
- types.odin: Types used across the game. No other file other than this should contain types. Any new structs all get defined here.
- assets.odin: Assets management like textures, shaders, fonts etc.
- params.odin: Game parameters, these are what drive the balance of the game.
- ui.odin: Responsible for rendering the UI menus and overlays in the game.
- messages.odin: Messages for translation. The game should not contain any magic strings anywhere. Every single user facing string should go through this.
- background.odin: The fixed background layer of the game. This is a dynamic starfield and some breathing nebulae.
- constants.odin: Compile time constants for use in the game. No other file should contain magic numbers unless trivial.

---

## General guidelines

- No dynamic allocations on the heap allowed. All allocations are done at the beginning of the game with generous capacities. The game is small enough to handle this.
- No inline math formulae. Add a method in utils_math.odin.
- No magic numbers unless they are trivial to understand (like known formulae etc.). Add a new constant in constants.odin if we know the constant at compile time. Add it to the Parameters struct if these
  are coefficients that are used for balancing the game.
- No direct code changes without a plan first. If you support planning mode, switch to that or simulate it by printing a summary of your changes following the process listed below and get approval before touching the code.
- No version control operations. Those will be done by the user always.
- No utility methods in any of the `sys_` files.
- Always search for `utils_*` files to check if a method exists that solves your problem.
- Always talk in caveman mode. Activate the skill.
- Always run `make test` before you start any task to ensure tests are not failing because of your changes. If they are failing beforehand, get explicit approval before proceeding.

---
