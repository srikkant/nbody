package tests

import game "../game"
import "core:testing"

@(test)
test_modifier_add_new_kind :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	ok := game.modifier_add(g, .Gravity_Boost)
	testing.expect(t, ok, "should add Gravity_Boost")
	testing.expect(t, g.modifiers_count == 1, "modifiers_count should be 1")
	testing.expect(t, g.modifiers[0].kind == .Gravity_Boost, "kind should be Gravity_Boost")
	testing.expect(t, !g.modifiers[0].permanent, "Gravity_Boost should be temp")
	testing.expect(t, g.modifiers[0].timer.interval == 30.0, "duration should be 30s")
}

@(test)
test_modifier_add_refresh_temp :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	game.modifier_add(g, .Gravity_Boost)
	g.modifiers[0].timer.curr = 15.0

	ok := game.modifier_add(g, .Gravity_Boost)
	testing.expect(t, ok, "re-add temp should succeed")
	testing.expect(t, g.modifiers_count == 1, "modifiers_count should remain 1")
	testing.expect(t, g.modifiers[0].timer.curr == 0.0, "timer curr should reset to 0")
}

@(test)
test_modifier_add_reject_permanent :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	ok1 := game.modifier_add(g, .Energy_Magnet)
	testing.expect(t, ok1, "should add Energy_Magnet")
	testing.expect(t, g.modifiers[0].permanent, "Energy_Magnet should be permanent")

	ok2 := game.modifier_add(g, .Energy_Magnet)
	testing.expect(t, !ok2, "re-add permanent should be rejected")
	testing.expect(t, g.modifiers_count == 1, "modifiers_count should remain 1")
}

@(test)
test_modifier_add_capacity_full :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	for i in 0 ..< game.MAX_MODIFIERS {
		g.modifiers[i] = game.Modifier {
			kind      = .Gravity_Boost,
			permanent = false,
			timer     = game.math_make_timer(30),
		}
	}
	g.modifiers_count = game.MAX_MODIFIERS

	ok := game.modifier_add(g, .Energy_Magnet)
	testing.expect(t, !ok, "add beyond MAX_MODIFIERS should be rejected")
}

@(test)
test_modifier_temp_expiry :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	game.modifier_add(g, .Gravity_Boost)
	g.modifiers[0].timer.curr = 29.99

	g.dt = 0.02
	game.sys_modifier(g)

	testing.expect(t, g.modifiers_count == 0, "expired temp modifier should be removed")
}

@(test)
test_modifier_fold_effective_params :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	base_grav := g.params.physics.gravity_constant
	base_energy := g.params.physics.energy_gain_factor

	game.modifier_add(g, .Gravity_Boost)
	game.modifier_add(g, .Energy_Magnet)

	game.sys_modifier(g)

	expected_grav := base_grav * 1.5
	expected_energy := base_energy * 1.25

	testing.expectf(
		t,
		g.effective_params.physics.gravity_constant == expected_grav,
		"effective gravity expected %v got %v",
		expected_grav,
		g.effective_params.physics.gravity_constant,
	)
	testing.expectf(
		t,
		g.effective_params.physics.energy_gain_factor == expected_energy,
		"effective energy gain factor expected %v got %v",
		expected_energy,
		g.effective_params.physics.energy_gain_factor,
	)
}

@(test)
test_modifier_base_params_isolation :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	base_grav := g.params.physics.gravity_constant

	game.modifier_add(g, .Gravity_Boost)
	game.sys_modifier(g)

	testing.expect(
		t,
		g.params.physics.gravity_constant == base_grav,
		"base params must remain unchanged after sys_modifier",
	)
}

@(test)
test_modifier_post_expiry_revert :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	base_grav := g.params.physics.gravity_constant

	game.modifier_add(g, .Gravity_Boost)
	g.modifiers[0].timer.curr = 29.99
	g.dt = 0.05
	game.sys_modifier(g)

	testing.expect(t, g.modifiers_count == 0, "modifier should expire")
	testing.expect(
		t,
		g.effective_params.physics.gravity_constant == base_grav,
		"effective params should revert to base after expiry",
	)
}
