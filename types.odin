package main

import rl "vendor:raylib"

Entity :: distinct u64

Timer :: struct {
	acc: f32,
	val: f32,
}

ComponentType :: enum {
	// Tag components
	// TODO: Add more tags
	Star,

	// Planet types
	SuperJupiter,
	GiantPlanet,
	SuperNeptune,
	SubNeptune,
	MiniNeptune,
	MegaEarth,
	SuperEarth,
	SubEarth,
	DwarfPlanet,

	// other objects
	Emitter,

	// General components
	Position,
	PositionTrail,
	Velocity,
	Size,
	Life,
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

LifeComponent :: struct {
	created_at: f32,
}

EnergySourceComponent :: struct {
	output: f32,
	timer:  Timer,
}

SizeComponent :: struct {
	mass:   f32,
	radius: f32,
}

EmitterComponent :: struct {
	emit_signature: Signature,
	emit_density:   f32,
	emit_radius:    f32,
	timer:          Timer,
	base_cost:      f32,
}

// TODO: Add some render specific properties here
RenderableComponent :: struct {}

Game_Slingshot :: struct {
	type:         ComponentType, // This should be better grouped and allow only tags or spawnables
	active:       bool,
	can_launch:   bool,
	start_pos:    rl.Vector2,
	launch_power: f32,
	preview:      f32,
}

Game_Event_ObjectSpawn :: struct {
	density:       f32,
	radius:        f32,
	pos:           rl.Vector2,
	show_trail:    bool,
	vel:           rl.Vector2,
	energy_source: EnergySourceComponent,
	tags:          Signature,
}

Game_Event_ObjectOutOfBounds :: struct {
	id:  Entity,
	pos: rl.Vector2,
}

// TODO: We might need extra fields here later
Game_Event_ApplyModifier :: Game_Modifier

Game_Event_Collision :: struct {
	id1: Entity,
	id2: Entity,
	pos: rl.Vector2,
}

Game_Event :: union {
	Game_Event_ObjectSpawn,
	Game_Event_Collision,
	Game_Event_ObjectOutOfBounds,
}

Game_Entity :: struct {
	sig:           Signature,
	life:          LifeComponent,
	pos:           PositionComponent,
	trail:         PositionTrailComponent,
	vel:           VelocityComponent,
	size:          SizeComponent,
	energy_source: EnergySourceComponent,
	emitter:       EmitterComponent,
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
	density_deltas:     [ComponentType]f32,
	radii_deltas:       [ComponentType]f32,
	launch_cost_deltas: [ComponentType]f32,
}

Game_Parameters :: struct {
	g:                     f32,
	densities:             [ComponentType]f32,
	radii:                 [ComponentType]f32,
	launch_costs:          [ComponentType]f32,
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
