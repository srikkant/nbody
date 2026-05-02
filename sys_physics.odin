package main

import "core:math"
import rl "vendor:raylib"

PHYSICS_SIG: Signature : {.Position, .Velocity, .Size}
STAR_SIG: Signature : {.Star}

sys_physics :: proc(g: ^Game) {
	softening := f32(2.0) // for preventing division by zero
	dt := rl.GetFrameTime() * 10

	accels := make([]rl.Vector2, g.entity_count)
	defer delete(accels)

	for i in 0 ..< g.entity_count {
		e1 := &g.entities[i]
		if !(PHYSICS_SIG <= e1.sig) do continue

		total_accel := rl.Vector2(0)

		for j in 0 ..< g.entity_count {
			if i == j do continue

			e2 := &g.entities[j]
			if !(PHYSICS_SIG <= e2.sig) do continue

			// Vector from i to j
			diff := e2.pos - e1.pos
			r2 := diff.x * diff.x + diff.y * diff.y
			r3 := (r2 + softening) * math.sqrt(r2 + softening)

			strength := G * e2.size.mass
			total_accel.x += (strength * diff.x) / r3
			total_accel.y += (strength * diff.y) / r3
		}

		accels[i] = total_accel
	}

	for i in 0 ..< g.entity_count {
		e := &g.entities[i]
		// Stars do not move
		if !(PHYSICS_SIG <= e.sig) || STAR_SIG <= e.sig do continue

		e.vel += accels[i] * dt
		e.pos += e.vel * dt

		dist_sq := e.pos.x * e.pos.x + e.pos.y * e.pos.y
		if dist_sq > WORLD_RADUIS_SQ {
			entity_free(g, Entity(i))
		}
	}
}
