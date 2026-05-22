package main
import rl "vendor:raylib"

input_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	return rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera)
}

sys_input :: proc(g: ^Game) {
	dt := frame_time(g)

	g.elapsed += dt
	g.mouse_pos = input_mouse_pos(g)

	// Update all timers in the input system
	for i in Game_TimerType {
		utils_math_update_timer(&g.timers[i], dt)
	}

	if (rl.IsMouseButtonPressed(.LEFT)) {
		g.slingshot.active = true
		g.slingshot.start_pos = input_mouse_pos(g)
	}

	if (rl.IsMouseButtonReleased(.RIGHT) || rl.IsKeyPressed(.C)) {
		g.slingshot.active = false
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
			event.radius = g.params.physics.radii[out.emitter.emit_celestial.type]
			event.emitter = out.emitter
			event.emitter.emit_vel = vel
			event.emitter.emit_density =
				g.params.physics.densities[out.emitter.emit_celestial.type]
			event.emitter.emit_radius = g.params.physics.radii[out.emitter.emit_celestial.type]
			event.emitter.emit_color = color
			cost = f64(
				g.params.physics.energy_loss_coefficient *
				(event.density * event.radius * event.radius * rl.Vector2LengthSqr(vel)),
			)
		case Game_SlingshotOutput_Celestial:
			event.celestial = out.celestial
			event.density = g.params.physics.densities[out.celestial.type]
			event.radius = g.params.physics.radii[out.celestial.type]
			event.velocity = vel
			event.show_orbit = true
			event.renderable = RenderableComponent{color}
			cost = f64(
				g.params.physics.launch_costs[out.celestial.type] +
				g.params.physics.energy_loss_coefficient *
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

	if (rl.IsKeyPressed(.D)) {
		g.draw_debug_panel = !g.draw_debug_panel
	}

	if rl.IsKeyPressed(.E) {
		g.slingshot.output = Game_SlingshotOutput_Emitter {
			emitter = {
				emit_celestial = {.DwarfPlanet},
				emit_density = g.params.physics.densities[.DwarfPlanet],
				emit_radius = g.params.physics.radii[.DwarfPlanet],
				base_cost = f64(g.params.physics.launch_costs[.DwarfPlanet]),
				timer = Timer{interval = 2},
				destroy_timer = Timer{interval = 10},
			},
		}
	}

	if rl.IsKeyPressed(.M) {
		g.render.show_upgrade_menu = !g.render.show_upgrade_menu
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
