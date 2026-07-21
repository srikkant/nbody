package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_sys_physics_bodies_attract :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id1 := test_add_celestial(g, .DwarfPlanet, {-50, 0})
	id2 := test_add_celestial(g, .DwarfPlanet, {50, 0})

	game.sys_physics(g)

	testing.expect(t, g.entities[id1].velocity.current.x > 0, "left body pulled right")
	testing.expect(t, g.entities[id2].velocity.current.x < 0, "right body pulled left")
}

@(test)
test_sys_physics_star_is_immovable :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	star := test_add_celestial(g, .Star, {0, 0})
	test_add_celestial(g, .DwarfPlanet, {50, 0})

	test_step(g, 10)

	expect_vec2_approx(t, g.entities[star].pos.current, rl.Vector2{0, 0})
}

@(test)
test_sys_physics_collision_pushes_event :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .DwarfPlanet, {0, 0})
	test_add_celestial(g, .DwarfPlanet, {3, 0}) // overlapping: r1 + r2 = 4

	game.sys_physics(g)

	testing.expect(
		t,
		g.events_count >= 1,
		"overlapping aged bodies should push a collision event",
	)
}

@(test)
test_sys_physics_spawn_invincibility_suppresses_collision :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .DwarfPlanet, {0, 0}, age = 0)
	test_add_celestial(g, .DwarfPlanet, {3, 0}, age = 0)

	game.sys_physics(g)

	expect_event_count(t, g, game.GameEvent_Collision, 0)
}

@(test)
test_sys_physics_out_of_bounds_pushes_event :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .DwarfPlanet, {2000, 0})

	game.sys_physics(g)

	expect_event_count(t, g, game.GameEvent_Object_OutOfBounds, 1)
}

@(test)
test_sys_physics_orbit_points_recorded :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .Star, {0, 0})
	id := test_add_celestial(g, .DwarfPlanet, {100, 0}, {0, 50})
	game.entity_add_orbit(g, id, {})

	test_step(g, 10)

	testing.expect(t, g.entities[id].orbit.count > 0, "moving body records orbit points")
}

@(test)
test_sys_physics_trail_recorded_on_timer :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id := test_add_celestial(g, .DwarfPlanet, {100, 0}, {0, 10})
	g.timers[.Trail].done = true

	game.sys_physics(g)

	testing.expect(t, g.entities[id].pos.trail_head == 1, "trail head advances")
	expect_vec2_approx(t, g.entities[id].pos.trail[0], g.entities[id].pos.current)
}
