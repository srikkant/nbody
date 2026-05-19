package main

import rl "vendor:raylib"

sys_score :: proc(g: ^Game) {
	dt := frame_time()

	curr_energy := g.energy

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]

		if g.timers[.Score].done && KE_SCORE_SIG <= e.sig {
			mass_score := e.mass
			vel_score := rl.Vector2LengthSqr(e.velocity.current)
			pos_score := 1 / (SOFTENING + rl.Vector2LengthSqr(e.pos.current))

			g.energy += f64(
				g.params.k_energy_gain *
				g.params.k_energy_momentum *
				mass_score *
				vel_score *
				pos_score,
			)
		}

		if ENERGY_SOURCE_SIG <= e.sig {
			gain := f64(
				g.params.k_energy_gain *
				(e.energy_source.output + (g.params.k_energy_source * e.radius * e.radius)),
			)

			utils_math_update_timer(&e.energy_source.timer, dt)

			if e.energy_source.timer.done {
				g.energy += gain
			}
		}
	}

	if g.timers[.Score].done {
		g.energy_gains[g.energy_rate_ticker] = (g.energy - curr_energy)
		g.energy_rate_ticker = (g.energy_rate_ticker + 1) % RATE_CALC_TICKS
	}
}
