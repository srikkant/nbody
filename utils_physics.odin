package main

import "core:math"
import rl "vendor:raylib"

physics_get_graviational_acceleration :: proc(
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
	r3 := (r2 + SOFTENING) * math.sqrt(r2 + SOFTENING)

	strength := g.params.g * source_mass
	accel := rl.Vector2{(strength * diff.x) / r3, (strength * diff.y) / r3}

	return accel, r2
}


physics_get_slingshot_release_velocity :: proc(g: ^Game, release_pos: rl.Vector2) -> rl.Vector2 {
	return (g.slingshot.start_pos - release_pos) * g.params.slingshot_power
}

frame_time :: proc() -> f32 {
	return math.min(rl.GetFrameTime(), MAX_DT)
}
