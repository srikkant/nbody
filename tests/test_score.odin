package tests

import game "../game"
import "core:math"
import "core:testing"

@(test)
test_ke_score_formula :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.status = .Paused
	g.dt = 0.016
	g.score.energy = 0.0

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
		math.abs(g.score.energy - expected) < 1e-5,
		"KE energy gain must match expected math",
	)
}

@(test)
test_ke_score_proximity_bonus :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.score.energy = 0.0
	g.timers[.Score] = {
		done = true,
	}

	g.params.physics.gravity_softening_factor = 1.0
	g.params.physics.energy_gain_coefficient = 1.0
	g.params.physics.energy_momentum_coefficient = 1.0

	id1 := add_test_entity(g, .Asteroid, 10.0, {1.0, 0.0}, {1.0, 0.0})
	game.sys_score(g)
	energy_close := g.score.energy

	g.score.energy = 0.0
	g.entities_count = 0
	g.free_entities_count = 0

	id2 := add_test_entity(g, .Asteroid, 10.0, {10.0, 0.0}, {1.0, 0.0})
	game.sys_score(g)
	energy_far := g.score.energy

	testing.expect(t, energy_close > energy_far, "Proximity to origin must yield higher energy")
}

@(test)
test_energy_generation_radius_scaling :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

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
	energy1 := g.score.energy

	g.score.energy = 0.0
	g.entities_count = 0
	g.free_entities_count = 0

	id2 := add_test_entity(g, .Star, 1000.0, {0, 0}, {0, 0})
	game.entity_add_energy_source(g, id2, {output = 10.0, timer = {interval = 1.0}})
	g.entities[id2].radius = 5.0

	game.sys_score(g)
	energy2 := g.score.energy

	testing.expect_value(t, energy1, f64(18.0))
	testing.expect_value(t, energy2, f64(60.0))
}

