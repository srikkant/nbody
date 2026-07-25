package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_persistence_roundtrip :: proc(t: ^testing.T) {
	g := test_make_populated_game()
	defer free(g)

	buf := make([]u8, game.MAX_SAVE_SIZE)
	defer delete(buf)

	n, ok := game.persist_serialize(g, buf)
	testing.expect(t, ok, "serialize failed")
	testing.expect(t, n > game.SAVE_HEADER_SIZE, "serialize wrote nothing")

	g2 := test_make_game()
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
		g2.score.lifetime_energy_earned == g.score.lifetime_energy_earned,
		"score.lifetime_energy_earned mismatch",
	)
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

	// Modifiers & Upgrades.
	testing.expect(t, g2.modifiers_count == g.modifiers_count, "modifiers_count mismatch")
	for i in 0 ..< g.modifiers_count {
		testing.expect(t, g2.modifiers[i] == g.modifiers[i], "modifiers mismatch")
	}
	for id in game.Upgrade_Id {
		testing.expect(t, g2.upgrade_levels[id] == g.upgrade_levels[id], "upgrade_levels mismatch")
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

	g2 := test_make_game()
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

	g2 := test_make_game()
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

	g2 := test_make_game()
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

	g2 := test_make_game()
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

@(test)
test_persistence_upgrade_levels_clamped :: proc(t: ^testing.T) {
	g := test_make_populated_game()
	defer free(g)

	// Set level above max_level
	g.upgrade_levels[.Gravity_Tuning] = 10

	buf := make([]u8, game.MAX_SAVE_SIZE)
	defer delete(buf)

	n, ok := game.persist_serialize(g, buf)
	testing.expect(t, ok, "serialize failed")

	g2 := test_make_game()
	defer free(g2)
	testing.expect(t, game.persist_deserialize(g2, buf[:n]), "deserialize failed")

	// Gravity_Tuning max_level is 5
	testing.expect_value(t, g2.upgrade_levels[.Gravity_Tuning], u8(5))
}

@(test)
test_persistence_modifier_kind_guard :: proc(t: ^testing.T) {
	g1 := test_make_game()
	defer free(g1)

	game.modifier_add(g1, .Gravity_Boost)

	buf := make([]u8, game.MAX_SAVE_SIZE)
	defer delete(buf)

	n, serialize_ok := game.persist_serialize(g1, buf)
	testing.expect(t, serialize_ok)

	// Tamper with the kind field near end of buffer
	kind_offset := n - 17
	buf[kind_offset] = 99 // invalid Modifier_Kind ordinal

	g2 := test_make_game()
	defer free(g2)

	ok := game.persist_deserialize(g2, buf[:n])
	testing.expect(t, !ok, "deserialize should fail when kind is invalid")
}
