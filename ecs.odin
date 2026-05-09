package main

entity_create :: proc(g: ^Game) -> Entity {
	id: Entity

	if g.free_entities_count > 0 {
		g.free_entities_count -= 1
		id = g.free_entities[g.free_entities_count]
	} else {
		id = Entity(g.entities_count)
		g.entities_count += 1
	}

	g.entities[id].sig = {}

	return id
}

entity_free :: proc(g: ^Game, id: Entity) {
	g.entities.sig[id] = {}
	g.free_entities[g.free_entities_count] = id
	g.free_entities_count += 1
}

entity_add_position :: proc(g: ^Game, id: Entity, pos: PositionComponent) {
	g.entities[id].pos = pos
	g.entities[id].sig += {.Position}
}

entity_add_size :: proc(g: ^Game, id: Entity, size: SizeComponent) {
	g.entities[id].size = size
	g.entities[id].sig += {.Size}
}

entity_add_velocity :: proc(g: ^Game, id: Entity, vel: VelocityComponent) {
	g.entities[id].vel = vel
	g.entities[id].sig += {.Velocity}
}

entity_add_position_trail :: proc(g: ^Game, id: Entity, trail: PositionTrailComponent) {
	g.entities[id].trail = trail
	g.entities[id].sig += {.PositionTrail}
}

entity_add_energy_source :: proc(g: ^Game, id: Entity, energy_source: EnergySourceComponent) {
	if energy_source.output == 0 {
		return
	}

	g.entities[id].energy_source = energy_source
	g.entities[id].sig += {.EnergySource}
}

entity_add_life :: proc(g: ^Game, id: Entity, life: LifeComponent) {
	g.entities[id].life = life
	g.entities[id].sig += {.Life}
}

entity_add_emitter :: proc(g: ^Game, id: Entity, emitter: EmitterComponent) {
	g.entities[id].emitter = emitter
	g.entities[id].sig += {.Emitter}
}

entity_add_renderable :: proc(g: ^Game, id: Entity, renderable: RenderableComponent) {
	g.entities[id].renderable = renderable
	g.entities[id].sig += {.Renderable}
}

entity_add_tags :: proc(g: ^Game, id: Entity, tags: Signature) {
	g.entities[id].sig += tags
}
