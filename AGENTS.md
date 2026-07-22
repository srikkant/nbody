# Agent Guide

## Project Overview

This project is an incremental n-body gravity simulation game written in Odin using Raylib. It
features physics-driven celestial mechanics, upgrade progression, automated emitters, and a
slingshot mechanic to launch new objects.

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
- **Web (WASM)**: Outputs to `build/web/` using `./scripts/build_web.sh`. Requires emsdk (v5.0.7)
  and the Raylib WASM library (`vendor/raylib/libraylib.wasm.a`). Deployed to itch.io.

---

## Core Architecture

### Entry Points

- `main.odin` (`#+build !js`): Native entry. Sets up context with a tracking allocator for leak
  checking, initializes game state, and loops `game_run`.
- `main_web.odin` (`#+build js`): Web/WASM entry. Exports `start()`, `run()`, and `update_size()`
  for emscripten. Implements `emscripten_allocator` on top of libc allocator (`malloc`, `free`,
  `realloc`, `calloc`) to ensure proper alignment required by maps and SIMD features.

### ECS (Entity Component System)

The project implements a lightweight custom ECS in `game/ecs.odin` and `game/types.odin`.

- Entities are stored in a Struct of Arrays (SOA) structure: `entities:
  #soa[MAX_ENTITIES]Game_Entity` inside the `Game` struct.
- Free entity indices are stored on a stack `free_entities` of size `MAX_ENTITIES`. When creating an
  entity, an index is popped from this stack if `free_entities_count > 0`, otherwise
  `entities_count` is incremented.
- Components are toggled and checked using `Signature :: bit_set[ComponentType]`. Systems filter
  entities by verifying signature inclusion (e.g. `PHYSICS_SIG <= e.sig`).

### Event Queue

- Standard fixed-size array `events: [MAX_ENTITIES]Game_Event` tracked by `events_count`.
- Events are pushed throughout the frame via `push_event`.
- Dispatched and cleared at the end of the game loop in `sys_lifecycle`.

### Game Loop Orchestration

Executed sequentially in `game_run` in `game.odin`:

- Frame Setup: Update delta time (clamped to `max_delta_time_sec`), increment elapsed time, query
  screen size, and update game timers (`Score`, `Trail`).
- Input Processing: Map inputs to abstract actions; process mouse and keyboard interactions (menus,
  slingshot actions, camera vibration).
- Based on the `Game_Status`, the main game loop executes the relevant systems.

### Persistence

`game/persistence.odin` (`#+build !js`, native only; `game/persistence_web.odin` provides no-op
stubs for the js build so call sites stay tag-free):

- Binary save format: fixed header (`SAVE_MAGIC`, `SAVE_VERSION`, payload length, crc32) plus a
  field-by-field little-endian payload. No padding, no raw struct dumps. Version or checksum
  mismatch = reject load, start fresh, never crash.
- Serializes into a static buffer (`MAX_SAVE_SIZE`); no heap allocations. Disk writes are atomic
  (`save.bin.tmp` + rename). Save location is the OS user data dir (`persist_save_dir`).
- Hooks: `game_init` calls `persist_load_from_disk` (falls back to `game_reset` on failure),
  `game_run` Playing branch calls `persist_maybe_autosave` when the built-in Autosave timer triggers,
  `main.odin` calls `persist_save_to_disk` on exit.
- Transient state (slingshot preview/drag, events, camera offset/shake, scratch buffers) is not
  persisted; it resets to defaults on load and status becomes `.Paused` (the user resumes
  manually).
- Decisions: `docs/adr/0001-serialization.org`. Plan: `plan/serialization.org`.

---

## General guidelines

- No dynamic allocations on the heap allowed. All allocations are done at the beginning of the game
  with generous capacities. The game is small enough to handle this.
- No inline math formulae. Add a method in utils_math.odin.
- No magic numbers unless they are trivial to understand (like known formulae etc.). Add a new
  constant in constants.odin if we know the constant at compile time. Add it to the Parameters
  struct if these are coefficients that are used for balancing the game.
- No direct code changes without a plan first. If you support planning mode, switch to that or
  simulate it by printing a summary of your changes following the process listed below and get
  approval before touching the code.
- No version control operations. Those will be done by the user always.
- No utility methods in any of the `sys_` files.
- No `@(private)` decorators on declarations. Everything in a package stays package-visible.
- No inline logging (`fmt.eprintln`, `core:log`, etc.) anywhere in the codebase. All logging goes
  to a dedicated log file; that system is not set up yet, so until then fail silently and return
  errors to the caller.
- Always search for `utils_*` files to check if a method exists that solves your problem.
- Always talk in caveman mode. Activate the skill.
- Always run `make test` before you start any task to ensure tests are not failing because of your
  changes. If they are failing beforehand, get explicit approval before proceeding.
- If there are any tasks that are deferred to a later date, always file them under plan/plan.org
  without fail.

---

## Process

- For every task given to by the user, check if there is a corresponding entry in the plan/plan.org
  file. If so, update the status of that entry throughout the process.
- If there are any tasks that you and the user decide to defer to a future data, always add an entry
  to the plan/plan.org file as a backlog item.
- Once your task is done, always ensure plan/plan.org file is updated.
- During the process, if there were any extra guidelines/restrictions that the user recommended,
  always add them to the AGENTS.md file after getting approval from the user.
