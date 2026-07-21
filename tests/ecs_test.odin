package tests

import game "../game"
import "core:testing"

@(test)
test_entity_create_free_reuses_id :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	id1 := game.entity_create(g)
	game.entity_add_position(g, id1, {})
	testing.expect(t, g.entities_count == 1)

	game.entity_free(g, id1)
	testing.expect(t, g.entities[id1].sig == {})
	testing.expect(t, g.free_entities_count == 1)

	id2 := game.entity_create(g)
	testing.expect(t, id2 == id1, "freed id should be reused")
	testing.expect(t, g.entities_count == 1)
	testing.expect(t, g.free_entities_count == 0)
}

@(test)
test_celestial_next_type :: proc(t: ^testing.T) {
	testing.expect(t, game.entity_celestial_next_type(.Asteroid) == .Moonlet)
	testing.expect(t, game.entity_celestial_next_type(.DwarfPlanet) == .SubEarth)
	testing.expect(t, game.entity_celestial_next_type(.None) == .None)
	testing.expect(t, game.entity_celestial_next_type(.Star) == .Star, "star is the ceiling")
}

@(test)
test_celestial_prev_type :: proc(t: ^testing.T) {
	testing.expect(t, game.entity_celestial_prev_type(.Moonlet) == .Asteroid)
	testing.expect(t, game.entity_celestial_prev_type(.Asteroid) == .Asteroid, "floors at asteroid")
	testing.expect(t, game.entity_celestial_prev_type(.GiantPlanet, 2) == .SubNeptune)
	testing.expect(t, game.entity_celestial_prev_type(.None) == .None)
}

@(test)
test_celestial_is_unlockable :: proc(t: ^testing.T) {
	testing.expect(t, game.entity_celestial_is_unlockable(.Asteroid))
	testing.expect(t, game.entity_celestial_is_unlockable(.SuperJupiter))
	testing.expect(t, !game.entity_celestial_is_unlockable(.Star))
	testing.expect(t, !game.entity_celestial_is_unlockable(.None))
}
