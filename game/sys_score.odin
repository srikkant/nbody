package game

Score :: struct {
	energy:                 f64,
	lifetime_energy_earned: f64,
	energy_rate_ticker:     int,
	total_objects:          int,
	energy_gains:           [AVG_CALC_TICKS]f64,
	energy_losses:          [AVG_CALC_TICKS]f64,
}

sys_score_init :: proc(g: ^Game) {
	g.score.energy = 10000000 // TODO: added for debugging.
	g.score.total_objects = 0
	g.score.energy_rate_ticker = 0

	for i in 0 ..< AVG_CALC_TICKS {
		g.score.energy_gains[i] = 0
		g.score.energy_losses[i] = 0
	}
}

sys_score :: proc(g: ^Game) {
	dt := g.dt
	curr_energy := g.score.energy

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]

		if g.timers[.Score].done && KE_SCORE_SIG <= e.sig {
			mass_score := e.mass
			vel_score := math_vec2_length_sq(e.velocity.current)
			pos_score := 1 / (1 + math_vec2_length_sq(e.pos.current)) // prevent division by zero

			economy_add_energy(
				g,
				f64(
					g.effective_params.physics.energy_gain_factor *
					mass_score *
					vel_score *
					pos_score,
				),
			)
		}

		if ENERGY_SOURCE_SIG <= e.sig {
			math_update_timer(&e.energy_source.timer, dt)
			if e.energy_source.timer.done {
				economy_add_energy(
					g,
					f64(
						g.effective_params.physics.energy_source_gain_factor *
						(e.energy_source.output + (e.radius * e.radius)),
					),
				)
			}
		}
	}

	if g.timers[.Score].done {
		g.score.energy_gains[g.score.energy_rate_ticker] = (g.score.energy - curr_energy)
		g.score.energy_rate_ticker = (g.score.energy_rate_ticker + 1) % AVG_CALC_TICKS
	}
}
