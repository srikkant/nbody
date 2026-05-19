package main

utils_math_update_timer :: proc(t: ^Timer, delta: f32) {
	t.done = false
	t.curr += delta
	if t.curr >= t.interval {
		t.curr -= t.interval
		t.done = true
	}
}
