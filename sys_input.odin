package main
import "core:math"
import rl "vendor:raylib"

input_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	return rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera)
}

sys_input :: proc(g: ^Game) {
	dt := frame_time(g)

	g.mouse_pos = input_mouse_pos(g)

	if !g.paused {
		g.elapsed += dt
		for i in Game_TimerType {
			utils_math_update_timer(&g.timers[i], dt)
		}
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

		if rl_is_mouse_button_released(g, .LEFT) {
			g.slingshot.active = false
			if g.slingshot.can_launch {
				push_event(g, event)
				g.energy -= cost // TODO: should this be an event?

				// Trigger camera shake proportional to payload mass
				payload_mass := event.density * (event.radius * event.radius)
				g.camera_shake_intensity = clamp(math.sqrt(payload_mass) * 0.45, 0.0, 25.0)

				// Trigger physical engine shockwave entity at the release/spawn coordinates
				sys_lifecycle_spawn_shockwave(g, g.slingshot.start_pos, f64(payload_mass * 2.0))

				// Trigger chromatic ring flash in an available slot
				for i in 0 ..< len(g.ring_flashes) {
					flash := &g.ring_flashes[i]
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
				g.slingshot_snap.active = true
				g.slingshot_snap.start_pos = g.slingshot.start_pos
				g.slingshot_snap.end_pos = end
				g.slingshot_snap.timer = 1.0
				g.slingshot_snap.color = color
			}
		}
	}

	if rl_is_key_pressed(g, .T) {
		g.show_orbits = !g.show_orbits
	}
}
