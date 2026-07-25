# Agent Guide

## Project Overview

This project is an incremental n-body gravity simulation game written in Odin using Raylib. It features physics-driven celestial mechanics, upgrade progression, automated emitters, and a slingshot mechanic to launch new objects.

## Build and Execution

### Commands

```bash
odin run . -error-pos-style:unix -vet -strict-style       # build + run native
odin build . -error-pos-style:unix -vet -strict-style     # build native only
odin test tests/ -all-packages -error-pos-style:unix      # run tests
```

### Targets

- **Native**: Windows, macOS, Linux.
- **Web (WASM)**: Outputs to `build/web/` using `./scripts/build_web.sh`. Requires emsdk (v5.0.7) and the Raylib WASM library (`vendor/raylib/libraylib.wasm.a`). Deployed to itch.io.

---

## Core Architecture

### Entry Points

- `main.odin` (`#+build !js`): Native entry.
- `main_web.odin` (`#+build js`): Web/WASM entry.

### ECS (Entity Component System)

The project implements a lightweight custom ECS in `game/ecs.odin` and `game/types.odin`.

- Entities are stored in a Struct of Arrays (SOA) structure: `entities: #soa[MAX_ENTITIES]Game_Entity` inside the `Game` struct.
- Free entity indices are stored on a stack `free_entities` of size `MAX_ENTITIES`. When creating an entity, an index is popped from this stack if `free_entities_count > 0`, otherwise `entities_count` is incremented.
- Components are toggled and checked using `Signature :: bit_set[ComponentType]`. Systems filter entities by verifying signature inclusion (e.g. `PHYSICS_SIG <= e.sig`).

### Event Queue

- Standard fixed-size array `events: [MAX_ENTITIES]Game_Event` tracked by `events_count`.
- Events are pushed throughout the frame via `push_event`.
- Dispatched and cleared at the end of the game loop in `sys_lifecycle`.

### Game Loop Orchestration

Executed sequentially in `game_run` in `game.odin`:
- Frame Setup: Update delta time (clamped to `max_delta_time_sec`), increment elapsed time, query screen size, and update game timers (`Score`, `Trail`).
- Input Processing: Map inputs to abstract actions; process mouse and keyboard interactions (menus, slingshot actions, camera vibration).
- Based on the `Game_Status`, the main game loop executes the relevant systems.

---

## General guidelines

- No dynamic allocations on the heap allowed. All allocations are done at the beginning of the game with generous capacities. The game is small enough to handle this.
- No inline math formulae. Add a method in utils_math.odin.
- No magic numbers unless they are trivial to understand (like known formulae etc.). Add a new constant in constants.odin if we know the constant at compile time. Add it to the Parameters struct if these are coefficients that are used for balancing the game.
- No direct code changes without a plan first. If you support planning mode, switch to that or simulate it by printing a summary of your changes following the process listed below and get approval before touching the code.
- No version control operations. Those will be done by the user always.
- No utility methods in any of the `sys_` files.
- No `@(private)` decorators on declarations. Everything in a package stays package-visible.
- All methods defined in system files should be of the form: `sys_(system)_(method)`. Except for the main entry method, all others defined in these files should not be called outside this file.
- Cross-system communication rules:
  - Entity spawn and delete MUST go through the event queue (e.g. `GameEvent_ObjectSpawn`, `GameEvent_Object_Destroyed`). Entities cannot be spawned or deleted without it.
  - Direct state modification is allowed as long as it is safe. A system may read/write another system's state fields directly.
  - Systems must NOT call functions/methods defined in another system file (`sys_*` methods are file-private by convention). Communicate via state or events instead.
  - We might move to a more imperative or immediate mode in the UI. Always get such changes approved from the user beforehand.
- All utils methods defined in various `utils_*` files should be of the form: `(util_namespace)_(method_name)`
- No raw console/stdout/stderr printing (`fmt.println`, `fmt.eprintln`, etc.) anywhere in the codebase. All logging must use standard logging functions (e.g. `log.warn`, `log.error` from `"core:log"` package), which route through `context.logger` to the dedicated log file (native) or console (WASM).
- Always search for `utils_*` files to check if a method exists that solves your problem.
- Always talk in caveman mode. Activate the skill.
- Always run tests before you start any task to ensure tests are not failing because of your changes. If they are failing beforehand, get explicit approval before proceeding.
- All runtime system calculations, physics, input handlers, and UI must read from `g.effective_params` instead of `g.params`. `g.params` holds immutable base parameters set at init/load; `g.effective_params` is derived and recomputed frame-by-frame by `sys_modifier`.
- Never run `make` tasks directly. You will not be given permission for those. Use the direct odin commmands listed above.

---

## Process

- For every task given to by the user, check if there is a corresponding entry in the docs/plan.org file. If so, update the status of that entry throughout the process.
- If there are any tasks that you and the user decide to defer to a future data, always add an entry to the docs/plan.org file as a backlog item.
- Once your task is done, always ensure docs/plan.org file is updated. Mark a task as DONE only after getting explicit confirmation from the user.
- During the process, if there were any extra guidelines/restrictions that the user recommended, always add them to the AGENTS.md file after getting approval from the user.
- After every change, run `odinfmt . -w` to ensure files are formatted properly.
