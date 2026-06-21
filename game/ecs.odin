package game

entity_create :: proc(g: ^Game) -> Entity_Id {
	id: Entity_Id

	if g.free_entities_count > 0 {
		g.free_entities_count -= 1
		id = g.free_entities[g.free_entities_count]
	} else {
		id = Entity_Id(g.entities_count)
		g.entities_count += 1
	}

	g.entities[id].sig = {}

	return id
}

entity_free :: proc(g: ^Game, id: Entity_Id) {
	g.entities.sig[id] = {}
	g.free_entities[g.free_entities_count] = id
	g.free_entities_count += 1
}

entity_add_position :: proc(g: ^Game, id: Entity_Id, pos: Component_Position) {
	g.entities[id].pos = pos
	g.entities[id].sig += {.Position}
}

entity_add_mass :: proc(g: ^Game, id: Entity_Id, mass: Component_Mass) {
	if mass == 0 {
		return
	}
	g.entities[id].mass = mass
	g.entities[id].sig += {.Mass}
}

entity_add_radius :: proc(g: ^Game, id: Entity_Id, radius: Component_Radius) {
	if radius == 0 {
		return
	}
	g.entities[id].radius = radius
	g.entities[id].sig += {.Radius}
}

entity_add_velocity :: proc(g: ^Game, id: Entity_Id, vel: Component_Velocity) {
	g.entities[id].velocity = vel
	g.entities[id].sig += {.Velocity}
}

entity_add_orbit :: proc(g: ^Game, id: Entity_Id, orbit: Component_Orbit) {
	g.entities[id].orbit = orbit
	g.entities[id].sig += {.Orbit}
}

entity_add_energy_source :: proc(g: ^Game, id: Entity_Id, energy_source: Component_EnergySource) {
	if energy_source.output == 0 {
		return
	}

	g.entities[id].energy_source = energy_source
	g.entities[id].sig += {.EnergySource}
}

entity_add_life :: proc(g: ^Game, id: Entity_Id, life: Component_Life) {
	g.entities[id].life = life
	g.entities[id].sig += {.Life}
}

entity_add_celestial :: proc(g: ^Game, id: Entity_Id, celestial: Component_Celestial) {
	g.entities[id].celestial = celestial
	g.entities[id].sig += {.Celestial}
}

entity_add_emitter :: proc(g: ^Game, id: Entity_Id, emitter: Component_Emitter) {
	if emitter.base_cost == 0 {
		return
	}

	g.entities[id].emitter = emitter
	g.entities[id].sig += {.Emitter}
}

entity_add_renderable :: proc(g: ^Game, id: Entity_Id, renderable: Component_Renderable) {
	g.entities[id].renderable = renderable
	g.entities[id].sig += {.Renderable}
}

entity_add_collectible_energy :: proc(g: ^Game, id: Entity_Id, ce: Component_CollectibleEnergy) {
	if ce.energy <= 0 {
		return
	}
	g.entities[id].collectible_energy = ce
	g.entities[id].sig += {.CollectibleEnergy}
}

entity_add_shockwave :: proc(g: ^Game, id: Entity_Id, es: Component_Shockwave) {
	g.entities[id].shockwave = es
	g.entities[id].sig += {.Shockwave}
}

push_event :: proc(g: ^Game, event: GameEvent) {
	if g.events_count == MAX_ENTITIES do return

	g.events[g.events_count] = event
	g.events_count += 1
}

entity_celestial_next_type :: proc(t: Celestial_Type) -> Celestial_Type {
	if t == .None do return .None
	if t == .Star do return .Star
	return Celestial_Type(int(t) + 1)
}

entity_celestial_prev_type :: proc(t: Celestial_Type, steps: int = 1) -> Celestial_Type {
	if t == .None do return .None
	idx := int(t) - steps
	if idx <= int(Celestial_Type.Asteroid) do return Celestial_Type.Asteroid
	return Celestial_Type(idx)
}

entity_celestial_is_unlockable :: proc(t: Celestial_Type) -> bool {
	return t >= .Asteroid && t < .Star
}

