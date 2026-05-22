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
		launch_type: CelestialType
		switch out in g.slingshot.output {
		case Game_SlingshotOutput_Emitter:
			launch_type = out.emitter.emit_celestial.type
		case Game_SlingshotOutput_Celestial:
			launch_type = out.celestial.type
		}
		color := get_celestial_color(g, launch_type)

		switch out in g.slingshot.output {
		case Game_SlingshotOutput_Emitter:
			obj_type = .Emitter
			event.radius = g.params.celestials[out.emitter.emit_celestial.type].radius
			event.emitter = out.emitter
			event.emitter.emit_vel = vel
			event.emitter.emit_density =
				g.params.celestials[out.emitter.emit_celestial.type].density
			event.emitter.emit_radius = g.params.celestials[out.emitter.emit_celestial.type].radius
			event.emitter.emit_color = color
			cost = f64(
				g.params.physics.energy_loss_coefficient *
				(event.density * event.radius * event.radius * rl.Vector2LengthSqr(vel)),
			)
		case Game_SlingshotOutput_Celestial:
			event.celestial = out.celestial
			event.density = g.params.celestials[out.celestial.type].density
			event.radius = g.params.celestials[out.celestial.type].radius
			event.velocity = vel
			event.show_orbit = true
			event.renderable = RenderableComponent{color}
			cost = f64(
				g.params.celestials[out.celestial.type].launch_cost +
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
				emit_density = g.params.celestials[.DwarfPlanet].density,
				emit_radius = g.params.celestials[.DwarfPlanet].radius,
				base_cost = f64(g.params.celestials[.DwarfPlanet].launch_cost),
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
