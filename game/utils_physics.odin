package game

import "core:math"
import rl "vendor:raylib"

physics_get_gravitational_acceleration :: proc(
	g: ^Game,
	target_pos: rl.Vector2,
	target_radius: f32,
	source_pos: rl.Vector2,
	source_mass: f32,
	source_radius: f32,
) -> (
	rl.Vector2,
	f32,
) {
	diff := source_pos - target_pos
	r2 := diff.x * diff.x + diff.y * diff.y
	r3 :=
		(r2 + g.params.physics.gravity_softening_factor) *
		math.sqrt(r2 + g.params.physics.gravity_softening_factor)

	strength := g.params.physics.gravity_constant * source_mass
	accel := rl.Vector2{(strength * diff.x) / r3, (strength * diff.y) / r3}

	return accel, r2
}


physics_get_slingshot_release_velocity :: proc(g: ^Game, release_pos: rl.Vector2) -> rl.Vector2 {
	return (g.slingshot.start_pos - release_pos) * g.params.physics.slingshot_launch_power
}

physics_radius_from_mass_density :: proc(mass: f32, density: f32) -> f32 {
	if density <= 0 do return 0
	return math.sqrt(mass / density)
}

physics_get_total_acceleration_at_pos :: proc(
	g: ^Game,
	target_pos: rl.Vector2,
	target_radius: f32,
) -> rl.Vector2 {
	total_accel := rl.Vector2(0)
	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if !(PHYSICS_SIG <= e.sig) do continue
		if e.mass <= 0.0 do continue

		acc, _ := physics_get_gravitational_acceleration(
			g,
			target_pos,
			target_radius,
			e.pos.current,
			e.mass,
			e.radius,
		)
		total_accel += acc
	}
	return total_accel
}

physics_rk4_step :: proc(g: ^Game, pos: ^rl.Vector2, vel: ^rl.Vector2, dt: f32, radius: f32) {
	// k1
	k1_pos := vel^
	k1_vel := physics_get_total_acceleration_at_pos(g, pos^, radius)

	// k2
	p2 := pos^ + k1_pos * (dt * 0.5)
	v2 := vel^ + k1_vel * (dt * 0.5)
	k2_pos := v2
	k2_vel := physics_get_total_acceleration_at_pos(g, p2, radius)

	// k3
	p3 := pos^ + k2_pos * (dt * 0.5)
	v3 := vel^ + k2_vel * (dt * 0.5)
	k3_pos := v3
	k3_vel := physics_get_total_acceleration_at_pos(g, p3, radius)

	// k4
	p4 := pos^ + k3_pos * dt
	v4 := vel^ + k3_vel * dt
	k4_pos := v4
	k4_vel := physics_get_total_acceleration_at_pos(g, p4, radius)

	// Update state
	pos^ += (k1_pos + k2_pos * 2.0 + k3_pos * 2.0 + k4_pos) * (dt / 6.0)
	vel^ += (k1_vel + k2_vel * 2.0 + k3_vel * 2.0 + k4_vel) * (dt / 6.0)
}

