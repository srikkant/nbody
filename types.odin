package main

import rl "vendor:raylib"

Entity :: distinct u64

Timer :: struct {
	curr:     f32,
	interval: f32,
}

ComponentType :: enum {
	// Tag components
	Celestial,
	Emitter,
	// General components
	Position,
	PositionTrail,
	Velocity,
	Life,
	Mass,
	Radius,
	EnergySource,
	Renderable,
	CollectibleEnergy,
}

Signature :: bit_set[ComponentType]

PositionComponent :: struct {
	current: rl.Vector2,
}

PositionTrailComponent :: struct {
	points: [MAX_TRAIL_LENGTH]rl.Vector2,
	head:   int,
	angle:  f32,
	count:  int,
}

VelocityComponent :: rl.Vector2

MassComponent :: f32

RadiusComponent :: f32

LifeComponent :: struct {
	created_at: f32,
}

EnergySourceComponent :: struct {
	output: f32,
	timer:  Timer,
}

EmitterComponent :: struct {
	emit_density:   f32,
	emit_radius:    f32,
	emit_vel:       rl.Vector2,
	emit_celestial: CelestialComponent,
	max_count:      int,
	current_count:  int,
	timer:          Timer,
	destroy_timer:  Timer,
	base_cost:      f64,
}

CelestialType :: enum {
	None,
	Asteroid,
	Moonlet,
	DwarfPlanet,
	SubEarth,
	SuperEarth,
	MegaEarth,
	MiniNeptune,
	SubNeptune,
	SuperNeptune,
	GiantPlanet,
	SuperJupiter,
	Star,
}

CelestialComponent :: struct {
	type: CelestialType,
}

RenderableComponent :: struct {}

CollectibleEnergyComponent :: struct {
	energy: f64,
}

Game_SlingshotOutput_Emitter :: struct {
	emitter: EmitterComponent,
}

Game_SlingshotOutput_Celestial :: struct {
	celestial: CelestialComponent,
}

Game_SlingshotOutput :: union {
	Game_SlingshotOutput_Emitter,
	Game_SlingshotOutput_Celestial,
}

Game_Slingshot :: struct {
	output:       Game_SlingshotOutput,
	active:       bool,
	can_launch:   bool,
	start_pos:    rl.Vector2,
	launch_power: f32,
	preview:      f32,
}

Game_Event_ObjectSpawn :: struct {
	pos:           rl.Vector2,
	density:       f32,
	radius:        f32,
	velocity:      rl.Vector2,
	show_trail:    bool,
	energy_source: EnergySourceComponent,
	emitter:       EmitterComponent,
	celestial:     CelestialComponent,
	tags:          Signature,
}

Game_Event_ObjectOutOfBounds :: struct {
	id: Entity,
}

Game_Event_ObjectDestroyed :: struct {
	id: Entity,
}

Game_Event_ApplyModifier :: Game_Modifier

Game_Event_Collision :: struct {
	id1: Entity,
	id2: Entity,
}

Game_Event :: union {
	Game_Event_ObjectSpawn,
	Game_Event_Collision,
	Game_Event_ObjectOutOfBounds,
	Game_Event_ObjectDestroyed,
}

Game_Entity :: struct {
	sig:                Signature,
	life:               LifeComponent,
	pos:                PositionComponent,
	trail:              PositionTrailComponent,
	velocity:           VelocityComponent,
	mass:               MassComponent,
	radius:             RadiusComponent,
	energy_source:      EnergySourceComponent,
	emitter:            EmitterComponent,
	celestial:          CelestialComponent,
	renderable:         RenderableComponent,
	collectible_energy: CollectibleEnergyComponent,
}

Assets_Font :: enum {
	Heading,
	Body,
}

Assets_Texture :: enum {
	Bg,
	Atlas,
}

Assets_Map :: struct {
	fonts:    [Assets_Font]rl.Font,
	textures: [Assets_Texture]rl.Texture2D,
}

Game_TextureType :: enum {
	Objects_Star,
	Objects_Emitter,
	Markers_OutOfBounds,
	Collectibles_Energy,
}

Game_Texture :: struct {
	texture: Assets_Texture,
	rect:    rl.Rectangle,
}

Game_Font :: struct {
	font:    Assets_Font,
	size:    f32,
	spacing: f32,
}

Game_FontType :: enum {
	Heading,
	Body,
}

Game_Modifier :: struct {
	active:             bool,
	started_at:         f64,
	duration:           f64,
	slingshot_power:    f32,
	slingshot_preview:  f32,
	density_deltas:     [CelestialType]f32,
	radii_deltas:       [CelestialType]f32,
	launch_cost_deltas: [CelestialType]f32,
}

Game_Parameters :: struct {
	g:                      f32,
	densities:              [CelestialType]f32,
	radii:                  [CelestialType]f32,
	launch_costs:           [CelestialType]f32,
	slingshot_power:        f32,
	slingshot_preview_len:  i32,
	sim_rate:               f32,
	k_energy_gain:          f32,
	k_energy_loss:          f32,
	k_energy_source:        f32,
	k_energy_momentum:      f32,
	k_mass_loss:            f32,
	k_collision_mass_scale: f32,
	k_shatter_base:         f32,
	k_debris_mass_loss:     f32,
	k_out_of_bounds_refund: f32,
	k_star_energy_scale:    f32,
	k_collect_dist:         f32,
	k_collect_dist_sq:      f32,
}

Game :: struct {
	elapsed:             f32,
	params:              Game_Parameters,
	mouse_pos:           rl.Vector2,

	// Event queue
	events:              [MAX_ENTITIES]Game_Event,
	events_count:        u64,

	// Modifiers / Upgrades
	modifiers:           [MAX_MODIFIERS]Game_Modifier,

	// Render
	view:                rl.Rectangle,
	view_scale:          f32,
	camera:              rl.Camera2D,

	// Assets
	assets:              Assets_Map,
	textures:            [Game_TextureType]Game_Texture,
	fonts:               [Game_FontType]Game_Font,

	// Special render textures
	render_target:       rl.RenderTexture2D,
	bg_texture:          rl.RenderTexture2D,

	// View options
	show_trails:         bool,

	// Entities
	entities:            #soa[MAX_ENTITIES]Game_Entity,
	entities_count:      u64,
	free_entities:       [MAX_ENTITIES]Entity,
	free_entities_count: u64,

	// Input -> Slingshot
	slingshot:           Game_Slingshot,
	available_objects:   bit_set[CelestialType],

	// Score
	score_timer:         Timer,
	energy:              f64,
	energy_rate_ticker:  int,
	energy_gains:        [RATE_CALC_TICKS]f64,
	energy_losses:       [RATE_CALC_TICKS]f64,
	total_objects:       int,

	// debug
	draw_debug_panel:    bool,
}
