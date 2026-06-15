package game
import "core:math"

sys_slingshot :: proc(g: ^Game) {
	if g.slingshot.status == .Inactive do return

	vel := physics_get_slingshot_release_velocity(g)

	cost: f64
	obj_type: ComponentType
	launch_type: CelestialType

	event := Game_Event_ObjectSpawn {
		pos = g.slingshot.start_pos,
	}

	switch out in g.slingshot.output {
	case Game_SlingshotOutput_Emitter:
		launch_type = out.emitter.emit_celestial.type
		obj_type = .Emitter
		event.radius = g.params.celestials[out.emitter.emit_celestial.type].radius
		event.emitter = out.emitter
		event.emitter.emit_vel = vel
		event.emitter.emit_density = g.params.celestials[out.emitter.emit_celestial.type].density
		event.emitter.emit_radius = g.params.celestials[out.emitter.emit_celestial.type].radius
		event.emitter.emit_color = get_celestial_color(g, out.emitter.emit_celestial.type)
		cost = f64(
			g.params.physics.energy_loss_coefficient *
			(event.density * event.radius * event.radius * vec2_length_sq(vel)),
		)

		g.slingshot.obj_radius = event.radius
		g.slingshot.obj_color = event.emitter.emit_color
	case Game_SlingshotOutput_Celestial:
		launch_type = out.celestial.type
		color := get_celestial_color(g, out.celestial.type)
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

		g.slingshot.obj_radius = event.radius
		g.slingshot.obj_color = color
	}

	g.slingshot.can_launch = g.score.energy >= cost

	if g.slingshot.status == .Released {
		g.slingshot.status = .Inactive

		if g.slingshot.can_launch {
			push_event(g, event)
			g.score.energy -= cost

			payload_mass := event.density * (event.radius * event.radius)
			g.camera.shake_intensity = clamp(math.sqrt(payload_mass) * 0.45, 0.0, 25.0)
			sys_lifecycle_spawn_shockwave(g, g.slingshot.start_pos, f64(payload_mass * 2.0))
		}
	}
}

