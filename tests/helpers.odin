package tests

import game "../game"
import "core:math"
import rl "vendor:raylib"

make_test_game :: proc() -> ^game.Game {
	g := new(game.Game)
	game.params_init(&g.params)
	game.theme_init(&g.theme)
	return g
}

free_test_game :: proc(g: ^game.Game) {
	free(g)
}

add_test_entity :: proc(
	g: ^game.Game,
	type: game.CelestialType,
	mass: f32,
	pos: rl.Vector2,
	vel: rl.Vector2,
) -> game.Entity {
	id := game.entity_create(g)

	game.entity_add_mass(g, id, mass)

	density := g.params.celestials[type].density
	radius: f32 = 1.0
	if density > 0 {
		radius = math.sqrt(mass / density)
	} else {
		radius = g.params.celestials[type].radius
	}

	game.entity_add_radius(g, id, radius)
	game.entity_add_position(g, id, {current = pos})
	game.entity_add_velocity(g, id, {current = vel})
	game.entity_add_celestial(g, id, {type = type})
	game.entity_add_life(g, id, {created_at = g.elapsed})

	return id
}

add_test_star :: proc(g: ^game.Game, mass: f32, pos: rl.Vector2) -> game.Entity {
	return add_test_entity(g, .Star, mass, pos, rl.Vector2{0, 0})
}

