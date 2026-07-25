package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

// ==========================================
// Compare helpers
// ==========================================

expect_color_eq :: proc(t: ^testing.T, got, want: rl.Color, msg := "") -> bool {
	ok := got.r == want.r && got.g == want.g && got.b == want.b && got.a == want.a
	return testing.expectf(t, ok, "%s: expected color %v == %v", msg, got, want)
}

expect_vec2_eq :: proc(t: ^testing.T, got, want: rl.Vector2, msg := "") -> bool {
	ok := got.x == want.x && got.y == want.y
	return testing.expectf(t, ok, "%s: expected vec2 %v == %v", msg, got, want)
}

expect_timer_eq :: proc(t: ^testing.T, got, want: game.Timer, msg := "") -> bool {
	ok := got.curr == want.curr && got.interval == want.interval && got.done == want.done
	return testing.expectf(t, ok, "%s: expected timer %v == %v", msg, got, want)
}

expect_emitter_eq :: proc(t: ^testing.T, got, want: game.Component_Emitter, msg := "") -> bool {
	ok :=
		got.emit_density == want.emit_density &&
		got.emit_radius == want.emit_radius &&
		got.emit_vel == want.emit_vel &&
		got.emit_celestial.type == want.emit_celestial.type &&
		got.max_count == want.max_count &&
		got.current_count == want.current_count &&
		got.base_cost == want.base_cost
	testing.expectf(t, ok, "%s: expected emitter %v == %v", msg, got, want)
	expect_color_eq(t, got.emit_color, want.emit_color, msg)
	expect_timer_eq(t, got.timer, want.timer, msg)
	expect_timer_eq(t, got.destroy_timer, want.destroy_timer, msg)
	return ok
}

expect_entity_eq :: proc(t: ^testing.T, got, want: game.Entity, idx: u64) -> bool {
	ok := true

	ok =
		testing.expectf(
			t,
			got.sig == want.sig,
			"entity %d: sig %v != %v",
			idx,
			got.sig,
			want.sig,
		) &&
		ok
	ok =
		testing.expectf(
			t,
			got.life.created_at == want.life.created_at,
			"entity %d: life.created_at",
			idx,
		) &&
		ok
	expect_timer_eq(t, got.life.remaining, want.life.remaining, "entity life.remaining")

	expect_vec2_eq(t, got.pos.current, want.pos.current, "entity pos.current")
	for i in 0 ..< game.POSITION_TRAIL_LENGTH {
		expect_vec2_eq(t, got.pos.trail[i], want.pos.trail[i], "entity pos.trail")
	}
	ok =
		testing.expectf(
			t,
			got.pos.trail_head == want.pos.trail_head,
			"entity %d: pos.trail_head",
			idx,
		) &&
		ok

	for i in 0 ..< game.MAX_ORBIT_LENGTH {
		expect_vec2_eq(t, got.orbit.points[i], want.orbit.points[i], "entity orbit.points")
	}
	ok = testing.expectf(t, got.orbit.head == want.orbit.head, "entity %d: orbit.head", idx) && ok
	ok =
		testing.expectf(t, got.orbit.angle == want.orbit.angle, "entity %d: orbit.angle", idx) &&
		ok
	ok =
		testing.expectf(t, got.orbit.count == want.orbit.count, "entity %d: orbit.count", idx) &&
		ok
	ok =
		testing.expectf(
			t,
			got.orbit.max_distance_sq == want.orbit.max_distance_sq,
			"entity %d: orbit.max_distance_sq",
			idx,
		) &&
		ok

	expect_vec2_eq(t, got.velocity.current, want.velocity.current, "entity velocity.current")
	expect_vec2_eq(
		t,
		got.velocity.acceleration,
		want.velocity.acceleration,
		"entity velocity.acceleration",
	)
	ok = testing.expectf(t, got.mass == want.mass, "entity %d: mass", idx) && ok
	ok = testing.expectf(t, got.radius == want.radius, "entity %d: radius", idx) && ok

	ok =
		testing.expectf(
			t,
			got.energy_source.output == want.energy_source.output,
			"entity %d: energy_source.output",
			idx,
		) &&
		ok
	expect_timer_eq(
		t,
		got.energy_source.timer,
		want.energy_source.timer,
		"entity energy_source.timer",
	)

	expect_emitter_eq(t, got.emitter, want.emitter, "entity emitter")
	ok =
		testing.expectf(
			t,
			got.celestial.type == want.celestial.type,
			"entity %d: celestial.type",
			idx,
		) &&
		ok
	expect_color_eq(t, got.renderable.color, want.renderable.color, "entity renderable.color")
	ok =
		testing.expectf(
			t,
			got.collectible_energy.energy == want.collectible_energy.energy,
			"entity %d: collectible_energy.energy",
			idx,
		) &&
		ok
	ok =
		testing.expectf(
			t,
			got.shockwave.growth_rate == want.shockwave.growth_rate,
			"entity %d: shockwave.growth_rate",
			idx,
		) &&
		ok
	expect_color_eq(t, got.shockwave.color, want.shockwave.color, "entity shockwave.color")

	return ok
}

expect_params_eq :: proc(t: ^testing.T, got, want: game.Parameters) -> bool {
	ok := true
	for ct in game.Celestial_Type {
		g := got.celestials[ct]
		w := want.celestials[ct]
		ok =
			testing.expectf(
				t,
				g.density == w.density &&
				g.radius == w.radius &&
				g.launch_cost == w.launch_cost &&
				g.visual_class == w.visual_class &&
				g.quad_multiplier == w.quad_multiplier &&
				g.trail_multiplier == w.trail_multiplier &&
				g.glow_intensity == w.glow_intensity,
				"params.celestials[%v] mismatch",
				ct,
			) &&
			ok
		expect_color_eq(t, g.color, w.color, "params celestial color")
	}

	gp := got.physics
	wp := want.physics
	ok =
		testing.expectf(
			t,
			gp.gravity_constant == wp.gravity_constant &&
			gp.mass_absorb_factor == wp.mass_absorb_factor &&
			gp.collision_mass_loss_factor == wp.collision_mass_loss_factor &&
			gp.collision_shatter_threshold_factor == wp.collision_shatter_threshold_factor &&
			gp.spawn_invincibility_duration_sec == wp.spawn_invincibility_duration_sec &&
			gp.cursor_distance == wp.cursor_distance &&
			gp.cursor_distance_squared == wp.cursor_distance_squared &&
			gp.world_radius == wp.world_radius &&
			gp.world_radius_squared == wp.world_radius_squared &&
			gp.energy_gain_factor == wp.energy_gain_factor &&
			gp.energy_source_gain_factor == wp.energy_source_gain_factor &&
			gp.energy_refund_factor == wp.energy_refund_factor,
			"params.physics mismatch",
		) &&
		ok

	ok =
		testing.expectf(
			t,
			got.slingshot.launch_power == want.slingshot.launch_power &&
			got.slingshot.preview_duration == want.slingshot.preview_duration,
			"params.slingshot mismatch",
		) &&
		ok

	return ok
}

// ==========================================
// Fixture
// ==========================================

/*
 * Builds a game populated across every persisted field group:
 * score ring buffers, timers, help, camera, slingshot (emitter output),
 * entities incl. trail/orbit arrays, a populated free list and modifiers.
 */
test_make_populated_game :: proc() -> ^game.Game {
	g := test_make_game()

	g.elapsed = 123.5
	g.score.energy = 987654.25
	g.score.energy_rate_ticker = 3
	g.score.total_objects = 42
	for i in 0 ..< game.AVG_CALC_TICKS {
		g.score.energy_gains[i] = f64(i) * 1.5
		g.score.energy_losses[i] = f64(i) * 2.5
	}
	g.timers[.Score] = {0.5, 1, false}
	g.timers[.Trail] = {0.02, 0.05, true}
	g.timers[.Autosave] = {15, game.SAVE_AUTOSAVE_INTERVAL_SEC, false}
	g.help.launch_done = true
	g.camera.rl_cam.zoom = 0.75
	g.camera.rl_cam.target = {100, -50}
	g.slingshot.available_objects = {.DwarfPlanet, .SubEarth}
	g.slingshot.launch_power = 2.5
	g.slingshot.output = game.Slingshot_Output_Emitter {
		emitter = {
			emit_density = 3.5,
			emit_radius = 7,
			emit_vel = {1, -2},
			emit_celestial = {type = .Moonlet},
			emit_color = rl.Color{10, 20, 30, 40},
			max_count = 11,
			current_count = 4,
			timer = {curr = 0.25, interval = 2, done = false},
			destroy_timer = {curr = 1, interval = 9, done = true},
			base_cost = 1234.5,
		},
	}
	g.params.physics.gravity_constant = 7.5
	g.effective_params = g.params

	_ = test_add_celestial(g, .Star, {0, 0})

	id2 := test_add_celestial(g, .DwarfPlanet, {100, 50}, {1, 2})
	game.entity_add_orbit(g, id2, {})
	for i in 0 ..< game.POSITION_TRAIL_LENGTH {
		g.entities[id2].pos.trail[i] = {f32(i) + 0.5, f32(-i) - 0.5}
	}
	g.entities[id2].pos.trail_head = 3
	for i in 0 ..< game.MAX_ORBIT_LENGTH {
		g.entities[id2].orbit.points[i] = {f32(i) * 2, f32(i) * -3}
	}
	g.entities[id2].orbit.head = 7
	g.entities[id2].orbit.angle = 1.5
	g.entities[id2].orbit.count = 50
	g.entities[id2].orbit.max_distance_sq = 900

	id3 := test_add_emitter(
		g,
		{-50, 25},
		{
			emit_density = 2,
			emit_radius = 5,
			emit_vel = {3, 4},
			emit_celestial = {type = .Asteroid},
			emit_color = rl.Color{200, 100, 50, 255},
			max_count = 10,
			current_count = 3,
			timer = {curr = 1, interval = 2, done = false},
			destroy_timer = {curr = 0.5, interval = 5, done = true},
			base_cost = 500,
		},
	)

	// Populate the free list.
	game.entity_free(g, id3)

	g.modifiers[0] = {
		kind = .Gravity_Boost,
		permanent = false,
		timer = {curr = 10, interval = 30, done = false},
	}
	g.modifiers_count = 1

	return g
}

// ==========================================
// Tests
// ==========================================

@(test)
test_persistence_roundtrip :: proc(t: ^testing.T) {
	g := test_make_populated_game()
	defer free(g)

	buf := make([]u8, game.MAX_SAVE_SIZE)
	defer delete(buf)

	n, ok := game.persist_serialize(g, buf)
	testing.expect(t, ok, "serialize failed")
	testing.expect(t, n > game.SAVE_HEADER_SIZE, "serialize wrote nothing")

	g2 := new(game.Game)
	defer free(g2)
	g2.screenw = 1440
	g2.screenh = 810
	testing.expect(t, game.persist_deserialize(g2, buf[:n]), "deserialize failed")

	// Transient state reset.
	testing.expect(t, g2.status == .Paused, "loaded run not paused")
	testing.expect(t, g2.events_count == 0, "events not cleared")
	testing.expect(t, g2.slingshot.status == .Inactive, "slingshot not reset to Inactive")
	testing.expect(t, g2.slingshot.preview_count == 0, "slingshot preview not cleared")

	// Camera offset seeded from screen size since sys_camera skips .Paused.
	expect_vec2_eq(t, g2.camera.rl_cam.offset, {720, 405}, "camera offset")

	// Scalar state.
	testing.expect(t, g2.elapsed == g.elapsed, "elapsed mismatch")
	testing.expect(t, g2.score.energy == g.score.energy, "score.energy mismatch")
	testing.expect(
		t,
		g2.score.energy_rate_ticker == g.score.energy_rate_ticker,
		"score.energy_rate_ticker mismatch",
	)
	testing.expect(
		t,
		g2.score.total_objects == g.score.total_objects,
		"score.total_objects mismatch",
	)
	for i in 0 ..< game.AVG_CALC_TICKS {
		testing.expect(
			t,
			g2.score.energy_gains[i] == g.score.energy_gains[i],
			"score.energy_gains mismatch",
		)
		testing.expect(
			t,
			g2.score.energy_losses[i] == g.score.energy_losses[i],
			"score.energy_losses mismatch",
		)
	}
	for i in game.Timer_BuiltIn {
		expect_timer_eq(t, g2.timers[i], g.timers[i], "timers")
	}
	testing.expect(t, g2.help.launch_done == g.help.launch_done, "help.launch_done mismatch")
	testing.expect(t, g2.camera.rl_cam.zoom == g.camera.rl_cam.zoom, "camera zoom mismatch")
	expect_vec2_eq(t, g2.camera.rl_cam.target, g.camera.rl_cam.target, "camera target")

	// Slingshot persisted fields.
	testing.expect(
		t,
		g2.slingshot.available_objects == g.slingshot.available_objects,
		"available_objects mismatch",
	)
	testing.expect(
		t,
		g2.slingshot.launch_power == g.slingshot.launch_power,
		"slingshot launch_power mismatch",
	)
	want_out, want_out_ok := g.slingshot.output.(game.Slingshot_Output_Emitter)
	testing.expect(t, want_out_ok, "fixture output should be emitter variant")
	got_out, got_out_ok := g2.slingshot.output.(game.Slingshot_Output_Emitter)
	testing.expect(t, got_out_ok, "deserialized output should be emitter variant")
	expect_emitter_eq(t, got_out.emitter, want_out.emitter, "slingshot output emitter")

	// Parameters.
	expect_params_eq(t, g2.params, g.params)

	// Entities, full SOA roundtrip.
	testing.expect(t, g2.entities_count == g.entities_count, "entities_count mismatch")
	for i in 0 ..< g.entities_count {
		got := g2.entities[i]
		want := g.entities[i]
		expect_entity_eq(t, got, want, i)
	}

	// Free list.
	testing.expect(
		t,
		g2.free_entities_count == g.free_entities_count,
		"free_entities_count mismatch",
	)
	for i in 0 ..< g.free_entities_count {
		testing.expect(t, g2.free_entities[i] == g.free_entities[i], "free_entities mismatch")
	}

	// Modifiers.
	testing.expect(t, g2.modifiers_count == g.modifiers_count, "modifiers_count mismatch")
	for i in 0 ..< g.modifiers_count {
		testing.expect(t, g2.modifiers[i] == g.modifiers[i], "modifiers mismatch")
	}
}

@(test)
test_persistence_rejects_bad_magic :: proc(t: ^testing.T) {
	g := test_make_populated_game()
	defer free(g)

	buf := make([]u8, game.MAX_SAVE_SIZE)
	defer delete(buf)

	n, ok := game.persist_serialize(g, buf)
	testing.expect(t, ok, "serialize failed")

	buf[0] = 'X'

	g2 := new(game.Game)
	defer free(g2)
	testing.expect(t, !game.persist_deserialize(g2, buf[:n]), "bad magic accepted")
}

@(test)
test_persistence_rejects_bad_version :: proc(t: ^testing.T) {
	g := test_make_populated_game()
	defer free(g)

	buf := make([]u8, game.MAX_SAVE_SIZE)
	defer delete(buf)

	n, ok := game.persist_serialize(g, buf)
	testing.expect(t, ok, "serialize failed")

	buf[4] = 0xFF // first byte of little-endian u32 version

	g2 := new(game.Game)
	defer free(g2)
	testing.expect(t, !game.persist_deserialize(g2, buf[:n]), "bad version accepted")
}

@(test)
test_persistence_rejects_corrupt_payload :: proc(t: ^testing.T) {
	g := test_make_populated_game()
	defer free(g)

	buf := make([]u8, game.MAX_SAVE_SIZE)
	defer delete(buf)

	n, ok := game.persist_serialize(g, buf)
	testing.expect(t, ok, "serialize failed")

	buf[game.SAVE_HEADER_SIZE] ~= 0xFF

	g2 := new(game.Game)
	defer free(g2)
	testing.expect(t, !game.persist_deserialize(g2, buf[:n]), "corrupt payload accepted")
}

@(test)
test_persistence_rejects_truncated :: proc(t: ^testing.T) {
	g := test_make_populated_game()
	defer free(g)

	buf := make([]u8, game.MAX_SAVE_SIZE)
	defer delete(buf)

	n, ok := game.persist_serialize(g, buf)
	testing.expect(t, ok, "serialize failed")

	g2 := new(game.Game)
	defer free(g2)
	testing.expect(t, !game.persist_deserialize(g2, buf[:n - 1]), "truncated buffer accepted")
	testing.expect(
		t,
		!game.persist_deserialize(g2, buf[:game.SAVE_HEADER_SIZE - 1]),
		"short header accepted",
	)
}

@(test)
test_persistence_autosave_interval :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	testing.expect(t, !g.timers[.Autosave].done, "done at elapsed 0")

	// Update by 29 seconds (below 30 interval)
	game.math_update_timer(&g.timers[.Autosave], 29.0)
	testing.expect(t, !g.timers[.Autosave].done, "done before interval")

	// Update by 1.1 seconds (reaches interval)
	game.math_update_timer(&g.timers[.Autosave], 1.1)
	testing.expect(t, g.timers[.Autosave].done, "not done at interval")

	// Next frame update (resets done flag)
	game.math_update_timer(&g.timers[.Autosave], 0.016)
	testing.expect(t, !g.timers[.Autosave].done, "done right after reset")
}
