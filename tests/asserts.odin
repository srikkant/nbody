package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

expect_f32_approx :: proc(t: ^testing.T, got, want: f32, eps := f32(1e-4), msg := "") -> bool {
	ok := abs(got - want) <= eps
	return testing.expectf(t, ok, "%s: expected %v ≈ %v (eps %v)", msg, got, want, eps)
}

expect_f64_approx :: proc(t: ^testing.T, got, want: f64, eps := f64(1e-6), msg := "") -> bool {
	ok := abs(got - want) <= eps
	return testing.expectf(t, ok, "%s: expected %v ≈ %v (eps %v)", msg, got, want, eps)
}

expect_vec2_approx :: proc(
	t: ^testing.T,
	got, want: rl.Vector2,
	eps := f32(1e-4),
	msg := "",
) -> bool {
	ok := abs(got.x - want.x) <= eps && abs(got.y - want.y) <= eps
	return testing.expectf(t, ok, "%s: expected %v ≈ %v (eps %v)", msg, got, want, eps)
}

expect_event_count :: proc(t: ^testing.T, g: ^game.Game, $T: typeid, want: int) -> bool {
	count := 0
	for i in 0 ..< g.events_count {
		if _, ok := g.events[i].(T); ok do count += 1
	}
	ok := count == want
	return testing.expectf(
		t,
		ok,
		"expected %d events of type %v, got %d",
		want,
		typeid_of(T),
		count,
	)
}


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
