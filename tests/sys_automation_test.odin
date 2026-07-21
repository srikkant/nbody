package tests

import game "../game"
import "core:testing"

test_emitter_component :: proc() -> game.Component_Emitter {
	return {
		emit_density = 1,
		emit_radius = 2,
		emit_vel = {1, 0},
		emit_celestial = {type = .DwarfPlanet},
		max_count = 2,
		timer = {interval = 0.01},
		destroy_timer = {interval = 100},
		base_cost = 5,
	}
}

@(test)
test_sys_automation_emits_when_funded :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id := test_add_emitter(g, {500, 0}, test_emitter_component())
	g.score.energy = 100
	g.dt = 0.02

	game.sys_automation(g)

	expect_event_count(t, g, game.GameEvent_ObjectSpawn, 1)
	testing.expect(t, g.entities[id].emitter.current_count == 1)

	event, ok := g.events[0].(game.GameEvent_ObjectSpawn)
	testing.expect(t, ok)
	if ok {
		testing.expect(t, event.celestial.type == .DwarfPlanet)
		testing.expect(t, event.show_orbit)
	}
}

@(test)
test_sys_automation_skips_when_broke :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_emitter(g, {500, 0}, test_emitter_component())
	g.score.energy = 1 // below base_cost(5)
	g.dt = 0.02

	game.sys_automation(g)

	expect_event_count(t, g, game.GameEvent_ObjectSpawn, 0)
}

@(test)
test_sys_automation_destroyed_at_max_count :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_emitter(g, {500, 0}, test_emitter_component())
	g.score.energy = 100
	g.dt = 0.02

	game.sys_automation(g)
	g.events_count = 0
	game.sys_automation(g)

	expect_event_count(t, g, game.GameEvent_ObjectSpawn, 1)
	expect_event_count(t, g, game.GameEvent_Object_Destroyed, 1)
}

@(test)
test_sys_automation_destroyed_on_timer :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	emitter := test_emitter_component()
	emitter.destroy_timer = {interval = 0.005}
	test_add_emitter(g, {500, 0}, emitter)
	g.score.energy = 0 // no emissions; destruction is timer-driven
	g.dt = 0.02

	game.sys_automation(g)

	expect_event_count(t, g, game.GameEvent_Object_Destroyed, 1)
}
