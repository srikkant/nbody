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

entity_add_mass :: proc(g: ^Game, id: Entity, mass: MassComponent) {
	if mass == 0 {
		return
	}
	g.entities[id].mass = mass
	g.entities[id].sig += {.Mass}
}

entity_add_radius :: proc(g: ^Game, id: Entity, radius: RadiusComponent) {
	if radius == 0 {
		return
	}
	g.entities[id].radius = radius
	g.entities[id].sig += {.Radius}
}

entity_add_velocity :: proc(g: ^Game, id: Entity, vel: VelocityComponent) {
	g.entities[id].velocity = vel
	g.entities[id].sig += {.Velocity}
}

entity_add_orbit :: proc(g: ^Game, id: Entity, orbit: OrbitComponent) {
	g.entities[id].orbit = orbit
	g.entities[id].sig += {.Orbit}
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

entity_add_celestial :: proc(g: ^Game, id: Entity, celestial: CelestialComponent) {
	g.entities[id].celestial = celestial
	g.entities[id].sig += {.Celestial}
}

entity_add_emitter :: proc(g: ^Game, id: Entity, emitter: EmitterComponent) {
	if emitter.base_cost == 0 {
		return
	}

	g.entities[id].emitter = emitter
	g.entities[id].sig += {.Emitter}
}

entity_add_renderable :: proc(g: ^Game, id: Entity, renderable: RenderableComponent) {
	g.entities[id].renderable = renderable
	g.entities[id].sig += {.Renderable}
}

entity_add_collectible_energy :: proc(g: ^Game, id: Entity, ce: CollectibleEnergyComponent) {
	if ce.energy <= 0 {
		return
	}
	g.entities[id].collectible_energy = ce
	g.entities[id].sig += {.CollectibleEnergy}
}

entity_add_tags :: proc(g: ^Game, id: Entity, tags: Signature) {
	g.entities[id].sig += tags
}

push_event :: proc(g: ^Game, event: Game_Event) {
	if g.events_count == MAX_ENTITIES do return

	g.events[g.events_count] = event
	g.events_count += 1
}

entity_celestial_next_type :: proc(t: CelestialType) -> CelestialType {
	if t == .None do return .None
	if t == .Star do return .Star
	return CelestialType(int(t) + 1)
}

entity_celestial_prev_type :: proc(t: CelestialType, steps: int = 1) -> CelestialType {
	if t == .None do return .None
	idx := int(t) - steps
	if idx <= int(CelestialType.Asteroid) do return CelestialType.Asteroid
	return CelestialType(idx)
}

entity_celestial_is_unlockable :: proc(t: CelestialType) -> bool {
	return t >= .Asteroid && t < .Star
}
