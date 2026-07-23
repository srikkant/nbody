package game

import "core:math"
import rl "vendor:raylib"

Game_Event_CollisionType :: enum {
	StarAbsorb,
	Merge,
	Shatter,
	Debris,
}

sys_lifecycle_spawn_fragments :: proc(g: ^Game, energy: f64, rel_speed: f32, pos: rl.Vector2) {
	frag_count := int(
		ENERGY_FRAGMENTS_COUNT_BASE + rel_speed * ENERGY_FRAGMENTS_COUNT_SPEED_FACTOR,
	)
	frag_count = int(
		clamp(f32(frag_count), f32(ENERGY_FRAGMENTS_COUNT_MIN), f32(ENERGY_FRAGMENTS_COUNT_MAX)),
	)
	frag_energy_each := energy / f64(frag_count)

	for f in 0 ..< frag_count {
		angle := (math.PI * 2.0 * f32(f)) / f32(frag_count) + math.PI / f32(frag_count)
		id := entity_create(g)
		offset := rl.Vector2 {
			pos.x + math.cos(angle) * ENERGY_FRAGMENTS_SPREAD_RADIUS,
			pos.y + math.sin(angle) * ENERGY_FRAGMENTS_SPREAD_RADIUS,
		}

		entity_add_position(g, id, {current = offset})
		entity_add_radius(g, id, ENERGY_FRAGMENTS_SIZE)
		entity_add_life(g, id, {created_at = g.elapsed})
		entity_add_renderable(g, id, {})
		entity_add_collectible_energy(g, id, {energy = frag_energy_each})
	}
}

sys_lifecycle_spawn_shockwave :: proc(g: ^Game, pos: rl.Vector2, energy: f64, color: rl.Color) {
	if energy <= 0 do return

	id := entity_create(g)
	entity_add_position(g, id, {current = pos})
	entity_add_radius(g, id, SHOCKWAVE_RADIUS_START)

	dur := clamp(
		f32(SHOCKWAVE_DURATION_BASE_SEC) + 0.12 * math.ln(f32(energy + 1.0)),
		f32(SHOCKWAVE_DURATION_MIN_SEC),
		f32(SHOCKWAVE_DURATION_MAX_SEC),
	)
	entity_add_life(g, id, {created_at = g.elapsed, remaining = Timer{interval = dur}})
	entity_add_shockwave(
		g,
		id,
		{
			growth_rate = math.min(
				math.ln(f32(energy) + 1.0) * SHOCKWAVE_GROWTH_FACTOR,
				SHOCKWAVE_GROWTH_MAX,
			),
			color = color,
		},
	)
}

sys_lifecycle_handle_spawn :: proc(g: ^Game, event: ^GameEvent_ObjectSpawn) {
	id := entity_create(g)

	mass := physics_calculate_mass(event.density, event.radius)

	entity_add_mass(g, id, mass)
	entity_add_radius(g, id, event.radius)
	entity_add_position(g, id, {current = event.pos})
	entity_add_velocity(g, id, {current = event.velocity})
	entity_add_energy_source(g, id, event.energy_source)

	entity_add_life(g, id, {created_at = g.elapsed})
	entity_add_renderable(g, id, event.renderable)
	entity_add_emitter(g, id, event.emitter)
	entity_add_celestial(g, id, event.celestial)

	if event.show_orbit {
		if g.params.celestials[event.celestial.type].trail_multiplier > 0 {
			entity_add_orbit(g, id, {})
		}
	}
}

sys_lifecycle_collision_classify :: proc(
	g: ^Game,
	e: ^GameEvent_Collision,
) -> Game_Event_CollisionType {
	e1 := &g.entities[e.id1]
	e2 := &g.entities[e.id2]

	// Stars always absord the other entity
	if e1.celestial.type == .Star || e2.celestial.type == .Star do return .StarAbsorb
	// For now, different celestial types result in debris
	if e1.celestial.type != e2.celestial.type do return .Debris
	// Same celestial types will result in shatter or merge depending on
	// relative velocity
	shatter_threshold_sq :=
		g.params.physics.collision_shatter_threshold_factor *
		(e1.mass + e2.mass) /
		(e1.radius + e2.radius)

	rel_speed_sq := math_vec2_length_sq(e1.velocity.current - e2.velocity.current)
	if rel_speed_sq > shatter_threshold_sq do return .Shatter

	return .Merge
}

sys_lifecycle_resolve_merge :: proc(g: ^Game, e: ^GameEvent_Collision) {
	g.delete_entities[e.id1] = true
	g.delete_entities[e.id2] = true

	e1 := &g.entities[e.id1]
	e2 := &g.entities[e.id2]

	// TODO: If the new type is a star, we should rethink this.
	new_type := entity_celestial_next_type(e1.celestial.type)
	new_mass := e1.mass + e2.mass
	new_density := g.params.celestials[new_type].density
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
	entity_add_life(g, id, {created_at = g.elapsed})
	entity_add_renderable(g, id, {g.params.celestials[new_type].color})
	entity_add_celestial(g, id, {new_type})
	if g.params.celestials[new_type].trail_multiplier > 0 {
		entity_add_orbit(g, id, {})
	}

	sys_lifecycle_spawn_shockwave(g, pos, f64(new_mass), g.params.celestials[new_type].color)

	if entity_celestial_is_unlockable(new_type) {
		g.slingshot.available_objects += {new_type}
	}
}

sys_lifecycle_resolve_shatter :: proc(g: ^Game, e: ^GameEvent_Collision) {
	g.delete_entities[e.id1] = true
	g.delete_entities[e.id2] = true

	e1 := &g.entities[e.id1]
	e2 := &g.entities[e.id2]

	rel_speed := math_vec2_length(e1.velocity.current - e2.velocity.current)
	impact_point := (e1.pos.current + e2.pos.current) * 0.5

	mass := f64(e1.mass + e2.mass) * 0.5
	energy := mass * f64(rel_speed * rel_speed)

	sys_lifecycle_spawn_fragments(g, mass, rel_speed, impact_point)
	sys_lifecycle_spawn_shockwave(g, e1.pos.current, energy, e1.renderable.color)
}

sys_lifecycle_resolve_debris :: proc(g: ^Game, e: ^GameEvent_Collision) {
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

	g.delete_entities[small_id] = true

	rel_speed := math_vec2_length(e1.velocity.current - e2.velocity.current)
	loss := small_mass * (rel_speed * g.params.physics.collision_mass_loss_factor)
	remaining_mass := big_mass - loss

	e_big := &g.entities[big_id]
	e_big.celestial.type = entity_celestial_prev_type(big_type)
	e_big.mass = remaining_mass

	new_density := g.params.celestials[e_big.celestial.type].density
	e_big.radius = physics_radius_from_mass_density(remaining_mass, new_density)

	energy_loss := f64(loss) * f64(rel_speed * rel_speed)

	sys_lifecycle_spawn_fragments(g, f64(loss), rel_speed, big_pos)
	sys_lifecycle_spawn_shockwave(g, e1.pos.current, energy_loss, e_big.renderable.color)
}

sys_lifecycle_handle_star_absorb :: proc(g: ^Game, e: ^GameEvent_Collision) {
	star_id := e.id1
	other_id := e.id2
	other_mass := g.entities[e.id2].mass

	if g.entities[e.id2].celestial.type == .Star {
		star_id = e.id2
		other_id = e.id1
		other_mass = g.entities[e.id1].mass
	}

	g.delete_entities[other_id] = true
	absorbed := other_mass * g.params.physics.mass_absorb_factor
	g.mass_delta[star_id] += absorbed
}

sys_lifecycle_handle_collision :: proc(g: ^Game, event: ^GameEvent_Collision) {
	if g.delete_entities[event.id1] || g.delete_entities[event.id2] {
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

sys_lifecycle_handle_out_of_bounds :: proc(g: ^Game, event: ^GameEvent_Object_OutOfBounds) {
	e := &g.entities[event.id]
	if e.celestial.type != .Star && e.mass > 0 {
		refund := f64(g.params.physics.energy_refund_factor * e.mass * e.radius)
		g.score.energy += refund
	}
	g.delete_entities[event.id] = true
}

sys_lifecycle_handle_demolish :: proc(g: ^Game, event: ^GameEvent_Object_Demolish) {
	closest_id: Entity_Id
	closest_dist := f32(1e9)
	found := false

	for i in 0 ..< g.entities_count {
		if g.delete_entities[i] do continue
		e := &g.entities[i]
		if PHYSICS_SIG <= e.sig && e.celestial.type != .Star {
			dist := rl.Vector2Distance(e.pos.current, g.input.mouse_pos)
			click_radius := g.params.physics.cursor_distance

			if dist <= click_radius && dist < closest_dist {
				closest_dist = dist
				closest_id = Entity_Id(i)
				found = true
			}
		}
	}

	if found {
		e := &g.entities[closest_id]
		if e.mass > 0 {
			refund := f64(g.params.physics.energy_refund_factor * e.mass * e.radius)
			g.score.energy += refund
			sys_lifecycle_spawn_shockwave(g, e.pos.current, f64(e.mass), e.renderable.color)
		}
		g.delete_entities[closest_id] = true
	}
}

sys_lifecycle_handle_destroyed :: proc(g: ^Game, event: ^GameEvent_Object_Destroyed) {
	g.delete_entities[event.id] = true
}

sys_lifecycle_handle_fragments :: proc(g: ^Game) {
	cursor := &g.input.mouse_pos

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if g.delete_entities[i] do continue

		if !(.CollectibleEnergy in e.sig) do continue

		dx := cursor.x - e.pos.current.x
		dy := cursor.y - e.pos.current.y
		dist_sq := dx * dx + dy * dy

		t := g.elapsed + f32(i)
		e.pos.current.x +=
			math.cos(t * ENERGY_FRAGMENTS_DRIFT_FREQUENCY_X) *
			ENERGY_FRAGMENTS_DRIFT_AMPLITUDE_X *
			f32(g.dt)
		e.pos.current.y +=
			math.sin(t * ENERGY_FRAGMENTS_DRIFT_FREQUENCY_Y) *
			ENERGY_FRAGMENTS_DRIFT_AMPLITUDE_Y *
			f32(g.dt)

		if dist_sq < g.params.physics.cursor_distance_squared {
			g.score.energy += e.collectible_energy.energy
			g.delete_entities[i] = true
		}
	}
}

sys_lifecycle_update_entities :: proc(g: ^Game) {
	dt := g.dt

	for i in 0 ..< MAX_ENTITIES {
		e := &g.entities[i]

		if g.delete_entities[i] {
			entity_free(g, Entity_Id(i))
			g.delete_entities[i] = false
			continue
		}

		if .Life in e.sig && e.life.remaining.interval != 0 {
			math_update_timer(&e.life.remaining, dt)
			if e.life.remaining.done {
				entity_free(g, Entity_Id(i))
				continue
			}
		}

		if .Shockwave in e.sig {
			age := e.life.remaining.interval - e.life.remaining.curr
			progress := age / e.life.remaining.interval
			scale := SHOCKWAVE_DECEL_START - SHOCKWAVE_DECEL_DECAY * progress
			e.radius += e.shockwave.growth_rate * scale * dt
		}

		if PHYSICS_SIG <= e.sig {
			g.score.total_objects += 1
		}

		if g.mass_delta[i] > 0 {
			density := g.params.celestials[e.celestial.type].density
			e.mass += g.mass_delta[i]
			e.radius = physics_radius_from_mass_density(e.mass, density)

			if ENERGY_SOURCE_SIG <= e.sig {
				e.energy_source.output = f32(g.params.physics.energy_source_gain_factor * e.mass)
			}

			g.mass_delta[i] = 0
		}

	}
}

sys_lifecycle :: proc(g: ^Game) {
	for i in 0 ..< g.events_count {
		switch &event in g.events[i] {
		case GameEvent_ObjectSpawn:
			sys_lifecycle_handle_spawn(g, &event)
		case GameEvent_Collision:
			sys_lifecycle_handle_collision(g, &event)
		case GameEvent_Object_OutOfBounds:
			sys_lifecycle_handle_out_of_bounds(g, &event)
		case GameEvent_Object_Destroyed:
			sys_lifecycle_handle_destroyed(g, &event)
		case GameEvent_Object_Demolish:
			sys_lifecycle_handle_demolish(g, &event)
		}
	}

	sys_lifecycle_handle_fragments(g)

	g.score.total_objects = 0
	g.events_count = 0

	sys_lifecycle_update_entities(g)
}
