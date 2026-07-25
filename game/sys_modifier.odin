package game

sys_modifier :: proc(g: ^Game) {
	// 1. Tick + expire temp modifiers only when Playing
	if g.status == .Playing {
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
	}

	// 2. Base -> Effective struct copy
	g.effective_params = g.params

	// 3. Fold upgrade levels
	for id in Upgrade_Id {
		if id == .None do continue
		lvl := g.upgrade_levels[id]
		if lvl == 0 do continue

		p := &g.params.upgrades[id]

		#partial switch id {
		case .Gravity_Tuning:
			g.effective_params.physics.gravity_constant = math_apply_upgrade_op(
				g.effective_params.physics.gravity_constant,
				.Mul,
				p.magnitude,
				lvl,
			)
		case .Orbital_Yield:
			g.effective_params.physics.energy_gain_factor = math_apply_upgrade_op(
				g.effective_params.physics.energy_gain_factor,
				.Mul,
				p.magnitude,
				lvl,
			)
		case .Collector_Reach:
			g.effective_params.physics.cursor_distance = math_apply_upgrade_op(
				g.effective_params.physics.cursor_distance,
				.Add,
				p.magnitude,
				lvl,
			)
		case .Launch_Efficiency:
			for c in Celestial_Type {
				if c == .None do continue
				g.effective_params.celestials[c].launch_cost = math_apply_upgrade_op(
					g.effective_params.celestials[c].launch_cost,
					.Mul,
					p.magnitude,
					lvl,
				)
			}
		case .Slingshot_Foresight:
			g.effective_params.slingshot.preview_duration = math_apply_upgrade_op(
				g.effective_params.slingshot.preview_duration,
				.Add,
				p.magnitude,
				lvl,
			)
		case .Star_Furnace:
			g.effective_params.physics.energy_source_gain_factor = math_apply_upgrade_op(
				g.effective_params.physics.energy_source_gain_factor,
				.Mul,
				p.magnitude,
				lvl,
			)
		case .Salvage_Rights:
			g.effective_params.physics.energy_refund_factor = math_apply_upgrade_op(
				g.effective_params.physics.energy_refund_factor,
				.Add,
				p.magnitude,
				lvl,
			)
		case .Emitter_Logistics:
			for ep in Emitter_Preset {
				g.effective_params.emitter_presets[ep].cost_multiplier = f64(
					math_apply_upgrade_op(
						f32(g.effective_params.emitter_presets[ep].cost_multiplier),
						.Mul,
						p.magnitude,
						lvl,
					),
				)
			}
		case .Emitter_Persistence:
			for ep in Emitter_Preset {
				g.effective_params.emitter_presets[ep].duration = math_apply_upgrade_op(
					g.effective_params.emitter_presets[ep].duration,
					.Mul,
					p.magnitude,
					lvl,
				)
			}
		case .Research_Grants:
			// Invariant: Research_Grants must exclude itself
			for target_id in Upgrade_Id {
				if target_id == .None || target_id == .Research_Grants do continue
				g.effective_params.upgrades[target_id].base_cost = f64(
					math_apply_upgrade_op(
						f32(g.effective_params.upgrades[target_id].base_cost),
						.Mul,
						p.magnitude,
						lvl,
					),
				)
			}
		}
	}

	// 4. Fold temporary / permanent modifiers
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

	// 5. Recompute derived companions (single site)
	g.effective_params.physics.cursor_distance_squared =
		g.effective_params.physics.cursor_distance * g.effective_params.physics.cursor_distance
	g.effective_params.physics.world_radius_squared =
		g.effective_params.physics.world_radius * g.effective_params.physics.world_radius

	// 6. Derive capabilities
	g.capabilities = {}
	for id in Upgrade_Id {
		if id == .None do continue
		if g.upgrade_levels[id] > 0 {
			def := &UPGRADE_DEFS[id]
			if cap, ok := def.effect.(Upgrade_Effect_Capability); ok {
				g.capabilities += {cap.capability}
			}
		}
	}

	// 7. Derive upgrade node states
	sys_modifier_derive_states(g)
}

sys_modifier_derive_node_hop :: proc(g: ^Game, id: Upgrade_Id) -> int {
	def := &UPGRADE_DEFS[id]
	has_requires := false
	for req in def.requires {
		if req != .None {
			has_requires = true
			if g.upgrade_levels[req] > 0 {
				return 1
			}
		}
	}
	if !has_requires {
		return 1
	}
	for req in def.requires {
		if req != .None {
			if sys_modifier_derive_node_hop(g, req) == 1 {
				return 2
			}
		}
	}
	return 3
}

sys_modifier_derive_states :: proc(g: ^Game) {
	for id in Upgrade_Id {
		if id == .None {
			g.upgrade_states[id] = .Hidden
			continue
		}
		def := &UPGRADE_DEFS[id]
		if def.scope == .Meta {
			g.upgrade_states[id] = .Hidden
			continue
		}

		p := &g.effective_params.upgrades[id]
		lvl := g.upgrade_levels[id]

		if lvl >= p.max_level {
			g.upgrade_states[id] = .Maxed
		} else if lvl > 0 {
			g.upgrade_states[id] = .Owned
		} else if upgrade_requires_met(g, id) && upgrade_condition_met(g, id) {
			g.upgrade_states[id] = .Available
		} else {
			hop := sys_modifier_derive_node_hop(g, id)
			if hop == 1 {
				g.upgrade_states[id] = .Locked
			} else if hop == 2 {
				g.upgrade_states[id] = .Silhouette
			} else {
				g.upgrade_states[id] = .Hidden
			}
		}
	}
}
