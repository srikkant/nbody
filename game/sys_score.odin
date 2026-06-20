package game

Score :: struct {
	energy:             f64,
	energy_rate_ticker: int,
	total_objects:      int,
	energy_gains:       [AVG_CALC_TICKS]f64,
	energy_losses:      [AVG_CALC_TICKS]f64,
}

sys_score :: proc(g: ^Game) {
	dt := g.dt
	curr_energy := g.score.energy
	gain_fac := g.params.economy.energy_gain_factor

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]

		if g.timers[.Score].done && KE_SCORE_SIG <= e.sig {
			mass_score := e.mass
			vel_score := vec2_length_sq(e.velocity.current)
			pos_score :=
				1 / (g.params.physics.gravity_softening_factor + vec2_length_sq(e.pos.current))

			g.score.energy += f64(gain_fac * mass_score * vel_score * pos_score)
		}

		if ENERGY_SOURCE_SIG <= e.sig {
			utils_math_update_timer(&e.energy_source.timer, dt)
			if e.energy_source.timer.done {
				g.score.energy += f64(gain_fac * (e.energy_source.output + (e.radius * e.radius)))
			}
		}
	}

	if g.timers[.Score].done {
		g.score.energy_gains[g.score.energy_rate_ticker] = (g.score.energy - curr_energy)
		g.score.energy_rate_ticker = (g.score.energy_rate_ticker + 1) % AVG_CALC_TICKS
	}
}

