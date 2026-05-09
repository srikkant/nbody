package main

import "core:math"
import rl "vendor:raylib"

sys_physics :: proc(g: ^Game) {
	dt := frame_time() * g.params.sim_rate

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

			accel, dist := physics_get_graviational_acceleration(
				g,
				e1.pos.current,
				e1.radius,
				e2.pos.current,
				e2.mass,
				e2.radius,
			)

			// Just an sum of the two radii for approximate collision radius
			collision_radius := (e1.radius + e2.radius)
			collision := dist < collision_radius * collision_radius
			total_accel += accel

			if collision {
				push_event(g, Game_Event_Collision{Entity(i), Entity(j)})
			}
		}

		accels[i] = total_accel
	}

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		// Stars do not move
		if !(PHYSICS_SIG <= e.sig) || e.celestial.type == .Star do continue

		e.velocity += accels[i] * dt
		e.pos.current += e.velocity * dt

		if TRAIL_SIG <= e.sig {
			angle := math.atan2(e.pos.current.y, e.pos.current.x)
			diff := math.abs(angle - e.trail.angle)
			if diff > math.PI do diff = (2.0 * math.PI) - diff

			if diff > TRAIL_MIN_ANGLE {
				e.trail.points[e.trail.head] = e.pos.current
				e.trail.head = (e.trail.head + 1) % MAX_TRAIL_LENGTH
				e.trail.angle = angle
				if e.trail.count < MAX_TRAIL_LENGTH {
					e.trail.count += 1
				}
			}
		}

		dist_sq := rl.Vector2LengthSqr(e.pos.current)
		if dist_sq > WORLD_RADIUS_SQ {
			push_event(g, Game_Event_ObjectOutOfBounds{id = Entity(i)})
		}
	}
}
