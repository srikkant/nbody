package main

import "core:math"
import rl "vendor:raylib"

physics_get_graviational_acceleration :: proc(
	target_pos: rl.Vector2,
	target_radius: f32,
	source_pos: rl.Vector2,
	source_mass: f32,
	source_radius: f32,
) -> (
	rl.Vector2,
	bool,
) {
	diff := source_pos - target_pos
	r2 := diff.x * diff.x + diff.y * diff.y
	r3 := (r2 + SOFTENING) * math.sqrt(r2 + SOFTENING)

	strength := G * source_mass
	accel := rl.Vector2{(strength * diff.x) / r3, (strength * diff.y) / r3}

	// Just an sum of the two radii for approximate collision radius
	collision_radius := (target_radius + source_radius)
	collision := r2 < collision_radius * collision_radius

	return accel, collision
}


physics_get_slingshot_release_velocity :: proc(
	start_pos: rl.Vector2,
	end_pos: rl.Vector2,
) -> rl.Vector2 {
	return (start_pos - end_pos) * SLINGSHOT_STIFFNESS
}
