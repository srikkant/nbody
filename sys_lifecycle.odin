package main

import "core:math"
import rl "vendor:raylib"

Game_Event_CollisionType :: enum {
	StarAbsorb,
	Merge,
	Shatter,
	Debris,
}

delete_entities: [MAX_ENTITIES]bool
mass_delta: [MAX_ENTITIES]f32

sys_lifecycle_init :: proc(g: ^Game) {
	g.events_count = 0
}

sys_lifecycle_spawn_fragments :: proc(g: ^Game, energy: f64, rel_speed: f32, pos: rl.Vector2) {
	frag_count := math.max(6, 3 + int(math.mod_f32(rel_speed * 0.7, 4.0)))
	frag_energy_each := energy / f64(frag_count)

	frag_radius := ENERGY_FRAGMENT_SIZE + f32(math.min(energy / 100, 10))

	for f in 0 ..< frag_count {
		angle := (math.PI * 2.0 * f32(f)) / f32(frag_count) + math.PI / f32(frag_count)
		spread := rel_speed * 0.15
		vel := rl.Vector2{math.cos(angle) * spread, math.sin(angle) * spread}

		id := entity_create(g)
		offset := rl.Vector2{pos.x + math.cos(angle), pos.y + math.sin(angle)}

		entity_add_position(g, id, {current = offset})
		// TODO: change radius based on mass
		entity_add_radius(g, id, frag_radius)
		entity_add_life(g, id, {g.elapsed})
		entity_add_renderable(g, id, {})
		entity_add_collectible_energy(g, id, {energy = frag_energy_each})
	}
}

sys_lifecycle_handle_spawn :: proc(g: ^Game, event: ^Game_Event_ObjectSpawn) {
	id := entity_create(g)

	mass := event.density * event.radius * event.radius

	entity_add_mass(g, id, mass)
	entity_add_radius(g, id, event.radius)
	entity_add_position(g, id, {current = event.pos})
	entity_add_velocity(g, id, {current = event.velocity})
	entity_add_energy_source(g, id, event.energy_source)

	entity_add_life(g, id, {g.elapsed})
	entity_add_renderable(g, id, event.renderable)
	entity_add_tags(g, id, event.tags)
	entity_add_emitter(g, id, event.emitter)
	entity_add_celestial(g, id, event.celestial)

	if event.show_trail {
		entity_add_position_trail(g, id, {})
	}
}

sys_lifecycle_collision_classify :: proc(
	g: ^Game,
	e: ^Game_Event_Collision,
) -> Game_Event_CollisionType {
	e1 := &g.entities[e.id1]
	e2 := &g.entities[e.id2]

	if e1.celestial.type == .Star || e2.celestial.type == .Star do return .StarAbsorb
	if e1.celestial.type != e2.celestial.type do return .Debris

	mass_ratio := math.max(e1.mass, e2.mass) / math.min(e2.mass, e1.mass)
	if mass_ratio > g.params.k_collision_mass_scale do return .Debris

	shatter_threshold_sq :=
		g.params.k_shatter_base * ((e1.mass + e2.mass) / math.max(e1.radius + e2.radius, 1.0))

	rel_speed_sq := rl.Vector2LengthSqr(e1.velocity.current - e2.velocity.current)
	if rel_speed_sq > shatter_threshold_sq do return .Shatter

	return .Merge
}

sys_lifecycle_resolve_merge :: proc(g: ^Game, e: ^Game_Event_Collision) {
	delete_entities[e.id1] = true
	delete_entities[e.id2] = true

	e1 := &g.entities[e.id1]
	e2 := &g.entities[e.id2]

	// TODO: If the new type is a star, we should rethink this.
	new_type := entity_celestial_next_type(e1.celestial.type)
	new_mass := e1.mass + e2.mass
	new_density := g.params.densities[new_type]
	new_radius := physics_radius_from_mass_density(new_mass, new_density)

	vel_x := (e1.mass * e1.velocity.current.x + e2.mass * e2.velocity.current.x) / new_mass
	vel_y := (e1.mass * e1.velocity.current.y + e2.mass * e2.velocity.current.y) / new_mass
	new_vel := rl.Vector2{vel_x, vel_y}

	pos := (e1.pos.current + e2.pos.current) * 0.5

	id := entity_create(g)

	entity_add_mass(g, id, new_mass)
	entity_add_radius(g, id, new_radius)
	entity_add_position(g, id, {current = pos})
	entity_add_velocity(g, id, {current = new_vel})
	entity_add_life(g, id, {g.elapsed})
	entity_add_renderable(g, id, {e1.renderable.color})
	entity_add_celestial(g, id, {new_type})
	entity_add_position_trail(g, id, {})

	if entity_celestial_is_unlockable(new_type) {
		g.available_objects += {new_type}
	}
}

sys_lifecycle_resolve_shatter :: proc(g: ^Game, e: ^Game_Event_Collision) {
	delete_entities[e.id1] = true
	delete_entities[e.id2] = true

	e1 := &g.entities[e.id1]
	e2 := &g.entities[e.id2]

	rel_speed := rl.Vector2Length(e1.velocity.current - e2.velocity.current)
	impact_point := (e1.pos.current + e2.pos.current) * 0.5

	sys_lifecycle_spawn_fragments(g, f64(e1.mass + e2.mass) * 0.5, rel_speed, impact_point)
}

sys_lifecycle_resolve_debris :: proc(g: ^Game, e: ^Game_Event_Collision) {
	e1 := &g.entities[e.id1]
	e2 := &g.entities[e.id2]

	big_id := e.id1
	small_id := e.id2
	big_mass := e1.mass
	small_mass := e2.mass
	big_type := e1.celestial.type
	big_pos := e1.pos.current
	big_vel := e1.velocity.current
	big_radius := e1.radius

	if e2.mass > e1.mass {
		big_id = e.id2
		small_id = e.id1
		big_mass = e2.mass
		small_mass = e1.mass
		big_type = e2.celestial.type
		big_pos = e2.pos.current
		big_vel = e2.velocity.current
		big_radius = e2.radius
	}

	delete_entities[small_id] = true

	rel_speed := rl.Vector2Length(e1.velocity.current - e2.velocity.current)
	loss := math.min(big_mass * 0.4, small_mass * (g.params.k_debris_mass_loss + rel_speed * 0.01))
	remaining_mass := big_mass - loss

	e_big := &g.entities[big_id]
	e_big.celestial.type = entity_celestial_prev_type(big_type)
	e_big.mass = remaining_mass

	new_density := g.params.densities[e_big.celestial.type]
	e_big.radius = physics_radius_from_mass_density(remaining_mass, new_density)

	sys_lifecycle_spawn_fragments(g, f64(remaining_mass), rel_speed, big_pos)
}

sys_lifecycle_handle_star_absorb :: proc(g: ^Game, e: ^Game_Event_Collision) {
	star_id := e.id1
	other_id := e.id2
	other_mass := g.entities[e.id2].mass

	if g.entities[e.id2].celestial.type == .Star {
		star_id = e.id2
		other_id = e.id1
		other_mass = g.entities[e.id1].mass
	}

	delete_entities[other_id] = true
	absorbed := other_mass * g.params.k_mass_loss
	mass_delta[star_id] += absorbed
}

sys_lifecycle_handle_collision :: proc(g: ^Game, event: ^Game_Event_Collision) {
	if delete_entities[event.id1] || delete_entities[event.id2] {
		return
	}

	classification := sys_lifecycle_collision_classify(g, event)

	switch classification {
	case .StarAbsorb:
		sys_lifecycle_handle_star_absorb(g, event)
	case .Merge:
		sys_lifecycle_resolve_merge(g, event)
	case .Shatter:
		sys_lifecycle_resolve_shatter(g, event)
	case .Debris:
		sys_lifecycle_resolve_debris(g, event)
	}
}

sys_lifecycle_handle_out_of_bounds :: proc(g: ^Game, event: ^Game_Event_ObjectOutOfBounds) {
	e := &g.entities[event.id]
	if e.celestial.type != .Star && e.mass > 0 {
		refund := f64(g.params.k_out_of_bounds_refund * e.mass * e.radius)
		g.energy += refund
	}
	delete_entities[event.id] = true
}

sys_lifecycle_handle_destroyed :: proc(g: ^Game, event: ^Game_Event_ObjectDestroyed) {
	delete_entities[event.id] = true
}

sys_lifecycle_handle_fragments :: proc(g: ^Game) {
	cursor := &g.mouse_pos

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if delete_entities[i] do continue
		if !(.CollectibleEnergy in e.sig) do continue

		dx := cursor.x - e.pos.current.x
		dy := cursor.y - e.pos.current.y
		dist_sq := dx * dx + dy * dy

		if dist_sq < g.params.k_collect_dist_sq {
			g.energy += e.collectible_energy.energy
			delete_entities[i] = true
		}
	}
}

sys_lifecycle_update_entities :: proc(g: ^Game) {
	for i in 0 ..< MAX_ENTITIES {
		if delete_entities[i] {
			entity_free(g, Entity(i))
			delete_entities[i] = false
			continue
		}

		e := &g.entities[i]

		if mass_delta[i] > 0 {
			e.mass += mass_delta[i]
			if e.celestial.type == .Star {
				star_density := g.params.densities[.Star]
				e.radius = physics_radius_from_mass_density(e.mass, star_density)
				e.energy_source.output = f32(g.params.k_star_energy_scale * e.mass)
			} else {
				e.radius = physics_radius_from_mass_density(
					e.mass,
					g.params.densities[e.celestial.type],
				)
			}
			mass_delta[i] = 0
		}

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

	sys_lifecycle_handle_fragments(g)

	g.total_objects = 0
	g.events_count = 0

	sys_lifecycle_update_entities(g)
}
