package main

import "core:math"
import rl "vendor:raylib"

input_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	relx := math.min(f32(rl.GetMouseX()) - g.view.x, f32(g.view.width))
	rely := math.min(f32(rl.GetMouseY()) - g.view.y, f32(g.view.height))
	return rl.GetScreenToWorld2D({relx / g.view_scale, rely / g.view_scale}, g.camera)
}

sys_input :: proc(g: ^Game) {
	// Update all timers in the input system
	g.elapsed += rl.GetFrameTime()

	if (rl.IsMouseButtonPressed(.LEFT)) {
		g.slingshot.active = true
		g.slingshot.start_pos = input_mouse_pos(g)
		g.slingshot.type = .DwarfPlanet
	}

	if g.slingshot.active {
		obj_type := g.slingshot.type
		obj_density := g.params.densities[obj_type]
		obj_radius := g.params.radii[obj_type]
		end := input_mouse_pos(g)
		vel := physics_get_slingshot_release_velocity(g, end)

		cost := f64(
			g.params.k_energy_loss *
			(g.params.launch_costs[obj_type] +
					(obj_density * obj_radius * obj_radius * rl.Vector2LengthSqr(vel))),
		)

		g.slingshot.can_launch = g.energy >= cost

		if (rl.IsMouseButtonReleased(.LEFT)) {
			g.slingshot.active = false

			if (g.slingshot.can_launch) {
				g.events[g.events_count] = Game_Event_ObjectSpawn {
					pos        = g.slingshot.start_pos,
					vel        = vel,
					density    = obj_density,
					radius     = obj_radius,
					show_trail = true,
					tags       = {.DwarfPlanet},
				}
				g.events_count += 1
				g.energy -= cost // TODO: should this be an event?
			}
		}
	}

	if (rl.IsKeyPressed(.C)) {
		g.slingshot.active = false
	}

	if (rl.IsKeyPressed(.P)) {
		g.draw_debug_panel = !g.draw_debug_panel
	}
}
