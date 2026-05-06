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
	DwarfPlanet,
	Planet,

	// General components
	Position,
	Velocity,
	Size,
	Life,
	EnergySource,
	Renderable,
}

Signature :: bit_set[ComponentType]

PositionComponent :: struct {
	current:  rl.Vector2,
	previous: [20]rl.Vector2,
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
	pos:           PositionComponent,
	vel:           VelocityComponent,
	size:          SizeComponent,
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
	vel:           VelocityComponent,
	size:          SizeComponent,
	energy_source: EnergySourceComponent,
	renderable:    RenderableComponent,
}

Game_Shaders :: struct {
	glow: rl.Shader,
}

Game_Textures :: struct {
	render:    rl.RenderTexture2D,
	blank:     rl.Texture2D,
	bg:        rl.RenderTexture2D,

	// Star texture and rect
	star:      rl.Texture2D,
	star_rect: rl.Rectangle,
}

Game_Modifier :: struct {
	active:             bool,
	started_at:         f64,
	duration:           f64,
	slingshot_power:    f32,
	slingshot_preview:  f32,
	mass_deltas:        [ComponentType]f32,
	radii_deltas:       [ComponentType]f32,
	launch_cost_deltas: [ComponentType]f32,
}

Game_Parameters :: struct {
	g:                     f32,
	masses:                [ComponentType]f32,
	radii:                 [ComponentType]f32,
	launch_costs:          [ComponentType]f32,
	slingshot_power:       f32,
	slingshot_preview_len: i32,
	sim_rate:              f32,
	energy_mass_factor:    f32,
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


	// Score
	score_timer:         Timer,
	energy:              f64,
	energy_gain_rate:    f64,
	energy_out:          f64,
	energy_rate:         f64,
	energy_over_time:    [10000]f64,
	total_objects:       int,

	// debug
	draw_debug_panel:    bool,
}
