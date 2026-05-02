package main

import rl "vendor:raylib"

Entity :: distinct u64

ComponentType :: enum {
	Position,
	Velocity,
	Size,
	Renderable,

	// Tag components
	Star,
}

Signature :: bit_set[ComponentType]


PositionComponent :: rl.Vector2

VelocityComponent :: rl.Vector2

SizeComponent :: struct {
	mass:   f32,
	radius: f32,
}

RenderableComponent :: struct {
	color: rl.Color,
}

Game :: struct {
	elapsed:              f32,

	// Render
	view:                 rl.Rectangle,
	view_scale:           f32,
	camera:               rl.Camera2D,
	render_texture:       rl.RenderTexture2D,

	// Entities
	entities:             #soa[MAX_ENTITIES]GameEntity,
	free_ids:             [MAX_ENTITIES]Entity,
	entity_count:         u64,
	free_entity_count:    u64,

	// Input -> Slingshot
	slingshot_active:     bool,
	slingshot_start_pos:  rl.Vector2,
	slingshot_canvas_pos: rl.Vector2,
	slingshot_mass:       f32,
	slingshot_radius:     f32,
}

GameEntity :: struct {
	sig:        Signature,
	pos:        PositionComponent,
	vel:        VelocityComponent,
	size:       SizeComponent,
	renderable: RenderableComponent,
}
