package main

import "core:debug/pe"
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
}

Signature :: bit_set[ComponentType]

PositionComponent :: rl.Vector2

VelocityComponent :: rl.Vector2

LifeComponent :: struct {
	created_at: f32,
}

SizeComponent :: struct {
	mass:   f32,
	radius: f32,
}

RenderableComponent :: struct {
	color: rl.Color,
}

Game_Slingshot :: struct {
	active:     bool,
	start_pos:  rl.Vector2,
	canvas_pos: rl.Vector2,
	mass:       f32,
	radius:     f32,
}

Game_Event_ObjectSpawn :: struct {
	pos:    rl.Vector2,
	vel:    rl.Vector2,
	mass:   f32,
	radius: f32,
	color:  rl.Color,
	tags:   Signature,
}

Game_Event_ObjectOutOfBounds :: struct {
	id:  Entity,
	pos: rl.Vector2,
}

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

Game :: struct {
	elapsed:             f32,

	// Event queue
	events:              [MAX_ENTITIES]Game_Event,
	events_count:        u64,

	// Render
	view:                rl.Rectangle,
	view_scale:          f32,
	camera:              rl.Camera2D,
	render_texture:      rl.RenderTexture2D,

	// Entities
	entities:            #soa[MAX_ENTITIES]Game_Entity,
	entities_count:      u64,
	free_entities:       [MAX_ENTITIES]Entity,
	free_entities_count: u64,

	// Input -> Slingshot
	slingshot:           Game_Slingshot,

	// Score
	energy:              f64,
	energy_in:           f64,
	energy_out:          f64,
	energy_over_time:    [10000]f64,

	// debug
	draw_debug_panel:    bool,
}
