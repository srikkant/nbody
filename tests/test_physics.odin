package tests

import game "../game"
import "core:math"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_gravity_two_body_attraction :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	target_pos := rl.Vector2{0, 0}
	source_pos := rl.Vector2{10, 0}
	source_mass: f32 = 100.0

	accel, r2 := game.physics_get_gravitational_acceleration(
		g,
		target_pos,
		1.0,
		source_pos,
		source_mass,
		1.0,
	)

	testing.expect(t, accel.x > 0, "Acceleration should point towards source (positive X)")
	testing.expect_value(t, accel.y, 0.0)
	testing.expect_value(t, r2, 100.0)
}

@(test)
test_gravity_inverse_square_falloff :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.params.physics.gravity_softening_factor = 0.0
	g.params.physics.gravity_constant = 1.0

	accel1, _ := game.physics_get_gravitational_acceleration(g, {0, 0}, 1.0, {5, 0}, 100.0, 1.0)

	accel2, _ := game.physics_get_gravitational_acceleration(g, {0, 0}, 1.0, {10, 0}, 100.0, 1.0)

	ratio := accel1.x / accel2.x
	testing.expect(
		t,
		math.abs(ratio - 4.0) < 1e-5,
		"Double distance must result in 1/4 acceleration",
	)
}

@(test)
test_gravity_softening_prevents_singularity :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.params.physics.gravity_softening_factor = 4.0
	g.params.physics.gravity_constant = 1.0

	accel, r2 := game.physics_get_gravitational_acceleration(g, {0, 0}, 1.0, {0, 0}, 100.0, 1.0)

	testing.expect_value(t, accel.x, 0.0)
	testing.expect_value(t, accel.y, 0.0)
	testing.expect_value(t, r2, 0.0)
}

@(test)
test_gravity_proportional_to_mass :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	accel1, _ := game.physics_get_gravitational_acceleration(g, {0, 0}, 1.0, {10, 0}, 100.0, 1.0)

	accel2, _ := game.physics_get_gravitational_acceleration(g, {0, 0}, 1.0, {10, 0}, 200.0, 1.0)

	ratio := accel2.x / accel1.x
	testing.expect(t, math.abs(ratio - 2.0) < 1e-5, "Double source mass must double acceleration")
}

