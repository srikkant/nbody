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

sys_input :: proc(g: ^Game) {
	if (rl.IsMouseButtonPressed(.LEFT)) {
		g.slingshot.active = true
		g.slingshot.start_pos = input_mouse_pos(g)
		g.slingshot.mass = COMET_MASS
		g.slingshot.radius = COMET_RADIUS
	}

	if g.slingshot.active {
		if (rl.IsMouseButtonReleased(.LEFT)) {
			g.slingshot.active = false
			end := input_mouse_pos(g)
			vel := physics_get_slingshot_release_velocity(g.slingshot.start_pos, end)

			id := entity_create(g)
			g.events[g.events_count] = Game_Event_ObjectSpawn {
				pos    = g.slingshot.start_pos,
				vel    = vel,
				mass   = g.slingshot.mass,
				radius = g.slingshot.radius,
				tags   = {.Comet},
			}
			g.events_count += 1
		}
	}

	if (rl.IsKeyPressed(.C)) {
		g.slingshot.active = false
	}

	if (rl.IsKeyPressed(.P)) {
		g.draw_debug_panel = !g.draw_debug_panel
	}
}
