package main

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

frame_time :: proc(g: ^Game) -> f32 {
	return math.min(rl.GetFrameTime(), g.params.physics.max_delta_time_sec)
}
