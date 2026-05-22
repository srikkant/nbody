package main

import "core:math"
import rl "vendor:raylib"

sys_physics :: proc(g: ^Game) {
	dt := frame_time(g) * g.params.physics.simulation_rate_multiplier

	for i in 0 ..< g.entities_count {
		e1 := &g.entities[i]

		if !(PHYSICS_SIG <= e1.sig) do continue

		total_accel := rl.Vector2(0)
		e1_is_new := g.elapsed - e1.life.created_at < g.params.physics.spawn_invincibility_duration_sec
		e1_is_star := e1.celestial.type == .Star

		for j in 0 ..< g.entities_count {
			if j == i do continue

			e2 := &g.entities[j]
			if !(PHYSICS_SIG <= e2.sig) do continue

			accel, dist := physics_get_gravitational_acceleration(
				g,
				e1.pos.current,
				e1.radius,
				e2.pos.current,
				e2.mass,
				e2.radius,
			)

			collision_radius := (e1.radius + e2.radius)
			collision := dist < collision_radius * collision_radius
			total_accel += accel

			e2_is_star := e2.celestial.type == .Star
			e2_is_new := g.elapsed - e2.life.created_at < g.params.physics.spawn_invincibility_duration_sec

			invincible := (e1_is_new || e2_is_new) && !(e1_is_star || e2_is_star)

			if collision && !invincible {
				push_event(g, Game_Event_Collision{id1 = Entity(i), id2 = Entity(j)})
			}
		}

		e1.velocity.acceleration = total_accel
	}

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if !(PHYSICS_SIG <= e.sig) || e.celestial.type == .Star do continue

		e.velocity.current += e.velocity.acceleration * dt
		e.pos.current += e.velocity.current * dt

		if g.timers[.Trail].done {
			e.pos.trail[e.pos.trail_head] = e.pos.current
			e.pos.trail_head = (e.pos.trail_head + 1) % POSITION_TRAIL_LENGTH
		}

		if ORBIT_SIG <= e.sig {
			angle := math.atan2(e.pos.current.y, e.pos.current.x)
			diff := math.abs(angle - e.orbit.angle)
			if diff > math.PI do diff = (2.0 * math.PI) - diff

			if diff > ORBIT_POINTS_MIN_ANGLE {
				e.orbit.points[e.orbit.head] = e.pos.current
				e.orbit.head = (e.orbit.head + 1) % MAX_ORBIT_LENGTH
				e.orbit.angle = angle
				if e.orbit.count < MAX_ORBIT_LENGTH {
					e.orbit.count += 1
				}
			}

			curr_dist_sq := rl.Vector2LengthSqr(e.pos.current)
			if curr_dist_sq > e.orbit.max_distance_sq {
				e.orbit.max_distance_sq = curr_dist_sq
			}
		}

		dist_sq := rl.Vector2LengthSqr(e.pos.current)
		if dist_sq > g.params.physics.world_radius_squared {
			push_event(g, Game_Event_ObjectOutOfBounds{id = Entity(i)})
		}
	}
}
