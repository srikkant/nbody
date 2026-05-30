package game

sys_score :: proc(g: ^Game) {
	if g.paused do return
	dt := g.dt

	curr_energy := g.energy

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]

		if g.timers[.Score].done && KE_SCORE_SIG <= e.sig {
			mass_score := e.mass
			vel_score := vec2_length_sq(e.velocity.current)
			pos_score :=
				1 / (g.params.physics.gravity_softening_factor + vec2_length_sq(e.pos.current))

			g.energy += f64(
				g.params.physics.energy_gain_coefficient *
				g.params.physics.energy_momentum_coefficient *
				mass_score *
				vel_score *
				pos_score,
			)
		}

		if ENERGY_SOURCE_SIG <= e.sig {
			gain := f64(
				g.params.physics.energy_gain_coefficient *
				(e.energy_source.output +
						(g.params.physics.energy_generation_coefficient * e.radius * e.radius)),
			)

			utils_math_update_timer(&e.energy_source.timer, dt)

			if e.energy_source.timer.done {
				g.energy += gain
			}
		}
	}

	if g.timers[.Score].done {
		g.energy_gains[g.energy_rate_ticker] = (g.energy - curr_energy)
		g.energy_rate_ticker = (g.energy_rate_ticker + 1) % AVG_CALC_TICKS
	}
}
