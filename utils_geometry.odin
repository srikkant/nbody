package main

import "core:math"
import rl "vendor:raylib"

geometry_get_rectangle_intersection_point :: proc(
	r: rl.Rectangle,
	p: rl.Vector2,
	padding: f32 = 0,
) -> (
	rl.Vector2,
	bool,
) {
	hit: rl.Vector2
	min_dist := f32(math.F32_MAX)
	found := false

	x1 := r.x + padding
	y1 := r.y + padding
	x2 := r.x + r.width - padding
	y2 := r.y + r.height - padding

	origin := rl.Vector2(0)

	sides := [4][2]rl.Vector2 {
		{{x1, y1}, {x2, r.y}}, // Top
		{{x1, y2}, {x2, y2}}, // Bottom
		{{x1, y1}, {r.x, y2}}, // Left
		{{x2, y1}, {x2, y2}}, // Right
	}

	for side in sides {
		cp: rl.Vector2
		if rl.CheckCollisionLines(origin, p, side[0], side[1], &cp) {
			dist := rl.Vector2Distance(origin, cp)
			if dist < min_dist {
				min_dist = dist
				hit = cp
				found = true
			}
		}
	}

	return found ? hit : p, found
}
