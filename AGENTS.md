# N-Body Forge — Agent Guide

## Project Overview

N-Body Forge is an incremental n-body gravity simulation game written in Odin using Raylib.
It features physics-driven celestial mechanics, upgrade progression, automate emitters, and a slingshot mechanic.

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
The project implements a lightweight custom ECS in [ecs.odin](file:///Users/srikkant/work/srikkant/nbody/game/ecs.odin) and [types.odin](file:///Users/srikkant/work/srikkant/nbody/game/types.odin):
- **Storage**: Entities are stored in a Struct of Arrays (SOA) structure: `entities: #soa[MAX_ENTITIES]Game_Entity` inside the `Game` struct.
- **Recycling**: Free entity indices are stored on a stack `free_entities` of size `MAX_ENTITIES`. When creating an entity, an index is popped from this stack if `free_entities_count > 0`, otherwise `entities_count` is incremented.
- **Component Bitsets**: Components are toggled and checked using `Signature :: bit_set[ComponentType]`. Systems filter entities by verifying signature inclusion (e.g. `PHYSICS_SIG <= e.sig`).

### Event Queue
- Standard fixed-size array `events: [MAX_ENTITIES]Game_Event` tracked by `events_count`.
- Events are pushed throughout the frame via `push_event`.
- Dispatched and cleared at the end of the game loop in `sys_lifecycle`.

---

## Game Loop Orchestration
Executed sequentially in `game_run` ([game/game.odin](file:///Users/srikkant/work/srikkant/nbody/game/game.odin)):
1. **Frame Setup**: Update delta time (clamped to `max_delta_time_sec`), increment elapsed time, query screen size, and update game timers (`Score`, `Trail`).
2. **Input Processing**: Map inputs to abstract actions; process mouse and keyboard interactions (menus, slingshot actions, camera vibration).
3. **Loop Phase Execution** (based on `Game_Status`):
   - **Menu**: `sys_camera` → `sys_render` → `sys_render_menu_main`.
   - **Paused**: `sys_render` → `sys_render_menu_pause`.
   - **Playing**: `sys_slingshot` → `sys_modifier` → `sys_automation` → `sys_physics` → `sys_score` → `sys_lifecycle` → `sys_camera` → `sys_render`.

---

## Systems Directory

- [frame.odin](file:///Users/srikkant/work/srikkant/nbody/game/frame.odin) — Capped delta time calculation and game-wide timer updates.
- [input.odin](file:///Users/srikkant/work/srikkant/nbody/game/input.odin) — Input action matching and handling (slingshot activation, menu triggers, orbit toggle).
- [sys_camera.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_camera.odin) — Focuses on coordinate `(0, 0)` (the central Star). Interpolates camera zoom to fit active entity boundary limits. Applies camera shake decay and slingshot pull vibration.
- [sys_slingshot.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_slingshot.odin) — Slingshot energy cost check and entity spawn event queueing upon release.
- [sys_render_slingshot.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_render_slingshot.odin) — Renders the slingshot Bezier pull line and its simulator trajectory.
- [sys_automation.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_automation.odin) — Processes emitter entities, managing periodic object spawning and emitter destruction timers.
- [sys_physics.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_physics.odin) — Calculates gravity vector offsets, updates velocities/positions, updates orbits/trails, and queues boundaries and collisions.
- [sys_lifecycle.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_lifecycle.odin) — Dispatches events, processes collision types (merge, shatter, debris, absorb), updates life timers, and cleans up dead entity indices.
- [sys_score.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_score.odin) — Generates energy based on orbital kinetic energy and active components.
- [sys_menu.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_menu.odin) — Renders main and pause UI panels and buttons.
- [sys_modifier.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_modifier.odin) — Iterates active modifier upgrades.
- [sys_render.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_render.odin) — Draws background starfields, nebulae, layered entities (using order), trails, VFX, and cursor indicators.
- [sys_render_ui.odin](file:///Users/srikkant/work/srikkant/nbody/game/sys_render_ui.odin) — Empty stub for future HUD rendering (current HUD/UI buttons reside in `sys_menu`).

---

## Math and Physics Mechanics

### Gravitational Acceleration (with Softening)
The gravity vector acting on a target from a source is softened to prevent infinite acceleration at zero distance:
$$\vec{a} = \frac{G \cdot M_{\text{source}} \cdot \vec{r}}{(r^2 + \epsilon)^{1.5}}$$
Where:
- $\vec{r}$ is the vector from target to source.
- $r^2$ is the squared distance.
- $\epsilon$ is the `gravity_softening_factor` (from parameters).

### Slingshot Preview (RK4 Integration)
The trajectory preview utilizes Runge-Kutta 4th order (RK4) integration to predict movement. It evaluates total gravity acceleration at 4 steps:
$$\begin{aligned}
k_1 &= \vec{v}_n, \quad l_1 = \vec{a}(\vec{x}_n) \\
k_2 &= \vec{v}_n + \frac{dt}{2} l_1, \quad l_2 = \vec{a}\left(\vec{x}_n + \frac{dt}{2} k_1\right) \\
k_3 &= \vec{v}_n + \frac{dt}{2} l_2, \quad l_3 = \vec{a}\left(\vec{x}_n + \frac{dt}{2} k_2\right) \\
k_4 &= \vec{v}_n + dt \cdot l_3, \quad l_4 = \vec{a}(\vec{x}_n + dt \cdot k_3)
\end{aligned}$$
$$\begin{aligned}
\vec{x}_{n+1} &= \vec{x}_n + \frac{dt}{6} (k_1 + 2k_2 + 2k_3 + k_4) \\
\vec{v}_{n+1} &= \vec{v}_n + \frac{dt}{6} (l_1 + 2l_2 + 2l_3 + l_4)
\end{aligned}$$
The preview dynamically adapts step size (`step_dt`) based on distance from the central star.

### Slingshot Bezier Pull Curve and Bow Sag
Renders a quadratic Bezier curve between `P0` (start drag) and `P2` (current cursor position) with control point `P1`:
$$P_1 = \frac{P_0 + P_2}{2} + \vec{v}_{\text{gravity\_pull}} + \vec{v}_{\text{bow\_sag}}$$
Where:
- $\vec{v}_{\text{gravity\_pull}}$ is a vector pulling the curve toward the central star based on drag distance.
- $\vec{v}_{\text{bow\_sag}}$ is a vector perpendicular to the drag direction, creating sag.

### Collision Classification
Collisions are processed in `sys_lifecycle` under four categories:
1. **StarAbsorb**: If one body is a `Star`. The Star absorbs the other entity.
2. **Debris**: If the colliding entities are of different types, or if their mass ratio exceeds `collision_mass_scaling_factor`:
   - The smaller body is destroyed.
   - The larger body is downgraded to the previous celestial type and loses mass based on relative speed.
   - The lost mass spawns as collectible energy fragments, a shockwave, and particle burst.
3. **Shatter**: If same-type entities collide at high velocity (relative speed squared > `shatter_threshold_sq`):
   - Both entities are destroyed.
   - The combined mass is spawned as collectible energy fragments, shockwaves, and particle bursts.
4. **Merge**: If same-type entities collide at low velocity:
   - Both entities are destroyed.
   - A new entity of the next tier celestial type is spawned at the average position, with combined mass and momentum. Unlocks the new tier for slingshot launches if unlockable.

---

## Utility modules

- [utils_general.odin](file:///Users/srikkant/work/srikkant/nbody/game/utils_general.odin) — General helper functions.
- [utils_geometry.odin](file:///Users/srikkant/work/srikkant/nbody/game/utils_geometry.odin) — Line-to-rectangle intersections (used for out-of-bounds screen indicators).
- [utils_math.odin](file:///Users/srikkant/work/srikkant/nbody/game/utils_math.odin) — Float utilities, vector operations, and timer update functions.
- [utils_physics.odin](file:///Users/srikkant/work/srikkant/nbody/game/utils_physics.odin) — Gravitational calculations and RK4 step calculations.
- [utils_rl.odin](file:///Users/srikkant/work/srikkant/nbody/game/utils_rl.odin) — Wrappers around Raylib draw calls and inputs.
- [utils_ui.odin](file:///Users/srikkant/work/srikkant/nbody/game/utils_ui.odin) — Raylib immediate UI draw functions (rounded buttons and panels).
- [messages.odin](file:///Users/srikkant/work/srikkant/nbody/game/messages.odin) — Localization string dictionaries.
- [constants.odin](file:///Users/srikkant/work/srikkant/nbody/game/constants.odin) — Compile-time settings, bounds, and entity component signatures.
- [params.odin](file:///Users/srikkant/work/srikkant/nbody/game/params.odin) — Configures physical parameters, visual properties, color configurations, and default game parameters.
- [assets.odin](file:///Users/srikkant/work/srikkant/nbody/game/assets.odin) — Asset loaders for textures, fonts, and shaders.
