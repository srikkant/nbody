package main

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

// Temporary
COLORS := []rl.Color{rl.RED, rl.GREEN, rl.BLUE, rl.YELLOW, rl.ORANGE, rl.PURPLE, rl.MAGENTA}

input_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	relx := math.min(f32(rl.GetMouseX()) - g.view.x, f32(g.view.width))
	rely := math.min(f32(rl.GetMouseY()) - g.view.y, f32(g.view.height))
	return rl.GetScreenToWorld2D({relx / g.view_scale, rely / g.view_scale}, g.camera)
}

input_update :: proc(g: ^Game) {
	if (rl.IsMouseButtonPressed(.LEFT)) {
		g.slingshot_active = true
		g.slingshot_start_pos = input_mouse_pos(g)
		g.slingshot_mass = COMET_MASS
		g.slingshot_radius = COMET_RADIUS
	}

	if g.slingshot_active {
		if (rl.IsMouseButtonReleased(.LEFT)) {
			g.slingshot_active = false
			end := input_mouse_pos(g)
			vel := (g.slingshot_start_pos - end) * SLINGSHOT_STIFFNESS

			// TODO: This is just random color for now.
			color := COLORS[int(rand.uint32()) % len(COLORS)]

			id := entity_create(g)
			entity_add_position(g, id, g.slingshot_start_pos)
			entity_add_velocity(g, id, vel)
			entity_add_size(g, id, SizeComponent{g.slingshot_mass, g.slingshot_radius})
			entity_add_renderable(g, id, RenderableComponent{color})
		}
	}

	if (rl.IsKeyPressed(.C)) {
		g.slingshot_active = false
	}
}
