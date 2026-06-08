package game
import "core:math"

sys_input :: proc(g: ^Game) {
	dt := g.dt

	g.mouse_pos = input_mouse_pos(g)

	for i in Game_TimerType {
		utils_math_update_timer(&g.timers[i], dt)
	}

	if rl_is_mouse_button_pressed(g, .LEFT) {
		g.slingshot.active = true
		g.slingshot.start_pos = input_mouse_pos(g)
	}

	if rl_is_mouse_button_released(g, .RIGHT) || rl_is_key_pressed(g, .C) {
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
				(event.density * event.radius * event.radius * vec2_length_sq(vel)),
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
					(event.density * event.radius * event.radius * vec2_length_sq(vel)),
			)
		}

		g.slingshot.can_launch = g.score.energy >= cost

		if rl_is_mouse_button_released(g, .LEFT) {
			g.slingshot.active = false
			if g.slingshot.can_launch {
				push_event(g, event)
				g.score.energy -= cost

				payload_mass := event.density * (event.radius * event.radius)
				g.camera.shake_intensity = clamp(math.sqrt(payload_mass) * 0.45, 0.0, 25.0)

				sys_lifecycle_spawn_shockwave(g, g.slingshot.start_pos, f64(payload_mass * 2.0))

				// Trigger chromatic ring flash in an available slot
				for i in 0 ..< len(g.slingshot.ring_flashes) {
					flash := &g.slingshot.ring_flashes[i]
					if !flash.active {
						flash.active = true
						flash.pos = g.slingshot.start_pos
						flash.radius = event.radius
						flash.max_radius = event.radius * 7.0
						flash.color = color
						flash.life = 1.0
						break
					}
				}

				// Trigger slingshot snap animation
				g.slingshot.snap.active = true
				g.slingshot.snap.start_pos = g.slingshot.start_pos
				g.slingshot.snap.end_pos = end
				g.slingshot.snap.timer = 1.0
				g.slingshot.snap.color = color
			}
		}
	}

	if rl_is_key_pressed(g, .ESCAPE) && g.status == .Paused {
		g.status = .Playing
	}

	if rl_is_key_pressed(g, .ESCAPE) && g.status == .Playing {
		g.status = .Paused
	}

	if rl_is_key_pressed(g, .T) {
		g.render.show_orbits = !g.render.show_orbits
	}
}

