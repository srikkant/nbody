package main

import "core:math"
import rl "vendor:raylib"

delete_entities: [MAX_ENTITIES]bool
mass_delta: [MAX_ENTITIES]f32

sys_lifecycle_init :: proc(g: ^Game) {
	g.events_count = 1
}

sys_lifecycle_handle_spawn :: proc(g: ^Game, event: ^Game_Event_ObjectSpawn) {
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
}

sys_lifecycle_handle_collision :: proc(g: ^Game, event: ^Game_Event_Collision) {
	// Handle collision event
	e1 := &g.entities[event.id1]
	e2 := &g.entities[event.id2]

	// Skip if either entity is marked for deletion
	if delete_entities[event.id1] || delete_entities[event.id2] {
		return
	}

	// if either is a star, delete the other
	if e1.celestial.type == .Star {
		delete_entities[event.id2] = true
		mass_delta[event.id1] += g.entities[event.id2].mass * g.params.k_mass_loss
		return
	}

	if e2.celestial.type == .Star {
		delete_entities[event.id1] = true
		mass_delta[event.id2] += g.entities[event.id1].mass * g.params.k_mass_loss
		return
	}

	rel_vel := e1.velocity - e2.velocity
	speed := rl.Vector2Length(rel_vel)

	// Merge the two entities
	if speed < g.params.k_shatter_speed {
		delete_entities[event.id1] = true
		delete_entities[event.id2] = true

		id := entity_create(g)
		mass := (e1.mass + e2.mass)
		radius := math.sqrt(e1.radius * e1.radius + e2.radius * e2.radius)

		vel_x := (e1.mass * e1.velocity.x + e2.mass * e2.velocity.x) / mass
		vel_y := (e1.mass * e1.velocity.y + e2.mass * e2.velocity.y) / mass
		vel := rl.Vector2{vel_x, vel_y}

		new_speed := rl.Vector2Length(vel)
		tangent := rl.Vector2Normalize(rl.Vector2{-e1.pos.current.y, e1.pos.current.x})
		if rl.Vector2DotProduct(tangent, vel) < 0 {
			tangent = rl.Vector2{-tangent.x, -tangent.y}
		}

		scaled_vel := tangent * new_speed
		created_at := math.min(e1.life.created_at, e2.life.created_at)

		entity_add_mass(g, id, mass)
		entity_add_radius(g, id, radius)
		entity_add_position(g, id, {current = e1.mass > e2.mass ? e1.pos.current : e2.pos.current})
		entity_add_renderable(g, id, {})
		entity_add_velocity(g, id, scaled_vel)
		entity_add_life(g, id, {created_at})
		entity_add_celestial(g, id, {.DwarfPlanet})
		entity_add_position_trail(g, id, e1.mass > e2.mass ? e1.trail : e2.trail)

		return
	}

	// One entity is much bigger than the other
	if e1.mass / e2.mass > g.params.k_collision_mass_scale {
		delete_entities[event.id2] = true
		return
	}

	if e2.mass / e1.mass > g.params.k_collision_mass_scale {
		delete_entities[event.id1] = true
		return
	}

	// if both entities are of similar sizes and their speed is greater than shatter speed,
	// delete both entities and spawn an explosion
	delete_entities[event.id1] = true
	delete_entities[event.id2] = true
}

sys_lifecycle_handle_out_of_bounds :: proc(g: ^Game, event: ^Game_Event_ObjectOutOfBounds) {
	delete_entities[event.id] = true
}

sys_lifecycle_handle_destroyed :: proc(g: ^Game, event: ^Game_Event_ObjectDestroyed) {
	delete_entities[event.id] = true
}

sys_lifecycle_update_entities :: proc(g: ^Game) {
	for i in 0 ..< MAX_ENTITIES {
		// TODO: Spawn an explosion here
		if delete_entities[i] {
			entity_free(g, Entity(i))
			delete_entities[i] = false
			continue
		}

		e := &g.entities[i]

		if mass_delta[i] > 0 {
			e.mass += mass_delta[i]
			e.radius += e.radius * (mass_delta[i] / e.mass)
			mass_delta[i] = 0
		}

		// Count non-star physics objects
		if PHYSICS_SIG <= e.sig && e.celestial.type != .Star {
			g.total_objects += 1
		}
	}
}

sys_lifecycle :: proc(g: ^Game) {

	for i in 0 ..< g.events_count {
		switch &event in g.events[i] {
		case Game_Event_ObjectSpawn:
			sys_lifecycle_handle_spawn(g, &event)
		case Game_Event_Collision:
			sys_lifecycle_handle_collision(g, &event)
		case Game_Event_ObjectOutOfBounds:
			sys_lifecycle_handle_out_of_bounds(g, &event)
		case Game_Event_ObjectDestroyed:
			sys_lifecycle_handle_destroyed(g, &event)
		}
	}

	g.total_objects = 0
	g.events_count = 0

	sys_lifecycle_update_entities(g)
}
