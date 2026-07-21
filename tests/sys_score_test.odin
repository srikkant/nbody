package tests

import game "../game"
import "core:testing"

@(test)
test_sys_score_kinetic_gain_on_tick :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .DwarfPlanet, {100, 0}, {0, 10})
	g.timers[.Score].done = true

	game.sys_score(g)

	// gain = gain_factor(1) * mass(4) * vel²(100) / (1 + dist²(10000))
	expect_f64_approx(t, g.score.energy, 400.0 / 10001.0, eps = 1e-6)
	expect_f64_approx(t, g.score.energy_gains[0], 400.0 / 10001.0, eps = 1e-6)
	testing.expect(t, g.score.energy_rate_ticker == 1, "ticker advances")
}

@(test)
test_sys_score_no_gain_without_tick :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .DwarfPlanet, {100, 0}, {0, 10})

	game.sys_score(g)

	expect_f64_approx(t, g.score.energy, 0)
}

@(test)
test_sys_score_energy_source_emission :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	star := test_add_celestial(g, .Star, {0, 0})
	game.entity_add_energy_source(g, star, {output = 10, timer = {interval = 0.01}})

	g.dt = 0.02
	game.sys_score(g)

	// gain = source_gain_factor(1) * (output(10) + radius²(100))
	expect_f64_approx(t, g.score.energy, 110)
}
