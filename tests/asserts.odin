package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

expect_f32_approx :: proc(t: ^testing.T, got, want: f32, eps := f32(1e-4), msg := "") -> bool {
	ok := abs(got - want) <= eps
	return testing.expectf(t, ok, "%s: expected %v ≈ %v (eps %v)", msg, got, want, eps)
}

expect_f64_approx :: proc(t: ^testing.T, got, want: f64, eps := f64(1e-6), msg := "") -> bool {
	ok := abs(got - want) <= eps
	return testing.expectf(t, ok, "%s: expected %v ≈ %v (eps %v)", msg, got, want, eps)
}

expect_vec2_approx :: proc(
	t: ^testing.T,
	got, want: rl.Vector2,
	eps := f32(1e-4),
	msg := "",
) -> bool {
	ok := abs(got.x - want.x) <= eps && abs(got.y - want.y) <= eps
	return testing.expectf(t, ok, "%s: expected %v ≈ %v (eps %v)", msg, got, want, eps)
}

expect_event_count :: proc(t: ^testing.T, g: ^game.Game, $T: typeid, want: int) -> bool {
	count := 0
	for i in 0 ..< g.events_count {
		if _, ok := g.events[i].(T); ok do count += 1
	}
	ok := count == want
	return testing.expectf(
		t,
		ok,
		"expected %d events of type %v, got %d",
		want,
		typeid_of(T),
		count,
	)
}
