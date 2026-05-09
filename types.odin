package main

import rl "vendor:raylib"

Entity :: distinct u64

Timer :: struct {
	curr:     f32,
	interval: f32,
}

ComponentType :: enum {
	// Tag components
	// TODO: Add more tags
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
	base_cost:      f64,
}


CelestialType :: enum {
	None,
	Star,
	SuperJupiter,
	GiantPlanet,
	SuperNeptune,
	SubNeptune,
	MiniNeptune,
	MegaEarth,
	SuperEarth,
	SubEarth,
	DwarfPlanet,
}

CelestialComponent :: struct {
	type: CelestialType,
}

// TODO: Add some render specific properties here
RenderableComponent :: struct {}

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
	// This should be better grouped and allow only tags or spawnables
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

// TODO: We might need extra fields here later
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
	sig:           Signature,
	life:          LifeComponent,
	pos:           PositionComponent,
	trail:         PositionTrailComponent,
	velocity:      VelocityComponent,
	mass:          MassComponent,
	radius:        RadiusComponent,
	energy_source: EnergySourceComponent,
	emitter:       EmitterComponent,
	celestial:     CelestialComponent,
	renderable:    RenderableComponent,
}

Game_Shaders :: struct {}

Game_Textures :: struct {
	render:       rl.RenderTexture2D,
	blank:        rl.Texture2D,
	bg:           rl.RenderTexture2D,
	atlas:        rl.Texture2D,
	star_rect:    rl.Rectangle,
	marker_rect:  rl.Rectangle,
	emitter_rect: rl.Rectangle,
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
	g:                     f32,
	densities:             [CelestialType]f32,
	radii:                 [CelestialType]f32,
	launch_costs:          [CelestialType]f32,
	slingshot_power:       f32,
	slingshot_preview_len: i32,
	sim_rate:              f32,
	k_energy_gain:         f32,
	k_energy_loss:         f32,
	k_energy_source:       f32,
	k_energy_momentum:     f32,
}

Game :: struct {
	elapsed:             f32,
	params:              Game_Parameters,

	// Event queue
	events:              [MAX_ENTITIES]Game_Event,
	events_count:        u64,

	// Modifiers / Upgrades
	modifiers:           [MAX_MODIFIERS]Game_Modifier,

	// Render
	view:                rl.Rectangle,
	view_scale:          f32,
	camera:              rl.Camera2D,
	shaders:             Game_Shaders,
	textures:            Game_Textures,

	// Entities
	entities:            #soa[MAX_ENTITIES]Game_Entity,
	entities_count:      u64,
	free_entities:       [MAX_ENTITIES]Entity,
	free_entities_count: u64,

	// Input -> Slingshot
	slingshot:           Game_Slingshot,
	available_objects:   Signature, // TODO: Maybe move to something more specific?

	// Score
	score_timer:         Timer,
	energy:              f64,
	energy_gain_rate:    f64,
	energy_lose_rate:    f64,
	energy_over_time:    [10000]f64,
	total_objects:       int,

	// debug
	draw_debug_panel:    bool,
}
