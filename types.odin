package main

import "core:math/big"
import rl "vendor:raylib"

Entity :: distinct u64

ComponentType :: enum {
	Position,
	Velocity,
	Size,
	Life,
	Renderable,

	// Tag components
	Star,
	Comet,
	// TODO: Add more tags
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

SizeComponent :: struct {
	mass:   f32,
	radius: f32,
}

// TODO: Add some render specific properties here
RenderableComponent :: struct {}

Game_Slingshot :: struct {
	active:       bool,
	start_pos:    rl.Vector2,
	canvas_pos:   rl.Vector2,
	mass:         f32,
	radius:       f32,
	launch_power: f32,
	preview:      f32,
}

Game_Event_ObjectSpawn :: struct {
	pos:    rl.Vector2,
	vel:    rl.Vector2,
	mass:   f32,
	radius: f32,
	tags:   Signature,
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
	sig:        Signature,
	life:       LifeComponent,
	pos:        PositionComponent,
	vel:        VelocityComponent,
	size:       SizeComponent,
	renderable: RenderableComponent,
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
	active:                 bool,
	started_at:             f64,
	duration:               f64,
	star_radius:            f32,
	star_mass:              f32,
	slingshot_launch_power: f32,
	slingshot_preview:      f32,
}

Game :: struct {
	elapsed:               f32,

	// Event queue
	events:                [MAX_ENTITIES]Game_Event,
	events_count:          u64,

	// Modifiers / Upgrades
	modifiers:             [MAX_MODIFIERS]Game_Modifier,

	// Render
	view:                  rl.Rectangle,
	view_scale:            f32,
	camera:                rl.Camera2D,
	shaders:               Game_Shaders,
	textures:              Game_Textures,

	// Entities
	entities:              #soa[MAX_ENTITIES]Game_Entity,
	entities_count:        u64,
	free_entities:         [MAX_ENTITIES]Entity,
	free_entities_count:   u64,

	// Input -> Slingshot
	slingshot:             Game_Slingshot,


	// Score
	energy:                f64,
	energy_in:             f64,
	energy_out:            f64,
	energy_rate:           f64,
	energy_over_time:      [10000]f64,
	dark_energy:           f64,
	dark_energy_in:        f64,
	dark_energy_out:       f64,
	dark_energy_rate:      f64,
	dark_energy_over_time: [10000]f64,
	total_objects:         int,

	// debug
	draw_debug_panel:      bool,
}
