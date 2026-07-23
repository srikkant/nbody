package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_physics_calculate_mass :: proc(t: ^testing.T) {
	expect_f32_approx(t, game.physics_calculate_mass(2, 3), 18)
	expect_f32_approx(t, game.physics_calculate_mass(1, 2), 4)
}

@(test)
test_physics_radius_from_mass_density :: proc(t: ^testing.T) {
	expect_f32_approx(t, game.physics_radius_from_mass_density(18, 2), 3)
	expect_f32_approx(
		t,
		game.physics_radius_from_mass_density(4, 0),
		0,
		msg = "zero density is safe",
	)
	expect_f32_approx(
		t,
		game.physics_radius_from_mass_density(4, -1),
		0,
		msg = "negative density is safe",
	)
}

@(test)
test_physics_slingshot_release_velocity :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	g.params.slingshot.launch_power = 2
	g.slingshot.start_pos = {10, 5}
	g.slingshot.end_pos = {4, 3}

	expect_vec2_approx(t, game.physics_get_slingshot_release_velocity(g), rl.Vector2{12, 4})
}

@(test)
test_physics_gravitational_acceleration :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// G = 1, source mass 100 at (10, 0), target at origin
	accel := game.physics_get_gravitational_acceleration(g, {0, 0}, 1, {10, 0}, 100, 1)
	expect_vec2_approx(t, accel, rl.Vector2{1, 0}, eps = 1e-5)

	// Overlapping bodies (r < 1) produce no acceleration
	accel_close := game.physics_get_gravitational_acceleration(g, {0, 0}, 1, {0.5, 0}, 100, 1)
	expect_vec2_approx(t, accel_close, rl.Vector2{0, 0})
}

@(test)
test_physics_rk4_falls_toward_star :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	test_add_celestial(g, .Star, {0, 0})

	pos := rl.Vector2{100, 0}
	vel := rl.Vector2{0, 0}

	initial_dist := rl.Vector2Length(pos)
	for _ in 0 ..< 100 {
		game.physics_rk4_step(g, &pos, &vel, 0.01, 1)
	}

	final_dist := rl.Vector2Length(pos)
	testing.expect(t, final_dist < initial_dist, "body should fall toward the star")
	testing.expect(t, abs(vel.x) > 0, "body should gain velocity toward the star")
}

@(test)
test_math_update_timer :: proc(t: ^testing.T) {
	timer := game.Timer {
		interval = 1.0,
	}

	game.math_update_timer(&timer, 0.5)
	testing.expect(t, !timer.done)
	expect_f32_approx(t, timer.curr, 0.5)

	game.math_update_timer(&timer, 0.6)
	testing.expect(t, timer.done, "crossing the interval completes the timer")
	expect_f32_approx(t, timer.curr, 0.1, msg = "remainder wraps around")

	game.math_update_timer(&timer, 0.2)
	testing.expect(t, !timer.done, "done resets every update")
}

@(test)
test_math_catmull_rom_endpoints :: proc(t: ^testing.T) {
	p0 := rl.Vector2{0, 0}
	p1 := rl.Vector2{1, 1}
	p2 := rl.Vector2{2, 1}
	p3 := rl.Vector2{3, 0}

	expect_vec2_approx(t, game.math_catmull_rom(p0, p1, p2, p3, 0), p1, eps = 1e-5)
	expect_vec2_approx(t, game.math_catmull_rom(p0, p1, p2, p3, 1), p2, eps = 1e-5)

	mid := game.math_catmull_rom(p0, p1, p2, p3, 0.5)
	testing.expect(t, mid.x > p1.x && mid.x < p2.x)
	testing.expect(t, mid.y >= 1, "curve bulges above control segment")
}

@(test)
test_math_vec2_length :: proc(t: ^testing.T) {
	expect_f32_approx(t, game.math_vec2_length({3, 4}), 5)
	expect_f32_approx(t, game.math_vec2_length_sq({3, 4}), 25)
}
