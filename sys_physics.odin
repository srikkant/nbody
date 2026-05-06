package main

import rl "vendor:raylib"

sys_physics :: proc(g: ^Game) {
	dt := rl.GetFrameTime() * g.params.sim_rate

	accels := make([]rl.Vector2, g.entities_count)
	defer delete(accels)

	for i in 0 ..< g.entities_count {
		e1 := &g.entities[i]
		if !(PHYSICS_SIG <= e1.sig) do continue

		total_accel := rl.Vector2(0)

		for j in 0 ..< g.entities_count {
			if i == j do continue

			e2 := &g.entities[j]
			if !(PHYSICS_SIG <= e2.sig) do continue

			// If the types are similar, add some extra chance of collision

			accel, dist := physics_get_graviational_acceleration(
				g,
				e1.pos.current,
				e1.size.radius,
				e2.pos.current,
				e2.size.mass,
				e2.size.radius,
			)

			// Just an sum of the two radii for approximate collision radius
			collision_radius := (e1.size.radius + e2.size.radius)
			collision := dist < collision_radius * collision_radius

			multiplier: f32 = 1
			for size in ComponentType {
				if size in e1.sig && size in e2.sig {
					#partial switch size {
					case .DwarfPlanet:
						multiplier = 100
					case .Planet:
						multiplier = 1000
					}
				}
			}

			total_accel += (accel * multiplier)

			if collision {
				g.events[g.events_count] = Game_Event_Collision {
					id1 = Entity(i),
					id2 = Entity(j),
					pos = (e1.pos.current + e2.pos.current) / 2,
				}
				g.events_count += 1
			}
		}

		accels[i] = total_accel
	}

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		// Stars do not move
		if !(PHYSICS_SIG <= e.sig) || STAR_SIG <= e.sig do continue

		e.vel += accels[i] * dt
		e.pos.current += e.vel * dt

		dist_sq := rl.Vector2LengthSqr(e.pos.current)
		if dist_sq > WORLD_RADUIS_SQ {
			g.events[g.events_count] = Game_Event_ObjectOutOfBounds {
				id  = Entity(i),
				pos = e.pos.current,
			}
			g.events_count += 1
		}
	}
}
