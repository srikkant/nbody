package game

import "core:math"
import rl "vendor:raylib"

math_vec2_length_sq :: proc(v: rl.Vector2) -> f32 {
	return v.x * v.x + v.y * v.y
}

math_vec2_length :: proc(v: rl.Vector2) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

math_update_timer :: proc(t: ^Timer, delta: f32) {
	t.done = false
	t.curr += delta
	if t.curr >= t.interval {
		t.curr -= t.interval
		t.done = true
	}
}

math_reset_timer :: proc(t: ^Timer, interval: f32) {
	t.interval = interval
	t.curr = 0
	t.done = false
}

math_make_timer :: proc(interval: f32) -> Timer {
	return Timer{interval = interval, curr = 0, done = false}
}

math_catmull_rom :: proc(p0, p1, p2, p3: rl.Vector2, t: f32) -> rl.Vector2 {
	t2 := t * t
	t3 := t2 * t
	return(
		0.5 *
		((2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3) \
	)
}
