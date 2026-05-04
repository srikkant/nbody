package main

import "core:math"
import rl "vendor:raylib"

sys_score :: proc(g: ^Game) {
	// Compute score based on velocity of each entity
	for i in 0 ..< g.entities_count {
		entity := &g.entities[i]
		// Only compute score for celestial bodies minus stars
		if !(SCORE_SIG <= entity.sig) || (STAR_SIG <= entity.sig) do continue

		mass_score := entity.size.mass / 10
		vel_score := rl.Vector2LengthSqr(entity.vel) / 100
		pos_score := 1 / (rl.Vector2LengthSqr(entity.pos) * 100)

		time_score := (g.elapsed - entity.life.created_at) * 10

		g.energy += f64(0.5 * mass_score * vel_score * pos_score * time_score)
	}


	// Record energy over time
	g.energy_over_time[int(math.floor(g.elapsed))] = g.energy
}
