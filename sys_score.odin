package main

import "core:math"
import rl "vendor:raylib"

sys_score :: proc(g: ^Game) {
	dt := rl.GetFrameTime()
	score_ticker := utils_math_update_timer(&g.score_timer, dt)

	static_gain := 0.0
	dynamic_gain := 0.0

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]

		if (score_ticker && KE_SCORE_SIG <= e.sig) {
			mass_score := e.size.mass
			vel_score := rl.Vector2LengthSqr(e.vel)
			pos_score := 1 / (SOFTENING + rl.Vector2LengthSqr(e.pos.current))

			dynamic_gain += f64(mass_score * vel_score * pos_score)
		}

		if (ENERGY_SOURCE_SIG <= e.sig) {
			gain := f64(
				e.energy_source.output +
				(g.params.energy_mass_factor * e.size.mass * e.size.radius),
			)

			static_gain += gain
			if (utils_math_update_timer(&e.energy_source.timer, dt)) {
				g.energy += gain
			}
		}

	}

	if (score_ticker) {
		g.energy += dynamic_gain
		g.energy_gain_rate = static_gain + dynamic_gain
		g.energy_over_time[int(math.floor(g.elapsed))] = g.energy
	}
}
