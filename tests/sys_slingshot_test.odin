package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

/*
 * Cost model under pinned test params for a DwarfPlanet launch with a
 * 10-unit drag: launch_cost(10) + density(1) * radius²(4) * |vel|²(100) = 410
 */
SLINGSHOT_TEST_COST :: 410

test_slingshot_setup :: proc(g: ^game.Game, start, end: rl.Vector2) {
	g.slingshot.status = .Active
	g.slingshot.start_pos = start
	g.slingshot.end_pos = end
	g.slingshot.preview = 1
	g.slingshot.output = game.Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}
}

@(test)
test_sys_slingshot_inactive :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	g.slingshot.status = .Inactive
	g.score.energy = 1000

	game.sys_slingshot(g)

	testing.expect(t, g.slingshot.status == .Inactive)
	testing.expect(t, g.score.energy == 1000)
	testing.expect(t, g.events_count == 0)
}

@(test)
test_sys_slingshot_active_insufficient_energy :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_slingshot_setup(g, {0, 0}, {10, 0})
	g.score.energy = 0

	game.sys_slingshot(g)

	testing.expect(t, !g.slingshot.can_launch)
	testing.expect(t, g.slingshot.status == .Active)
}

@(test)
test_sys_slingshot_active_sufficient_energy :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_slingshot_setup(g, {0, 0}, {10, 0})
	g.score.energy = SLINGSHOT_TEST_COST

	game.sys_slingshot(g)

	testing.expect(t, g.slingshot.can_launch, "energy == cost must be launchable")
	testing.expect(t, g.slingshot.status == .Active)
}

@(test)
test_sys_slingshot_released_insufficient_energy :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_slingshot_setup(g, {0, 0}, {10, 0})
	g.slingshot.status = .Released
	g.score.energy = 100

	game.sys_slingshot(g)

	testing.expect(t, !g.slingshot.can_launch)
	testing.expect(t, g.slingshot.status == .Inactive)
	expect_event_count(t, g, game.GameEvent_ObjectSpawn, 0)
	testing.expect(t, g.score.energy == 100, "no charge on a failed launch")
}

@(test)
test_sys_slingshot_released_sufficient_energy :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_slingshot_setup(g, {0, 0}, {10, 0})
	g.slingshot.status = .Released
	g.score.energy = 500

	game.sys_slingshot(g)

	testing.expect(t, g.slingshot.status == .Inactive)
	expect_f64_approx(t, g.score.energy, 500 - SLINGSHOT_TEST_COST)
	expect_event_count(t, g, game.GameEvent_ObjectSpawn, 1)

	if g.events_count == 1 {
		event, ok := g.events[0].(game.GameEvent_ObjectSpawn)
		testing.expect(t, ok, "event should be GameEvent_ObjectSpawn")
		if ok {
			expect_vec2_approx(t, event.pos, rl.Vector2{0, 0})
			expect_vec2_approx(t, event.velocity, rl.Vector2{-10, 0})
			expect_f32_approx(t, event.radius, 2)
			expect_f32_approx(t, event.density, 1)
			testing.expect(t, event.celestial.type == .DwarfPlanet)
		}
	}

	testing.expect(t, g.help.launch_done, "successful launch completes the tutorial")
}

@(test)
test_sys_slingshot_preview_straight_line_without_gravity :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_slingshot_setup(g, {100, 0}, {100, 10})
	g.score.energy = 1000

	game.sys_slingshot(g)

	testing.expect(t, g.slingshot.preview_count > 10)
	expect_vec2_approx(t, g.slingshot.preview_points[0], rl.Vector2{100, 0})

	last := g.slingshot.preview_points[g.slingshot.preview_count - 1]
	testing.expect(t, last.y < -5, "preview travels along the release velocity")
}

@(test)
test_sys_slingshot_preview_terminates_on_collision :: proc(t: ^testing.T) {
	g_clear := test_make_game()
	defer free(g_clear)
	test_slingshot_setup(g_clear, {20, 0}, {40, 0})
	g_clear.score.energy = 10000
	game.sys_slingshot(g_clear)

	g_hit := test_make_game()
	defer free(g_hit)
	test_add_celestial(g_hit, .Star, {0, 0})
	test_slingshot_setup(g_hit, {20, 0}, {40, 0})
	g_hit.score.energy = 10000
	game.sys_slingshot(g_hit)

	testing.expect(t, g_clear.slingshot.preview_count > 10)
	testing.expect(
		t,
		g_hit.slingshot.preview_count < g_clear.slingshot.preview_count,
		"preview stops early when the path hits the star",
	)
}

@(test)
test_sys_slingshot_preview_zero_when_unlaunchable :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_slingshot_setup(g, {0, 0}, {10, 0})
	g.score.energy = 0

	game.sys_slingshot(g)

	testing.expect(t, g.slingshot.preview_count == 0)
}

@(test)
test_sys_slingshot_preview_zero_when_preview_disabled :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_slingshot_setup(g, {0, 0}, {10, 0})
	g.slingshot.preview = 0
	g.score.energy = 1000

	game.sys_slingshot(g)

	testing.expect(t, g.slingshot.preview_count == 0)
}
