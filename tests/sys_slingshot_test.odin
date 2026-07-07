package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_sys_slingshot_inactive :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer test_game_free(g)
	test_game_setup(g)

	g.slingshot.status = .Inactive
	g.score.energy = 1000

	game.sys_slingshot(g)

	testing.expect(t, g.slingshot.status == .Inactive)
	testing.expect(t, g.score.energy == 1000)
	testing.expect(t, g.events_count == 0)
}

@(test)
test_sys_slingshot_active_insufficient_energy :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer test_game_free(g)
	test_game_setup(g)

	g.slingshot.status = .Active
	g.slingshot.start_pos = rl.Vector2{0, 0}
	g.slingshot.end_pos = rl.Vector2{10, 0}
	g.slingshot.output = game.Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}

	g.score.energy = 0

	game.sys_slingshot(g)

	testing.expect(t, !g.slingshot.can_launch)
	testing.expect(t, g.slingshot.status == .Active)
}

@(test)
test_sys_slingshot_active_sufficient_energy :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer test_game_free(g)
	test_game_setup(g)

	g.slingshot.status = .Active
	g.slingshot.output = game.Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}
	g.slingshot.start_pos = rl.Vector2{0, 0}
	g.slingshot.end_pos = rl.Vector2{10, 0}

	g.score.energy = 10000
	game.sys_slingshot(g)

	testing.expect(t, g.slingshot.can_launch)
	testing.expect(t, g.slingshot.status == .Active)
}

@(test)
test_sys_slingshot_released_insufficient_energy :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer test_game_free(g)
	test_game_setup(g)

	g.slingshot.status = .Released
	g.slingshot.output = game.Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}
	g.slingshot.start_pos = rl.Vector2{0, 0}
	g.slingshot.end_pos = rl.Vector2{10, 0}

	g.score.energy = 100
	g.events_count = 0

	game.sys_slingshot(g)

	testing.expect(t, !g.slingshot.can_launch)
	testing.expect(t, g.slingshot.status == .Inactive)
	testing.expect(t, g.events_count == 0)
	testing.expect(t, g.score.energy == 100)
}

@(test)
test_sys_slingshot_released_sufficient_energy :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer test_game_free(g)
	test_game_setup(g)

	g.slingshot.status = .Released
	g.slingshot.output = game.Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}
	g.slingshot.start_pos = rl.Vector2{0, 0}
	g.slingshot.end_pos = rl.Vector2{10, 0}

	g.score.energy = 500
	g.events_count = 0

	game.sys_slingshot(g)

	testing.expect(t, !g.slingshot.can_launch)
	testing.expect(t, g.slingshot.status == .Inactive)
	testing.expect(t, g.score.energy == 90)
	testing.expect(t, g.events_count == 1)

	if g.events_count == 1 {
		event, ok := g.events[0].(game.GameEvent_ObjectSpawn)
		testing.expect(t, ok, "event should be GameEvent_ObjectSpawn")
		if ok {
			testing.expect(t, event.pos == rl.Vector2{0, 0})
			testing.expect(t, event.velocity == rl.Vector2{-10, 0})
			testing.expect(t, event.radius == 2.0)
			testing.expect(t, event.density == 1.0)
			testing.expect(t, event.celestial.type == .DwarfPlanet)
		}
	}
}
