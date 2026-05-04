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

entity_add_life :: proc(g: ^Game, id: Entity, life: LifeComponent) {
	g.entities[id].life = life
	g.entities[id].sig += {.Life}
}

entity_add_renderable :: proc(g: ^Game, id: Entity, renderable: RenderableComponent) {
	g.entities[id].renderable = renderable
	g.entities[id].sig += {.Renderable}
}

entity_add_tags :: proc(g: ^Game, id: Entity, tags: Signature) {
	g.entities[id].sig += tags
}
