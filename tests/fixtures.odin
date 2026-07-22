package tests

import game "../game"
import rl "vendor:raylib"

TEST_DT :: f32(1.0 / 60.0)

/*
 * Parameters pinned for tests. Never read live balance values from
 * params_init: tuning the game must not break the test suite.
 */
test_params :: proc() -> game.Parameters {
	p: game.Parameters

	p.celestials[.Asteroid] = {
		density          = 1,
		radius           = 1,
		launch_cost      = 1,
		color            = rl.GRAY,
		visual_class     = .Debris,
		quad_multiplier  = 2,
		trail_multiplier = 1,
	}
	p.celestials[.Moonlet] = {
		density          = 1,
		radius           = 2,
		launch_cost      = 2,
		color            = rl.WHITE,
		visual_class     = .Debris,
		quad_multiplier  = 2,
		trail_multiplier = 1,
	}
	p.celestials[.DwarfPlanet] = {
		density          = 1,
		radius           = 2,
		launch_cost      = 10,
		color            = rl.BLUE,
		visual_class     = .Terrestrial,
		quad_multiplier  = 2,
		trail_multiplier = 1,
	}
	p.celestials[.SubEarth] = {
		density          = 1,
		radius           = 3,
		launch_cost      = 20,
		color            = rl.GREEN,
		visual_class     = .Terrestrial,
		quad_multiplier  = 2,
		trail_multiplier = 1,
	}
	p.celestials[.Star] = {
		density          = 10,
		radius           = 10,
		launch_cost      = 0,
		color            = rl.YELLOW,
		visual_class     = .Anchor,
		quad_multiplier  = 2,
		trail_multiplier = 0,
	}

	p.physics.gravity_constant = 1
	p.physics.mass_absorb_factor = 0.5
	p.physics.collision_mass_loss_factor = 0.01
	p.physics.collision_shatter_threshold_factor = 50
	p.physics.spawn_invincibility_duration_sec = 1
	p.physics.cursor_distance = 50
	p.physics.cursor_distance_squared = 50 * 50
	p.physics.world_radius = 1000
	p.physics.world_radius_squared = 1000 * 1000
	p.physics.energy_gain_factor = 1
	p.physics.energy_source_gain_factor = 1
	p.physics.energy_refund_factor = 0.1

	p.slingshot.launch_power = 1
	p.slingshot.preview_duration = 1

	return p
}

test_make_game :: proc() -> ^game.Game {
	g := new(game.Game)
	g.params = test_params()
	g.dt = TEST_DT
	g.timers[.Score] = game.Timer{0, 1, false}
	g.timers[.Trail] = game.Timer{0, 0.05, false}
	g.timers[.Autosave] = game.Timer{0, game.SAVE_AUTOSAVE_INTERVAL_SEC, false}
	g.slingshot.output = game.Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}
	return g
}

/*
 * Spawns a celestial through the real spawn path. Aged past spawn
 * invincibility by default; pass age = 0 for a fresh spawn.
 */
test_add_celestial :: proc(
	g: ^game.Game,
	type: game.Celestial_Type,
	pos: rl.Vector2,
	vel: rl.Vector2 = {},
	age := f32(100),
) -> game.Entity_Id {
	event := game.GameEvent_ObjectSpawn {
		pos        = pos,
		velocity   = vel,
		density    = g.params.celestials[type].density,
		radius     = g.params.celestials[type].radius,
		celestial  = {type = type},
		renderable = {color = g.params.celestials[type].color},
	}
	game.sys_lifecycle_handle_spawn(g, &event)

	id := game.Entity_Id(g.entities_count - 1)
	g.entities[id].life.created_at = g.elapsed - age
	return id
}

test_add_emitter :: proc(
	g: ^game.Game,
	pos: rl.Vector2,
	emitter: game.Component_Emitter,
) -> game.Entity_Id {
	id := game.entity_create(g)
	game.entity_add_position(g, id, {current = pos})
	game.entity_add_radius(g, id, 2)
	game.entity_add_emitter(g, id, emitter)
	return id
}

/*
 * Runs the same system pipeline as game_run in the Playing state,
 * minus render/camera, with a fixed dt.
 */
test_step :: proc(g: ^game.Game, frames: int, dt := TEST_DT) {
	for _ in 0 ..< frames {
		g.dt = dt
		g.elapsed += dt
		for i in game.Timer_BuiltIn {
			game.math_update_timer(&g.timers[i], dt)
		}
		game.sys_slingshot(g)
		game.sys_modifier(g)
		game.sys_automation(g)
		game.sys_physics(g)
		game.sys_score(g)
		game.sys_lifecycle(g)
	}
}

test_count_sig :: proc(g: ^game.Game, sig: game.Entity_Signature) -> int {
	count := 0
	for i in 0 ..< g.entities_count {
		if sig <= g.entities[i].sig do count += 1
	}
	return count
}

test_find_celestial :: proc(
	g: ^game.Game,
	type: game.Celestial_Type,
) -> (game.Entity_Id, bool) {
	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if .Celestial in e.sig && e.celestial.type == type {
			return game.Entity_Id(i), true
		}
	}
	return 0, false
}
