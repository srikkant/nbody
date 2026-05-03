package main

sys_lifecycle :: proc(g: ^Game) {
	delete_entities := [MAX_ENTITIES]Entity{}
	delete_entities_count := 0

	for i in 0 ..< g.events_count {
		switch event in g.events[i] {
		case Game_Event_ObjectSpawn:
			id := entity_create(g)

			entity_add_size(g, id, SizeComponent{event.mass, event.radius})
			entity_add_position(g, id, event.pos)
			entity_add_renderable(g, id, RenderableComponent{event.color})
			entity_add_velocity(g, id, event.vel)
			entity_add_tags(g, id, event.tags)

		case Game_Event_Collision:
			// Handle collision event
			e1 := &g.entities[event.id1]
			e2 := &g.entities[event.id2]

			// Stars do not get deleted on collision
			if !(STAR_SIG <= e1.sig) {
				delete_entities[delete_entities_count] = event.id1
				delete_entities_count += 1
			}

			if !(STAR_SIG <= e2.sig) {
				delete_entities[delete_entities_count] = event.id2
				delete_entities_count += 1
			}

		case Game_Event_ObjectOutOfBounds:
			delete_entities[delete_entities_count] = event.id
			delete_entities_count += 1

		}
	}

	g.events_count = 0

	for i in 0 ..< delete_entities_count {
		// TODO: Spawn an explosion here
		entity_free(g, delete_entities[i])
	}
}
