package main

utils_math_update_timer :: proc(t: ^Timer, delta: f32) -> bool {
	t.acc += delta
	if t.acc >= t.val {
		t.acc -= t.val
		return true
	}
	return false
}
