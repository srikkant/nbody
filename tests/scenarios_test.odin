package tests

import game "../game"
import "core:math"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_scenario_orbit_generates_energy :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Circular orbit: v = sqrt(G * M / r) with G=1, star mass 1000, r=100
	star := test_add_celestial(g, .Star, {0, 0})
	orbital_vel := math.sqrt(f32(1000.0 / 100.0))
	id := test_add_celestial(g, .DwarfPlanet, {100, 0}, {0, orbital_vel})

	test_step(g, 300) // 5 seconds

	testing.expect(t, g.entities[id].sig != {}, "orbiting body survives")
	testing.expect(t, g.entities[star].sig != {}, "star survives")

	dist := rl.Vector2Length(g.entities[id].pos.current)
	testing.expect(t, dist > 50 && dist < 400, "body stays near its orbital radius")

	testing.expect(t, g.score.energy > 0, "orbit generates energy")
}

@(test)
test_scenario_slow_collision_merges :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .Asteroid, {-10, 0}, {3, 0})
	test_add_celestial(g, .Asteroid, {10, 0}, {-3, 0})

	test_step(g, 240)

	testing.expect(t, test_count_sig(g, game.PHYSICS_SIG) == 1, "one body remains")
	_, found := test_find_celestial(g, .Moonlet)
	testing.expect(t, found, "asteroids merge into a moonlet")
}

@(test)
test_scenario_fast_collision_shatters_and_collects :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .DwarfPlanet, {-50, 0}, {30, 0})
	test_add_celestial(g, .DwarfPlanet, {50, 0}, {-30, 0})
	g.input.mouse_pos = {0, 0} // hover the impact point to collect fragments
	g.timers[.Score] = game.Timer{interval = 1000} // isolate fragment energy from KE scoring

	test_step(g, 150)

	testing.expect(t, test_count_sig(g, game.PHYSICS_SIG) == 0, "both bodies destroyed")
	testing.expect(
		t,
		test_count_sig(g, {game.Component_Type.CollectibleEnergy}) == 0,
		"fragments collected",
	)

	// shatter mass pool: (4 + 4) * 0.5 = 4
	expect_f64_approx(t, g.score.energy, 4, eps = 1e-4)
}

@(test)
test_scenario_launch_via_full_pipeline :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .Star, {0, 0})
	g.score.energy = 1000

	g.slingshot.status = .Active
	g.slingshot.start_pos = {200, 0}
	g.slingshot.end_pos = {200, 0}
	g.slingshot.output = game.Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}
	g.slingshot.status = .Released

	test_step(g, 1)

	testing.expect(t, test_count_sig(g, game.PHYSICS_SIG) == 2, "star plus launched body")
	_, found := test_find_celestial(g, .DwarfPlanet)
	testing.expect(t, found, "launched body exists after pipeline")
}
