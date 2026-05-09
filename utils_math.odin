package main

utils_math_update_timer :: proc(t: ^Timer, delta: f32) -> bool {
	t.curr += delta
	if t.curr >= t.interval {
		t.curr -= t.interval
		return true
	}
	return false
}
