package tests

import game "../game"
import "core:math"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_ke_score_formula :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.paused = false
	g.dt = 0.016
	g.energy = 0.0

	g.timers[.Score] = {
		curr     = 0,
		interval = 1.0,
		done     = true,
	}

	g.params.physics.gravity_softening_factor = 4.0
	g.params.physics.energy_gain_coefficient = 2.0
	g.params.physics.energy_momentum_coefficient = 1.5

	id := add_test_entity(g, .Asteroid, 10.0, {3.0, 4.0}, {2.0, 0.0})

	testing.expect(t, game.KE_SCORE_SIG <= g.entities[id].sig, "Must match KE_SCORE_SIG")

	game.sys_score(g)

	expected := f64(2.0 * 1.5 * 10.0 * 4.0 * (1.0 / 29.0))
	testing.expect(
		t,
		math.abs(g.energy - expected) < 1e-5,
		"KE energy gain must match expected math",
	)
}

@(test)
test_ke_score_proximity_bonus :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.paused = false
	g.energy = 0.0
	g.timers[.Score] = {
		done = true,
	}

	g.params.physics.gravity_softening_factor = 1.0
	g.params.physics.energy_gain_coefficient = 1.0
	g.params.physics.energy_momentum_coefficient = 1.0

	id1 := add_test_entity(g, .Asteroid, 10.0, {1.0, 0.0}, {1.0, 0.0})
	game.sys_score(g)
	energy_close := g.energy

	g.energy = 0.0
	g.entities_count = 0
	g.free_entities_count = 0

	id2 := add_test_entity(g, .Asteroid, 10.0, {10.0, 0.0}, {1.0, 0.0})
	game.sys_score(g)
	energy_far := g.energy

	testing.expect(t, energy_close > energy_far, "Proximity to origin must yield higher energy")
}

@(test)
test_energy_source_timer_gated :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.paused = false
	g.dt = 0.5
	g.energy = 0.0

	g.timers[.Score] = {
		done = false,
	}

	id := add_test_entity(g, .Star, 1000.0, {0, 0}, {0, 0})
	game.entity_add_energy_source(
		g,
		id,
		{output = 10.0, timer = {curr = 0, interval = 1.0, done = false}},
	)

	game.sys_score(g)
	testing.expect_value(t, g.energy, f64(0.0))
	testing.expect_value(t, g.entities[id].energy_source.timer.curr, f32(0.5))

	game.sys_score(g)
	testing.expect(t, g.energy > 0, "Energy source must fire after its timer ticks to completion")
}

@(test)
test_energy_generation_radius_scaling :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.paused = false
	g.dt = 1.0
	g.timers[.Score] = {
		done = false,
	}

	g.params.physics.energy_gain_coefficient = 1.0
	g.params.physics.energy_generation_coefficient = 2.0

	id1 := add_test_entity(g, .Star, 1000.0, {0, 0}, {0, 0})
	game.entity_add_energy_source(g, id1, {output = 10.0, timer = {interval = 1.0}})
	g.entities[id1].radius = 2.0

	game.sys_score(g)
	energy1 := g.energy

	g.energy = 0.0
	g.entities_count = 0
	g.free_entities_count = 0

	id2 := add_test_entity(g, .Star, 1000.0, {0, 0}, {0, 0})
	game.entity_add_energy_source(g, id2, {output = 10.0, timer = {interval = 1.0}})
	g.entities[id2].radius = 5.0

	game.sys_score(g)
	energy2 := g.energy

	testing.expect_value(t, energy1, f64(18.0))
	testing.expect_value(t, energy2, f64(60.0))
}

@(test)
test_score_paused_no_change :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.paused = true
	g.dt = 1.0
	g.energy = 100.0
	g.timers[.Score] = {
		done = true,
	}

	id := add_test_entity(g, .Asteroid, 10.0, {0, 0}, {5, 0})

	game.sys_score(g)

	testing.expect_value(t, g.energy, f64(100.0))
}
