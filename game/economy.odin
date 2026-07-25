package game

economy_add_energy :: proc(g: ^Game, amount: f64) {
	if amount <= 0 do return
	g.score.energy += amount
	g.score.lifetime_energy_earned += amount
}

economy_try_spend :: proc(g: ^Game, amount: f64) -> bool {
	if amount <= 0 do return true
	if g.score.energy < amount do return false
	g.score.energy -= amount
	return true
}
