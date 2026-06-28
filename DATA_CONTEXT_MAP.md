# Data Context Map

## 1. Core State Structs, Enums, and Constants

```odin
// Constants
MAX_DT                 :: 0.05
MAX_ENTITIES           :: 4096
MAX_MODIFIERS          :: 10
MAX_ORBIT_LENGTH       :: 100
POSITION_TRAIL_LENGTH  :: 5
AVG_CALC_TICKS         :: 10
BG_NEBULA_COUNT        :: 4
BG_STAR_COUNT          :: 1600
BG_NUM_LAYERS          :: 4

// Enums
Status :: enum { Playing, Paused, Exit }
ObjectType :: enum { Celestial, Emitter }
Timer_BuiltIn :: enum { Score, Trail }
Celestial_Type :: enum { None, Asteroid, Moonlet, DwarfPlanet, SubEarth, SuperEarth, MegaEarth, MiniNeptune, SubNeptune, SuperNeptune, GiantPlanet, SuperJupiter, Star }
Celestial_Class :: enum { Debris, Terrestrial, GasGiant, Anchor }
Component_Type :: enum { Celestial, Emitter, Position, Orbit, Velocity, Life, Mass, Radius, EnergySource, Renderable, CollectibleEnergy, Shockwave }
Input_InteractionType :: enum { Down, Pressed, Released }
Input_Action :: enum { None, Game_Pause, Game_Resume, Slingshot_Activate, Slingshot_Move, Slingshot_Release, Slingshot_Cancel, View_ToggleOrbit, Demolish_Object }
Render_LayerType :: enum { Debris, Terrestrial, GasGiant, Stars, EmitterStations, OrbitPoints, Collectibles, Effects }
Slingshot_Status :: enum { Inactive, Active, Released }

// Component Structs
Component_Position :: struct { current: rl.Vector2, trail: [POSITION_TRAIL_LENGTH]rl.Vector2, trail_head: int }
Component_Orbit :: struct { points: [MAX_ORBIT_LENGTH]rl.Vector2, head: int, angle: f32, count: int, max_distance_sq: f32 }
Component_Velocity :: struct { current: rl.Vector2, acceleration: rl.Vector2 }
Component_Mass :: f32
Component_Radius :: f32
Component_Life :: struct { created_at: f32, remaining: Timer }
Component_EnergySource :: struct { output: f32, timer: Timer }
Component_Emitter :: struct { emit_density: f32, emit_radius: f32, emit_vel: rl.Vector2, emit_celestial: Component_Celestial, emit_color: rl.Color, max_count: int, current_count: int, timer: Timer, destroy_timer: Timer, base_cost: f64 }
Component_Celestial :: struct { type: Celestial_Type }
Component_Renderable :: struct { color: rl.Color }
Component_CollectibleEnergy :: struct { energy: f64 }
Component_Shockwave :: struct { growth_rate: f32, color: rl.Color }

// ECS Entities & Signatures
Entity_Id :: distinct u64
Entity_Signature :: bit_set[Component_Type]
Entity :: struct {
	sig:                Entity_Signature,
	life:               Component_Life,
	pos:                Component_Position,
	orbit:              Component_Orbit,
	velocity:           Component_Velocity,
	mass:               Component_Mass,
	radius:             Component_Radius,
	energy_source:      Component_EnergySource,
	emitter:            Component_Emitter,
	celestial:          Component_Celestial,
	renderable:         Component_Renderable,
	collectible_energy: Component_CollectibleEnergy,
	shockwave:          Component_Shockwave,
}

// System-specific State Structs
Timer :: struct { curr: f32, interval: f32, done: bool }
Camera :: struct { rl_cam: rl.Camera2D, shake_dir: rl.Vector2, shake_intensity: f32 }
Score :: struct { energy: f64, energy_rate_ticker: int, total_objects: int, energy_gains: [AVG_CALC_TICKS]f64, energy_losses: [AVG_CALC_TICKS]f64 }
Modifier :: struct { active: bool, started_at: f64, duration: f64 }
Help :: struct { launch_done: bool }

Input_Matcher_Base :: struct { interaction: Input_InteractionType, status: Status }
Input_Matcher_Mouse :: struct { using base: Input_Matcher_Base, key: rl.MouseButton }
Input_Matcher_Keyboard :: struct { using base: Input_Matcher_Base, key: rl.KeyboardKey }
Input_Matcher :: union { Input_Matcher_Mouse, Input_Matcher_Keyboard }
Input :: struct { ignore: bool, mouse_pos_screen: rl.Vector2, mouse_pos: rl.Vector2, mouse_scroll_move: rl.Vector2, action: Input_Action, controls: [Input_Action]Input_Matcher }

Render_Layer :: struct { entities: [MAX_ENTITIES]Entity_Id, count: int }
Render_Background_Nebula :: struct { pos: rl.Vector2, color: rl.Color, radius: f32, drift_speed: f32, drift_phase: f32 }
Render_Background_Star :: struct { pos: rl.Vector2, layer: int, size: f32, blink_speed: f32, blink_phase: f32, color: rl.Color }
Render_Background :: struct { stars: [BG_STAR_COUNT]Render_Background_Star, nebulae: [BG_NEBULA_COUNT]Render_Background_Nebula }
Render_LaunchMenu :: struct { opacity: f32, inactive_timer: Timer, h_idx: int, v_idx: int }
Render :: struct { rect: rl.Rectangle, scale: f32, show_orbits: bool, layers: [Render_LayerType]Render_Layer, bg: Render_Background, launch_menu: Render_LaunchMenu }

Slingshot_Snap :: struct { active: bool, start_pos: rl.Vector2, end_pos: rl.Vector2, color: rl.Color, timer: f32 }
Slingshot_RingFlash :: struct { active: bool, pos: rl.Vector2, color: rl.Color, radius: f32, max_radius: f32, life: f32 }
Slingshot_Output_Emitter :: struct { emitter: Component_Emitter }
Slingshot_Output_Celestial :: struct { celestial: Component_Celestial }
Slingshot_Output :: union { Slingshot_Output_Emitter, Slingshot_Output_Celestial }
Slingshot :: struct { available_objects: bit_set[Celestial_Type], output: Slingshot_Output, status: Slingshot_Status, can_launch: bool, start_pos: rl.Vector2, end_pos: rl.Vector2, shimmer_time: f32, launch_power: f32, preview: f32, preview_points: [600]rl.Vector2, preview_times: [600]f32, snap: Slingshot_Snap, ring_flashes: [8]Slingshot_RingFlash, obj_color: rl.Color, obj_radius: f32 }

Theme :: struct { name: string, color_bg: rl.Color, color_error: rl.Color, colors_bg_nebula: [4]rl.Color, colors_bg_star: [5]rl.Color, spacing_s: f32, spacing_m: f32, spacing_l: f32, color_cursor_collector: rl.Color, color_slingshot_trail: rl.Color, color_slingshot_trail_error: rl.Color, margin_top_bar: f32, font_title: Assets_FontType }

Parameters_Slingshot :: struct { launch_power: f32, preview_duration: f32 }
Parameters_Physics :: struct { gravity_constant: f32, mass_absorb_factor: f32, collision_mass_loss_factor: f32, collision_shatter_threshold_factor: f32, spawn_invincibility_duration_sec: f32, cursor_distance: f32, cursor_distance_squared: f32, world_radius: f32, world_radius_squared: f32, energy_gain_factor: f32, energy_source_gain_factor: f32, energy_refund_factor: f32 }
Parameters_Celestial :: struct { density: f32, radius: f32, launch_cost: f32, color: rl.Color, visual_class: Celestial_Class, quad_multiplier: f32, trail_multiplier: f32, glow_intensity: f32 }
Parameters :: struct { celestials: [Celestial_Type]Parameters_Celestial, physics: Parameters_Physics, slingshot: Parameters_Slingshot }

// Events
GameEvent_ObjectSpawn :: struct { pos: rl.Vector2, density: f32, radius: f32, velocity: rl.Vector2, show_orbit: bool, renderable: Component_Renderable, energy_source: Component_EnergySource, emitter: Component_Emitter, celestial: Component_Celestial }
GameEvent_Object_OutOfBounds :: struct { id: Entity_Id }
GameEvent_Object_Destroyed :: struct { id: Entity_Id }
GameEvent_Object_Demolish :: struct {}
GameEvent_Collision :: struct { id1: Entity_Id, id2: Entity_Id }
GameEvent :: union { GameEvent_ObjectSpawn, GameEvent_Collision, GameEvent_Object_OutOfBounds, GameEvent_Object_Destroyed, GameEvent_Object_Demolish }

// Main Game Controller
Game :: struct {
	elapsed:             f32,
	dt:                  f32,
	screenw:             f32,
	screenh:             f32,
	scale:               f32,
	status:              Status,
	theme:               Theme,
	params:              Parameters,
	assets:              Assets,
	input:               Input,
	help:                Help,
	camera:              Camera,
	render:              Render,
	slingshot:           Slingshot,
	score:               Score,
	timers:              [Timer_BuiltIn]Timer,
	entities_count:      u64,
	entities:            #soa[MAX_ENTITIES]Entity,
	free_entities_count: u64,
	free_entities:       [MAX_ENTITIES]Entity_Id,
	events_count:        u64,
	events:              [MAX_ENTITIES]GameEvent,
	modifiers_count:     u64,
	modifiers:           [MAX_MODIFIERS]Modifier,
}
```

## 2. Memory Management and Allocation Approach

- **Static Preallocation**: Components (`entities` as Struct-of-Arrays), input buffers, timers, background layers, and events (`events`) are statically preallocated within the `Game` structure to maximum capacities (e.g., `MAX_ENTITIES = 4096`), eliminating per-frame heap allocations or resizing overhead.
- **Entity Lifecycle / Recycled Indices**: Entity slot allocation is managed through a free-list stack (`free_entities: [4096]Entity_Id` tracked by `free_entities_count`). Creating an entity pops a recycled index from the stack (or increments `entities_count` if empty) and clears its `Entity_Signature`; freeing an entity clears its signature and pushes the ID back onto the free stack.
- **Context Allocators**:
  - **Native Platform (`main.odin`)**: Utilizes Odin's `mem.Tracking_Allocator` wrapper around the default context allocator to monitor allocations, capture peaks, and output verbose leak/bad-free traces at teardown.
  - **Web/WASM Target (`main_web.odin`)**: Implements an aligned custom allocator (`emscripten_allocator`) wrapping Emscripten's libc allocation functions (`malloc`, `free`, `realloc`, `calloc`) to satisfy memory alignment constraints required for Odin maps, dynamic arrays, and SIMD instruction compatibility.

## 3. Mutation Flow in the Update Loop

1. Frame delta times are clamped and inputs are mapped to abstract action flags (`Input` state).
2. Dependent subsystems run sequentially to process slingshot calculations, emitter ticking, Newtonian physics integration, scoring, and lifecycle events.
3. The lifecycle system processes collision resolutions (absorptions, merges, shatters) and queues spawns or recycling, preceding final camera interpolation and layered rendering.
