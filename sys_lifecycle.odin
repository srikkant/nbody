package main

import "core:math"
import rl "vendor:raylib"

sys_lifecycle_init :: proc(g: ^Game) {
	g.events_count = 1
}

sys_lifecycle :: proc(g: ^Game) {
	delete_entities := [MAX_ENTITIES]bool{}
	delete_entities_count := 0

	mass_delta := [MAX_ENTITIES]f32{}

	g.total_objects = 0

	for i in 0 ..< g.events_count {
		switch &event in g.events[i] {
		case Game_Event_ObjectSpawn:
			id := entity_create(g)

			mass := event.density * event.radius * event.radius

			entity_add_mass(g, id, mass)
			entity_add_radius(g, id, event.radius)
			entity_add_position(g, id, {current = event.pos})
			entity_add_velocity(g, id, event.velocity)
			entity_add_energy_source(g, id, event.energy_source)

			entity_add_life(g, id, {g.elapsed})
			entity_add_renderable(g, id, {})
			entity_add_tags(g, id, event.tags)
			entity_add_emitter(g, id, event.emitter)
			entity_add_celestial(g, id, event.celestial)

			if event.show_trail {
				entity_add_position_trail(g, id, {})
			}

		case Game_Event_Collision:
			// Handle collision event
			e1 := &g.entities[event.id1]
			e2 := &g.entities[event.id2]
			merge := true

			// Skip if either entity is marked for deletion
			if delete_entities[event.id1] || delete_entities[event.id2] {
				continue
			}

			// Stars do not get deleted on collision
			if e1.celestial.type != .Star {
				delete_entities[event.id1] = true
			} else {
				merge = false
				mass_delta[event.id1] += e2.mass
			}

			if e2.celestial.type != .Star {
				delete_entities[event.id2] = true
			} else {
				merge = false
				mass_delta[event.id2] += e1.mass
			}

			if merge {
				// create a new entity
				id := entity_create(g)
				mass := (e1.mass + e2.mass)
				radius := math.sqrt(e1.radius * e1.radius + e2.radius * e2.radius)

				vel_x := (e1.mass * e1.velocity.x + e2.mass * e2.velocity.x) / mass
				vel_y := (e1.mass * e1.velocity.y + e2.mass * e2.velocity.y) / mass
				vel := rl.Vector2{vel_x, vel_y}

				speed := rl.Vector2Length(vel)
				tangent := rl.Vector2Normalize(rl.Vector2{-e1.pos.current.y, e1.pos.current.x})
				if rl.Vector2DotProduct(tangent, vel) < 0 {
					tangent = rl.Vector2{-tangent.x, -tangent.y}
				}

				scaled_vel := tangent * speed
				created_at := math.min(e1.life.created_at, e2.life.created_at)

				entity_add_mass(g, id, mass)
				entity_add_radius(g, id, radius)
				entity_add_position(
					g,
					id,
					{current = e1.mass > e2.mass ? e1.pos.current : e2.pos.current},
				)
				entity_add_renderable(g, id, {})
				entity_add_velocity(g, id, scaled_vel)
				entity_add_life(g, id, {created_at})
				entity_add_celestial(g, id, {.DwarfPlanet})
				entity_add_position_trail(g, id, e1.mass > e2.mass ? e1.trail : e2.trail)
			}

		case Game_Event_ObjectOutOfBounds:
			delete_entities[event.id] = true
			delete_entities_count += 1

		case Game_Event_ObjectDestroyed:
			delete_entities[event.id] = true
			delete_entities_count += 1
		}
	}

	g.events_count = 0

	for i in 0 ..< MAX_ENTITIES {
		// TODO: Spawn an explosion here
		if delete_entities[i] {
			entity_free(g, Entity(i))
			continue
		}

		e := &g.entities[i]

		if mass_delta[i] > 0 {
			mass_delta[i] = mass_delta[i]
			e.mass += mass_delta[i]
			// Increase radius proportionally
			e.radius += e.radius * (mass_delta[i] / e.mass)
		}

		// Count non-star physics objects
		if PHYSICS_SIG <= e.sig && e.celestial.type != .Star {
			g.total_objects += 1
		}
	}
}
