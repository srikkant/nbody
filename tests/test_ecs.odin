package tests

import game "../game"
import "core:testing"

@(test)
test_entity_create_sequential :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := game.entity_create(g)
	id2 := game.entity_create(g)
	id3 := game.entity_create(g)

	testing.expect_value(t, id1, game.Entity(0))
	testing.expect_value(t, id2, game.Entity(1))
	testing.expect_value(t, id3, game.Entity(2))
}

@(test)
test_entity_free_and_reuse :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id1 := game.entity_create(g)
	id2 := game.entity_create(g)

	game.entity_free(g, id1)
	testing.expect_value(t, g.free_entities_count, 1)
	testing.expect_value(t, g.free_entities[0], id1)

	id3 := game.entity_create(g)
	testing.expect_value(t, id3, id1)
	testing.expect_value(t, g.free_entities_count, 0)
}

@(test)
test_entity_free_clears_signature :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id := game.entity_create(g)
	game.entity_add_position(g, id, {current = {10, 10}})
	testing.expect(t, .Position in g.entities[id].sig, "Should have Position component")

	game.entity_free(g, id)
	testing.expect(t, g.entities[id].sig == {}, "Signature must be empty after free")
}

@(test)
test_entity_add_mass_zero_guard :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id := game.entity_create(g)
	game.entity_add_mass(g, id, 0.0)
	testing.expect(t, !(.Mass in g.entities[id].sig), "Should not add Mass if value is 0")

	game.entity_add_mass(g, id, 5.0)
	testing.expect(t, .Mass in g.entities[id].sig, "Should add Mass if value > 0")
}

@(test)
test_entity_add_radius_zero_guard :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id := game.entity_create(g)
	game.entity_add_radius(g, id, 0.0)
	testing.expect(t, !(.Radius in g.entities[id].sig), "Should not add Radius if value is 0")

	game.entity_add_radius(g, id, 2.5)
	testing.expect(t, .Radius in g.entities[id].sig, "Should add Radius if value > 0")
}

@(test)
test_entity_add_energy_source_zero_output_guard :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id := game.entity_create(g)
	game.entity_add_energy_source(g, id, {output = 0.0})
	testing.expect(
		t,
		!(.EnergySource in g.entities[id].sig),
		"Should not add EnergySource if output is 0",
	)

	game.entity_add_energy_source(g, id, {output = 10.0})
	testing.expect(t, .EnergySource in g.entities[id].sig, "Should add EnergySource if output > 0")
}

@(test)
test_entity_add_emitter_zero_cost_guard :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id := game.entity_create(g)
	game.entity_add_emitter(g, id, {base_cost = 0.0})
	testing.expect(
		t,
		!(.Emitter in g.entities[id].sig),
		"Should not add Emitter if base_cost is 0",
	)

	game.entity_add_emitter(g, id, {base_cost = 100.0})
	testing.expect(t, .Emitter in g.entities[id].sig, "Should add Emitter if base_cost > 0")
}

@(test)
test_entity_add_collectible_negative_guard :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	id := game.entity_create(g)
	game.entity_add_collectible_energy(g, id, {energy = 0.0})
	testing.expect(
		t,
		!(.CollectibleEnergy in g.entities[id].sig),
		"Should not add CollectibleEnergy if energy <= 0",
	)

	game.entity_add_collectible_energy(g, id, {energy = -5.0})
	testing.expect(
		t,
		!(.CollectibleEnergy in g.entities[id].sig),
		"Should not add CollectibleEnergy if energy <= 0",
	)

	game.entity_add_collectible_energy(g, id, {energy = 25.0})
	testing.expect(
		t,
		.CollectibleEnergy in g.entities[id].sig,
		"Should add CollectibleEnergy if energy > 0",
	)
}
