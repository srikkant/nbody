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
	dt := frame_time()
	g.elapsed += dt
	g.mouse_pos = input_mouse_pos(g)

	for i in Game_TimerType {
		utils_math_update_timer(&g.timers[i], dt)
	}

	if (rl.IsMouseButtonPressed(.LEFT)) {
		g.slingshot.active = true
		g.slingshot.start_pos = input_mouse_pos(g)
	}

	if g.slingshot.active {
		end := input_mouse_pos(g)
		vel := physics_get_slingshot_release_velocity(g, end)

		obj_type: ComponentType
		event := Game_Event_ObjectSpawn {
			pos = g.slingshot.start_pos,
		}

		cost: f64
		color := get_object_color(g)

		switch out in g.slingshot.output {
		case Game_SlingshotOutput_Emitter:
			obj_type = .Emitter
			event.tags = {.Emitter}
			event.radius = g.params.radii[out.emitter.emit_celestial.type]
			event.emitter = out.emitter
			event.emitter.emit_vel = vel
			event.emitter.emit_density = g.params.densities[out.emitter.emit_celestial.type]
			event.emitter.emit_radius = g.params.radii[out.emitter.emit_celestial.type]
			event.emitter.emit_color = color
			cost = f64(
				g.params.k_energy_loss *
				(event.density * event.radius * event.radius * rl.Vector2LengthSqr(vel)),
			)
		case Game_SlingshotOutput_Celestial:
			event.tags = {.Celestial}
			event.celestial = out.celestial
			event.density = g.params.densities[out.celestial.type]
			event.radius = g.params.radii[out.celestial.type]
			event.velocity = vel
			event.show_orbit = true
			event.renderable = RenderableComponent{color}
			cost = f64(
				g.params.launch_costs[out.celestial.type] +
				g.params.k_energy_loss *
					(event.density * event.radius * event.radius * rl.Vector2LengthSqr(vel)),
			)
		}


		g.slingshot.can_launch = g.energy >= cost

		if (rl.IsMouseButtonReleased(.LEFT)) {
			g.slingshot.active = false
			if (g.slingshot.can_launch) {
				push_event(g, event)
				g.energy -= cost // TODO: should this be an event?
			}
		}
	}

	if (rl.IsKeyPressed(.C)) {
		g.slingshot.active = false
	}

	if (rl.IsKeyPressed(.D)) {
		g.draw_debug_panel = !g.draw_debug_panel
	}

	if rl.IsKeyPressed(.E) {
		g.slingshot.output = Game_SlingshotOutput_Emitter {
			emitter = {
				emit_celestial = {.DwarfPlanet},
				emit_density = g.params.densities[.DwarfPlanet],
				emit_radius = g.params.radii[.DwarfPlanet],
				base_cost = f64(g.params.launch_costs[.DwarfPlanet]),
				timer = Timer{interval = 2},
				destroy_timer = Timer{interval = 10},
			},
		}
	}

	if rl.IsKeyPressed(.P) {
		g.slingshot.output = Game_SlingshotOutput_Celestial {
			celestial = {.DwarfPlanet},
		}
	}

	if rl.IsKeyPressed(.T) {
		g.show_orbits = !g.show_orbits
	}

}
