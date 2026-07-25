package game

import "core:log"

upgrade_cost :: proc(g: ^Game, id: Upgrade_Id) -> f64 {
	if id == .None do return 0.0
	p := &g.effective_params.upgrades[id]
	level := g.upgrade_levels[id]
	return math_geometric_cost(p.base_cost, p.cost_growth, level)
}

upgrade_effect_value :: proc(g: ^Game, id: Upgrade_Id, level: u8) -> f32 {
	if id == .None do return 0.0
	p := &g.effective_params.upgrades[id]
	def := &UPGRADE_DEFS[id]
	#partial switch e in def.effect {
	case Upgrade_Effect_Param:
		return math_apply_upgrade_op(1.0, e.op, p.magnitude, level)
	case Upgrade_Effect_Capability:
		return level > 0 ? 1.0 : 0.0
	case Upgrade_Effect_Grant:
		return level > 0 ? 1.0 : 0.0
	}
	return 0.0
}

upgrade_requires_met :: proc(g: ^Game, id: Upgrade_Id) -> bool {
	if id == .None do return false
	def := &UPGRADE_DEFS[id]
	for req in def.requires {
		if req != .None && g.upgrade_levels[req] == 0 {
			return false
		}
	}
	return true
}

upgrade_condition_met :: proc(g: ^Game, id: Upgrade_Id) -> bool {
	if id == .None do return false
	def := &UPGRADE_DEFS[id]
	p := &g.effective_params.upgrades[id]

	switch def.condition.kind {
	case .None:
		return true
	case .Lifetime_Energy_Earned:
		return g.score.lifetime_energy_earned >= p.condition_threshold
	case .Celestial_Discovered:
		return def.condition.celestial in g.slingshot.available_objects
	case .Upgrades_Purchased:
		return f64(upgrade_purchased_count(g)) >= p.condition_threshold
	}
	return true
}

upgrade_can_afford :: proc(g: ^Game, id: Upgrade_Id) -> bool {
	if id == .None do return false
	return g.score.energy >= upgrade_cost(g, id)
}

upgrade_can_purchase :: proc(g: ^Game, id: Upgrade_Id) -> bool {
	if id == .None do return false
	def := &UPGRADE_DEFS[id]
	p := &g.effective_params.upgrades[id]

	if def.scope != .Run do return false
	if g.upgrade_levels[id] >= p.max_level do return false
	if !upgrade_requires_met(g, id) do return false
	if !upgrade_condition_met(g, id) do return false
	if !upgrade_can_afford(g, id) do return false

	return true
}

upgrade_purchase :: proc(g: ^Game, id: Upgrade_Id) -> bool {
	if !upgrade_can_purchase(g, id) {
		log.warn("Cannot purchase upgrade:", id)
		return false
	}

	cost := upgrade_cost(g, id)
	if !economy_try_spend(g, cost) {
		log.warn("Failed energy spend for upgrade purchase:", id)
		return false
	}

	g.upgrade_levels[id] += 1

	def := &UPGRADE_DEFS[id]
	if grant, ok := def.effect.(Upgrade_Effect_Grant); ok {
		g.slingshot.available_objects += {grant.celestial}
	}

	return true
}

upgrade_purchased_count :: proc(g: ^Game) -> int {
	count := 0
	for id in Upgrade_Id {
		if id != .None && g.upgrade_levels[id] > 0 {
			count += 1
		}
	}
	return count
}

upgrade_reset :: proc(g: ^Game, scope: Upgrade_Scope, all: bool = false) {
	for id in Upgrade_Id {
		if id == .None do continue
		if all || UPGRADE_DEFS[id].scope == scope {
			g.upgrade_levels[id] = 0
		}
	}
	upgrade_reapply_grants(g)
}

upgrade_reapply_grants :: proc(g: ^Game) {
	for id in Upgrade_Id {
		if id == .None do continue
		if g.upgrade_levels[id] > 0 {
			def := &UPGRADE_DEFS[id]
			if grant, ok := def.effect.(Upgrade_Effect_Grant); ok {
				g.slingshot.available_objects += {grant.celestial}
			}
		}
	}
}
