package tests

import game "../game"
import "core:math"
import "core:testing"

@(test)
test_upgrade_cost_curve :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Level 0 cost = base
	c0 := game.upgrade_cost(g, .Gravity_Tuning)
	testing.expect_value(t, c0, 250.0)

	// Level 1 cost = base * growth^1
	g.upgrade_levels[.Gravity_Tuning] = 1
	c1 := game.upgrade_cost(g, .Gravity_Tuning)
	testing.expect_value(t, c1, 500.0)

	// Level 2 cost = base * growth^2
	g.upgrade_levels[.Gravity_Tuning] = 2
	c2 := game.upgrade_cost(g, .Gravity_Tuning)
	testing.expect_value(t, c2, 1000.0)
}

@(test)
test_upgrade_purchase_happy_path :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)
	g.score.energy = 1000.0

	ok := game.upgrade_purchase(g, .Gravity_Tuning)
	testing.expect(t, ok, "purchase should succeed")
	testing.expect_value(t, g.upgrade_levels[.Gravity_Tuning], u8(1))
	testing.expect_value(t, g.score.energy, 750.0)
}

@(test)
test_upgrade_purchase_rejected :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// 1. Insufficient energy
	g.score.energy = 10.0
	ok := game.upgrade_purchase(g, .Gravity_Tuning)
	testing.expect(t, !ok, "should fail due to insufficient energy")
	testing.expect_value(t, g.upgrade_levels[.Gravity_Tuning], u8(0))

	// 2. Requires unmet (Moonlet_Foundry requires Gravity_Tuning)
	g.score.energy = 5000.0
	ok = game.upgrade_purchase(g, .Moonlet_Foundry)
	testing.expect(t, !ok, "should fail due to unmet requirements")

	// 3. Condition unmet (Salvage_Rights requires lifetime_energy_earned >= 25000)
	g.upgrade_levels[.Orbital_Yield] = 1
	g.score.lifetime_energy_earned = 100.0
	ok = game.upgrade_purchase(g, .Salvage_Rights)
	testing.expect(t, !ok, "should fail due to unmet condition")

	// 4. At max_level
	g.upgrade_levels[.Gravity_Tuning] = 5
	ok = game.upgrade_purchase(g, .Gravity_Tuning)
	testing.expect(t, !ok, "should fail at max_level")

	// 5. Meta scope rejected in v1
	ok = game.upgrade_purchase(g, .Stellar_Legacy)
	testing.expect(t, !ok, "Meta scope upgrade purchase should fail in v1")
}

@(test)
test_upgrade_fold_and_derived_companions :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Initial physics params
	base_g := g.params.physics.gravity_constant
	base_yield := g.params.physics.energy_gain_factor
	base_reach := g.params.physics.cursor_distance

	// Apply upgrade levels
	g.upgrade_levels[.Gravity_Tuning] = 2
	g.upgrade_levels[.Orbital_Yield] = 1
	g.upgrade_levels[.Collector_Reach] = 2

	game.sys_modifier(g)

	expected_g := base_g * math.pow(f32(1.08), 2.0)
	expected_yield := base_yield * f32(1.12)
	expected_reach := base_reach + 8.0 * 2.0

	testing.expect(
		t,
		abs(g.effective_params.physics.gravity_constant - expected_g) < 0.001,
		"Gravity Tuning fold math",
	)
	testing.expect(
		t,
		abs(g.effective_params.physics.energy_gain_factor - expected_yield) < 0.001,
		"Orbital Yield fold math",
	)
	testing.expect(
		t,
		abs(g.effective_params.physics.cursor_distance - expected_reach) < 0.001,
		"Collector Reach fold math",
	)

	// Companion check
	expected_sq := expected_reach * expected_reach
	testing.expect(
		t,
		abs(g.effective_params.physics.cursor_distance_squared - expected_sq) < 0.01,
		"Derived companion cursor_distance_squared updated",
	)

	// Base isolation: g.params remains unchanged
	testing.expect_value(t, g.params.physics.gravity_constant, base_g)
}

@(test)
test_upgrade_table_target :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)
	base_launch_cost := g.params.celestials[.DwarfPlanet].launch_cost

	g.upgrade_levels[.Launch_Efficiency] = 2
	game.sys_modifier(g)

	expected_cost := base_launch_cost * math.pow(f32(0.92), 2.0)
	testing.expect(
		t,
		abs(g.effective_params.celestials[.DwarfPlanet].launch_cost - expected_cost) < 0.01,
		"Launch efficiency reduces celestial launch cost",
	)
}

@(test)
test_upgrade_capability_and_grant :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Capability derive
	testing.expect(
		t,
		!(.Fragment_Attraction in g.capabilities),
		"Capability absent before purchase",
	)

	g.upgrade_levels[.Tractor_Field] = 1
	game.sys_modifier(g)
	testing.expect(t, .Fragment_Attraction in g.capabilities, "Capability present after purchase")

	// Grant effect
	testing.expect(
		t,
		!(.Moonlet in g.slingshot.available_objects),
		"Moonlet absent before purchase",
	)
	g.score.energy = 5000.0
	g.upgrade_levels[.Gravity_Tuning] = 1
	ok := game.upgrade_purchase(g, .Moonlet_Foundry)
	testing.expect(t, ok, "Moonlet Foundry purchase succeeds")
	testing.expect(
		t,
		.Moonlet in g.slingshot.available_objects,
		"Moonlet granted to available_objects",
	)

	// Reset clears capability & reapplies grant
	game.upgrade_reset(g, .Run)
	game.sys_modifier(g)
	testing.expect(t, !(.Fragment_Attraction in g.capabilities), "Capability cleared on reset")
}

@(test)
test_upgrade_self_exclusion :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	base_research_cost := g.params.upgrades[.Research_Grants].base_cost
	base_gravity_cost := g.params.upgrades[.Gravity_Tuning].base_cost

	g.upgrade_levels[.Research_Grants] = 1
	game.sys_modifier(g)

	eff_research_cost := g.effective_params.upgrades[.Research_Grants].base_cost
	eff_gravity_cost := g.effective_params.upgrades[.Gravity_Tuning].base_cost

	testing.expect_value(t, eff_research_cost, base_research_cost) // self-exclusion: cost unchanged
	testing.expect(
		t,
		eff_gravity_cost < base_gravity_cost,
		"Research Grants discounts other node base_cost",
	)
}

@(test)
test_upgrade_states :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)
	game.sys_modifier(g)

	// Tier 1 root: Available
	testing.expect_value(t, g.upgrade_states[.Gravity_Tuning], game.Upgrade_State.Available)
	// Tier 2 (1-hop): Locked (prereq Gravity_Tuning available but level 0)
	testing.expect_value(t, g.upgrade_states[.Moonlet_Foundry], game.Upgrade_State.Silhouette)
	// Tier 3 (2-hop): Hidden
	testing.expect_value(t, g.upgrade_states[.Emitter_Persistence], game.Upgrade_State.Hidden)

	// Own Gravity_Tuning
	g.upgrade_levels[.Gravity_Tuning] = 1
	game.sys_modifier(g)

	testing.expect_value(t, g.upgrade_states[.Gravity_Tuning], game.Upgrade_State.Owned)
	testing.expect_value(t, g.upgrade_states[.Moonlet_Foundry], game.Upgrade_State.Available)
	testing.expect_value(t, g.upgrade_states[.Slingshot_Foresight], game.Upgrade_State.Available)

	// Max Gravity_Tuning
	g.upgrade_levels[.Gravity_Tuning] = 5
	game.sys_modifier(g)
	testing.expect_value(t, g.upgrade_states[.Gravity_Tuning], game.Upgrade_State.Maxed)
}

@(test)
test_upgrade_paused_guard :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Add temporary modifier
	game.modifier_add(g, .Gravity_Boost)
	initial_timer := g.modifiers[0].timer.curr

	g.status = .Paused
	g.upgrade_levels[.Gravity_Tuning] = 1

	// Run sys_modifier in Paused state
	g.dt = 0.5
	game.sys_modifier(g)

	// Modifier timer should NOT tick while Paused
	testing.expect_value(t, g.modifiers[0].timer.curr, initial_timer)

	// Upgrade fold SHOULD apply while Paused
	expected_g := g.params.physics.gravity_constant * 1.08 * 1.5 // Gravity_Tuning * Gravity_Boost
	testing.expect(
		t,
		abs(g.effective_params.physics.gravity_constant - expected_g) < 0.01,
		"Upgrade fold applies while Paused",
	)
}
