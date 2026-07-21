package game

import "core:math"
import rl "vendor:raylib"

/*
 * Simulates the slingshot's launch trajectory and stores the result in the
 * slingshot's preview buffers. Pure computation; rendering reads the buffers.
 */
sys_slingshot_compute_preview :: proc(g: ^Game) {
	g.slingshot.preview_count = 0

	star := &g.entities[Entity_Id(0)]

	// No preview if the user cannot launch or has no preview level, to avoid confusion
	if g.slingshot.preview == 0 || !g.slingshot.can_launch do return

	pos := g.slingshot.start_pos
	vel := physics_get_slingshot_release_velocity(g)

	g.slingshot.preview_points[0] = pos
	g.slingshot.preview_times[0] = 0.0
	g.slingshot.preview_count = 1

	base_dt: f32 = (1.0 / 30.0)
	accumulated_t: f32 = 0.0

	for idx in 1 ..< 600 {
		if accumulated_t >= g.params.slingshot.preview_duration do break

		dist := rl.Vector2Distance(pos, star.pos.current)
		scale := clamp(dist / f32(380.0), f32(0.12), f32(3.5))
		step_dt := base_dt * scale * f32(2.8)

		// Check collision with any celestial
		// TODO(perf): Potential for improvement here.
		// Right now, this iterates through all entities 600 times essentially.
		entity := physics_check_collision(g, pos, g.slingshot.obj_radius, PHYSICS_SIG)
		if entity != nil {
			break
		}

		physics_rk4_step(g, &pos, &vel, step_dt, g.slingshot.obj_radius)
		accumulated_t += step_dt

		g.slingshot.preview_points[idx] = pos
		g.slingshot.preview_times[idx] = accumulated_t
		g.slingshot.preview_count = idx + 1
	}
}

sys_slingshot :: proc(g: ^Game) {
	if g.slingshot.status == .Inactive do return

	vel := physics_get_slingshot_release_velocity(g)

	cost: f64
	obj_type: Component_Type
	launch_type: Celestial_Type

	event := GameEvent_ObjectSpawn {
		pos = g.slingshot.start_pos,
	}

	switch out in g.slingshot.output {
	case Slingshot_Output_Emitter:
		launch_type = out.emitter.emit_celestial.type
		obj_type = .Emitter
		event.radius = g.params.celestials[out.emitter.emit_celestial.type].radius
		event.emitter = out.emitter
		event.emitter.emit_vel = vel
		event.emitter.emit_density = g.params.celestials[out.emitter.emit_celestial.type].density
		event.emitter.emit_radius = g.params.celestials[out.emitter.emit_celestial.type].radius
		event.emitter.emit_color = get_celestial_color(g, out.emitter.emit_celestial.type)
		cost = f64(event.density * event.radius * event.radius * math_vec2_length_sq(vel))

		g.slingshot.obj_radius = event.radius
		g.slingshot.obj_color = event.emitter.emit_color
	case Slingshot_Output_Celestial:
		launch_type = out.celestial.type
		color := get_celestial_color(g, out.celestial.type)
		event.celestial = out.celestial
		event.density = g.params.celestials[out.celestial.type].density
		event.radius = g.params.celestials[out.celestial.type].radius
		event.velocity = vel
		event.show_orbit = true
		event.renderable = Component_Renderable{color}
		cost = f64(
			g.params.celestials[out.celestial.type].launch_cost +
			(event.density * event.radius * event.radius * math_vec2_length_sq(vel)),
		)

		g.slingshot.obj_radius = event.radius
		g.slingshot.obj_color = color
	}

	g.slingshot.can_launch = g.score.energy >= cost

	if g.slingshot.status == .Released {
		g.slingshot.status = .Inactive

		if g.slingshot.can_launch {
			g.help.launch_done = true

			push_event(g, event)
			g.score.energy -= cost

			payload_mass := event.density * (event.radius * event.radius)
			g.camera.shake_intensity = clamp(math.sqrt(payload_mass) * 0.45, 0.0, 25.0)
			sys_lifecycle_spawn_shockwave(
				g,
				g.slingshot.start_pos,
				f64(payload_mass * 2.0),
				g.params.celestials[event.celestial.type].color,
			)
		}
	}

	if g.slingshot.status == .Active {
		sys_slingshot_compute_preview(g)
	}
}
