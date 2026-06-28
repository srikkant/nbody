package tests

import game "../game"
import "core:math"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_classify_star_absorb_star_vs_asteroid :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_star(g, 1000.0, {0, 0})
	id2 := add_test_entity(g, .Asteroid, 5.0, {1, 0}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}
	class := game.sys_lifecycle_collision_classify(g, &e)

	testing.expect_value(t, class, game.Game_Event_CollisionType.StarAbsorb)
}

@(test)
test_classify_debris_different_types :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Asteroid, 5.0, {0, 0}, {0, 0})
	id2 := add_test_entity(g, .Moonlet, 5.0, {1, 0}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}
	class := game.sys_lifecycle_collision_classify(g, &e)

	testing.expect_value(t, class, game.Game_Event_CollisionType.Debris)
}


@(test)
test_classify_shatter_high_speed :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Asteroid, 5.0, {0, 0}, {50, 0})
	id2 := add_test_entity(g, .Asteroid, 5.0, {1, 0}, {-50, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}
	class := game.sys_lifecycle_collision_classify(g, &e)

	testing.expect_value(t, class, game.Game_Event_CollisionType.Shatter)
}

@(test)
test_classify_merge_same_type_low_speed :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Asteroid, 5.0, {0, 0}, {0.1, 0})
	id2 := add_test_entity(g, .Asteroid, 5.0, {1, 0}, {-0.1, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}
	class := game.sys_lifecycle_collision_classify(g, &e)

	testing.expect_value(t, class, game.Game_Event_CollisionType.Merge)
}

@(test)
test_classify_merge_boundary_mass_ratio :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Asteroid, 9.0, {0, 0}, {0, 0})
	id2 := add_test_entity(g, .Asteroid, 3.0, {1, 0}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}
	class := game.sys_lifecycle_collision_classify(g, &e)

	testing.expect_value(t, class, game.Game_Event_CollisionType.Merge)
}

@(test)
test_classify_shatter_threshold_formula :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.params.physics.collision_shatter_threshold_factor = 100.0

	id1 := add_test_entity(g, .Asteroid, 6.0, {0, 0}, {0, 0})
	id2 := add_test_entity(g, .Asteroid, 4.0, {0, 0}, {0, 0})

	r1 := g.entities[id1].radius
	r2 := g.entities[id2].radius

	expected_threshold := 100.0 * (6.0 + 4.0) / math.max(r1 + r2, 1.0)

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	g.entities[id1].velocity.current = {0, 0}
	g.entities[id2].velocity.current = {math.sqrt(expected_threshold) - 0.5, 0}
	class1 := game.sys_lifecycle_collision_classify(g, &e)
	testing.expect_value(t, class1, game.Game_Event_CollisionType.Merge)

	g.entities[id2].velocity.current = {math.sqrt(expected_threshold) + 0.5, 0}
	class2 := game.sys_lifecycle_collision_classify(g, &e)
	testing.expect_value(t, class2, game.Game_Event_CollisionType.Shatter)
}

@(test)
test_merge_conserves_mass :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Asteroid, 5.0, {0, 0}, {1, 0})
	id2 := add_test_entity(g, .Asteroid, 3.0, {2, 0}, {-1, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	before_count := g.entities_count
	game.sys_lifecycle_resolve_merge(g, &e)

	testing.expect(t, game.delete_entities[id1], "id1 must be deleted")
	testing.expect(t, game.delete_entities[id2], "id2 must be deleted")

	new_id := game.Entity_Id(before_count)
	testing.expect_value(t, g.entities[new_id].mass, f32(8.0))
}

@(test)
test_merge_conserves_momentum :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Asteroid, 6.0, {0, 0}, {2, 0})
	id2 := add_test_entity(g, .Asteroid, 4.0, {2, 0}, {-3, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	before_count := g.entities_count
	game.sys_lifecycle_resolve_merge(g, &e)

	new_id := game.Entity_Id(before_count)
	testing.expect_value(t, g.entities[new_id].velocity.current.x, f32(0.0))
}

@(test)
test_merge_promotes_type :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Asteroid, 5.0, {0, 0}, {0, 0})
	id2 := add_test_entity(g, .Asteroid, 5.0, {2, 0}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	before_count := g.entities_count
	game.sys_lifecycle_resolve_merge(g, &e)

	new_id := game.Entity_Id(before_count)
	testing.expect_value(t, g.entities[new_id].celestial.type, game.Celestial_Type.Moonlet)
}

@(test)
test_merge_unlocks_type :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.slingshot.available_objects = {.Asteroid}

	id1 := add_test_entity(g, .Asteroid, 5.0, {0, 0}, {0, 0})
	id2 := add_test_entity(g, .Asteroid, 5.0, {2, 0}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	game.sys_lifecycle_resolve_merge(g, &e)

	testing.expect(t, .Moonlet in g.slingshot.available_objects, "Moonlet must be unlocked")
}

@(test)
test_debris_bigger_survives :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Moonlet, 10.0, {0, 0}, {0, 0})
	id2 := add_test_entity(g, .Moonlet, 4.0, {2, 0}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	game.sys_lifecycle_resolve_debris(g, &e)

	testing.expect(t, game.delete_entities[id2], "id2 must be deleted")
	testing.expect(t, !game.delete_entities[id1], "id1 must survive")
}

@(test)
test_debris_mass_loss_formula :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.params.physics.collision_debris_max_loss_fraction = 0.5
	g.params.physics.debris_mass_loss_fraction = 0.1
	g.params.physics.collision_mass_loss_factor = 0.01

	id1 := add_test_entity(g, .Moonlet, 10.0, {0, 0}, {10, 0})
	id2 := add_test_entity(g, .Moonlet, 2.0, {2, 0}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	game.sys_lifecycle_resolve_debris(g, &e)

	testing.expect_value(t, g.entities[id1].mass, f32(9.6))
}

@(test)
test_debris_type_demotion :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Moonlet, 10.0, {0, 0}, {0, 0})
	id2 := add_test_entity(g, .Moonlet, 2.0, {2, 0}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	game.sys_lifecycle_resolve_debris(g, &e)

	testing.expect_value(t, g.entities[id1].celestial.type, game.Celestial_Type.Asteroid)
}

@(test)
test_shatter_both_destroyed :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_entity(g, .Asteroid, 5.0, {0, 0}, {100, 0})
	id2 := add_test_entity(g, .Asteroid, 5.0, {2, 0}, {-100, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	game.sys_lifecycle_resolve_shatter(g, &e)

	testing.expect(t, game.delete_entities[id1], "id1 must be deleted")
	testing.expect(t, game.delete_entities[id2], "id2 must be deleted")
}

@(test)
test_star_absorb_correct_entity :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := add_test_star(g, 1000.0, {0, 0})
	id2 := add_test_entity(g, .Asteroid, 10.0, {1, 1}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
		game.mass_delta[i] = 0.0
	}

	game.sys_lifecycle_handle_star_absorb(g, &e)

	testing.expect(t, game.delete_entities[id2], "Asteroid must be deleted")
	testing.expect(t, !game.delete_entities[id1], "Star must survive")
}

@(test)
test_star_absorb_absorbed_mass :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.params.physics.mass_absorb_factor = 0.85

	id1 := add_test_star(g, 1000.0, {0, 0})
	id2 := add_test_entity(g, .Asteroid, 100.0, {1, 1}, {0, 0})

	e := game.GameEvent_Collision {
		id1 = id1,
		id2 = id2,
	}

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
		game.mass_delta[i] = 0.0
	}

	game.sys_lifecycle_handle_star_absorb(g, &e)

	testing.expect_value(t, game.mass_delta[id1], f32(85.0))
}

@(test)
test_out_of_bounds_refund :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	g.score.energy = 0.0
	g.params.physics.energy_refund_factor = 0.5

	id := add_test_entity(g, .Asteroid, 10.0, {0, 0}, {0, 0})
	g.entities[id].radius = 2.0

	for i in 0 ..< game.MAX_ENTITIES {
		game.delete_entities[i] = false
	}

	e := game.GameEvent_Object_OutOfBounds {
		id = id,
	}
	game.sys_lifecycle_handle_out_of_bounds(g, &e)

	testing.expect_value(t, g.score.energy, f64(10.0))
	testing.expect(t, game.delete_entities[id], "Out of bounds entity must be deleted")
}
