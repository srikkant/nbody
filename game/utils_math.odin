package game

import "core:math"
import rl "vendor:raylib"

vec2_length_sq :: proc(v: rl.Vector2) -> f32 {
	return v.x * v.x + v.y * v.y
}

vec2_length :: proc(v: rl.Vector2) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

utils_math_update_timer :: proc(t: ^Timer, delta: f32) {
	t.done = false
	t.curr += delta
	if t.curr >= t.interval {
		t.curr -= t.interval
		t.done = true
	}
}

utils_math_reset_timer :: proc(t: ^Timer, interval: f32) {
	t.interval = interval
	t.curr = 0
	t.done = false
}
