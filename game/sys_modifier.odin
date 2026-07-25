package game

sys_modifier :: proc(g: ^Game) {
	i: u64 = 0
	for i < g.modifiers_count {
		m := &g.modifiers[i]
		if !m.permanent {
			math_update_timer(&m.timer, g.dt)
			if m.timer.done {
				g.modifiers[i] = g.modifiers[g.modifiers_count - 1]
				g.modifiers_count -= 1
				continue
			}
		}
		i += 1
	}

	g.effective_params = g.params


	for kind in Modifier_Kind {
		#partial switch kind {
		case .Gravity_Boost:
			if _, active := modifier_find(g, .Gravity_Boost); active {
				g.effective_params.physics.gravity_constant *=
					g.params.modifiers[.Gravity_Boost].magnitude
			}
		case .Energy_Magnet:
			if _, active := modifier_find(g, .Energy_Magnet); active {
				g.effective_params.physics.energy_gain_factor *=
					g.params.modifiers[.Energy_Magnet].magnitude
			}
		}
	}
}
