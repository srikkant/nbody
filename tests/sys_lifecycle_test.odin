package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_sys_lifecycle_classify_star_absorb :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	star := test_add_celestial(g, .Star, {0, 0})
	other := test_add_celestial(g, .DwarfPlanet, {15, 0})

	event := game.GameEvent_Collision{id1 = star, id2 = other}
	testing.expect(t, game.sys_lifecycle_collision_classify(g, &event) == .StarAbsorb)
}

@(test)
test_sys_lifecycle_classify_merge :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Same type, slow approach: rel_speed² (4) < threshold² (50 * 8 / 4 = 100)
	id1 := test_add_celestial(g, .DwarfPlanet, {-10, 0}, {1, 0})
	id2 := test_add_celestial(g, .DwarfPlanet, {10, 0}, {-1, 0})

	event := game.GameEvent_Collision{id1 = id1, id2 = id2}
	testing.expect(t, game.sys_lifecycle_collision_classify(g, &event) == .Merge)
}

@(test)
test_sys_lifecycle_classify_shatter :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Same type, fast approach: rel_speed² (400) > threshold² (100)
	id1 := test_add_celestial(g, .DwarfPlanet, {-10, 0}, {20, 0})
	id2 := test_add_celestial(g, .DwarfPlanet, {10, 0}, {0, 0})

	event := game.GameEvent_Collision{id1 = id1, id2 = id2}
	testing.expect(t, game.sys_lifecycle_collision_classify(g, &event) == .Shatter)
}

@(test)
test_sys_lifecycle_classify_debris :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id1 := test_add_celestial(g, .Asteroid, {-10, 0})
	id2 := test_add_celestial(g, .DwarfPlanet, {10, 0})

	event := game.GameEvent_Collision{id1 = id1, id2 = id2}
	testing.expect(t, game.sys_lifecycle_collision_classify(g, &event) == .Debris)
}

@(test)
test_sys_lifecycle_merge_evolves_and_conserves :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id1 := test_add_celestial(g, .DwarfPlanet, {-10, 0}, {1, 0})
	id2 := test_add_celestial(g, .DwarfPlanet, {10, 0}, {-1, 0})

	game.push_event(g, game.GameEvent_Collision{id1 = id1, id2 = id2})
	game.sys_lifecycle(g)

	testing.expect(t, g.entities[id1].sig == {}, "first body destroyed")
	testing.expect(t, g.entities[id2].sig == {}, "second body destroyed")

	merged_id, found := test_find_celestial(g, .SubEarth)
	testing.expect(t, found, "merged body evolves to the next tier")
	if found {
		merged := &g.entities[merged_id]
		expect_f32_approx(t, merged.mass, 8, msg = "mass is conserved")
		expect_vec2_approx(t, merged.pos.current, rl.Vector2{0, 0}, msg = "spawned at midpoint")
		expect_vec2_approx(t, merged.velocity.current, rl.Vector2{0, 0}, msg = "momentum conserved")
	}

	testing.expect(t, .SubEarth in g.slingshot.available_objects, "new tier unlocked")
	testing.expect(t, test_count_sig(g, game.SHOCKWAVE_SIG) == 1, "merge spawns a shockwave")
}

@(test)
test_sys_lifecycle_shatter_spawns_fragments :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id1 := test_add_celestial(g, .DwarfPlanet, {-10, 0}, {20, 0})
	id2 := test_add_celestial(g, .DwarfPlanet, {10, 0}, {0, 0})
	g.input.mouse_pos = {9999, 9999} // far away: fragments must survive

	game.push_event(g, game.GameEvent_Collision{id1 = id1, id2 = id2})
	game.sys_lifecycle(g)

	testing.expect(t, g.entities[id1].sig == {})
	testing.expect(t, g.entities[id2].sig == {})

	// frag_count = BASE(3) + rel_speed(20) * FACTOR(0.3) = 9
	frag_count := test_count_sig(g, {game.Component_Type.CollectibleEnergy})
	testing.expect(t, frag_count == 9, "expected 9 fragments")
}

@(test)
test_sys_lifecycle_star_absorbs_mass :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	star := test_add_celestial(g, .Star, {0, 0})
	other := test_add_celestial(g, .DwarfPlanet, {15, 0})

	game.push_event(g, game.GameEvent_Collision{id1 = star, id2 = other})
	game.sys_lifecycle(g)

	testing.expect(t, g.entities[other].sig == {}, "absorbed body destroyed")

	star_mass := g.entities[star].mass
	expect_f32_approx(t, star_mass, 1002, msg = "star gains mass * absorb_factor(0.5)")

	expected_radius := game.physics_radius_from_mass_density(1002, 10)
	expect_f32_approx(t, g.entities[star].radius, expected_radius, eps = 1e-3)
}

@(test)
test_sys_lifecycle_out_of_bounds_refunds :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id := test_add_celestial(g, .DwarfPlanet, {2000, 0})

	game.push_event(g, game.GameEvent_Object_OutOfBounds{id = id})
	game.sys_lifecycle(g)

	testing.expect(t, g.entities[id].sig == {})
	// refund = refund_factor(0.1) * mass(4) * radius(2)
	expect_f64_approx(t, g.score.energy, 0.8)
}

@(test)
test_sys_lifecycle_demolish_nearest :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	near := test_add_celestial(g, .DwarfPlanet, {10, 0})
	far := test_add_celestial(g, .DwarfPlanet, {40, 0})
	g.input.mouse_pos = {0, 0}

	game.push_event(g, game.GameEvent_Object_Demolish{})
	game.sys_lifecycle(g)

	testing.expect(t, g.entities[near].sig == {}, "nearest body demolished")
	testing.expect(t, g.entities[far].sig != {}, "further body survives")
	expect_f64_approx(t, g.score.energy, 0.8)
}

@(test)
test_sys_lifecycle_demolish_skips_star_and_distant :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	star := test_add_celestial(g, .Star, {0, 0})
	distant := test_add_celestial(g, .DwarfPlanet, {500, 0})
	g.input.mouse_pos = {0, 0}

	game.push_event(g, game.GameEvent_Object_Demolish{})
	game.sys_lifecycle(g)

	testing.expect(t, g.entities[star].sig != {}, "star cannot be demolished")
	testing.expect(t, g.entities[distant].sig != {}, "out-of-range body survives")
	expect_f64_approx(t, g.score.energy, 0)
}

@(test)
test_sys_lifecycle_fragments_collected_on_hover :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	game.sys_lifecycle_spawn_fragments(g, 9, 0, {0, 0})
	g.input.mouse_pos = {0, 0}

	game.sys_lifecycle(g)

	expect_f64_approx(t, g.score.energy, 9)
	testing.expect(
		t,
		test_count_sig(g, {game.Component_Type.CollectibleEnergy}) == 0,
		"all fragments collected",
	)
}

@(test)
test_sys_lifecycle_life_timer_expires_entity :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id := game.entity_create(g)
	game.entity_add_position(g, id, {current = {0, 0}})
	game.entity_add_life(g, id, {created_at = g.elapsed, remaining = {interval = 0.01}})

	g.dt = 0.02
	game.sys_lifecycle(g)

	testing.expect(t, g.entities[id].sig == {}, "entity expires when its timer completes")
}
