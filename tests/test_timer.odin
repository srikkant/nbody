package tests

import game "../game"
import "core:testing"

@(test)
test_timer_tick_to_completion :: proc(t: ^testing.T) {
	timer := game.Timer {
		interval = 1.0,
		curr     = 0.0,
		done     = false,
	}

	game.utils_math_update_timer(&timer, 1.0)
	testing.expect_value(t, timer.done, true)
	testing.expect_value(t, timer.curr, f32(0.0))
}

@(test)
test_timer_wraps_correctly :: proc(t: ^testing.T) {
	timer := game.Timer {
		interval = 1.0,
		curr     = 0.0,
		done     = false,
	}

	game.utils_math_update_timer(&timer, 1.5)
	testing.expect_value(t, timer.done, true)
	testing.expect_value(t, timer.curr, f32(0.5))
}

@(test)
test_timer_partial_tick :: proc(t: ^testing.T) {
	timer := game.Timer {
		interval = 1.0,
		curr     = 0.0,
		done     = false,
	}

	game.utils_math_update_timer(&timer, 0.5)
	testing.expect_value(t, timer.done, false)
	testing.expect_value(t, timer.curr, f32(0.5))
}

@(test)
test_timer_done_resets_next_tick :: proc(t: ^testing.T) {
	timer := game.Timer {
		interval = 1.0,
		curr     = 0.0,
		done     = false,
	}

	game.utils_math_update_timer(&timer, 1.0)
	testing.expect_value(t, timer.done, true)

	game.utils_math_update_timer(&timer, 0.2)
	testing.expect_value(t, timer.done, false)
	testing.expect_value(t, timer.curr, f32(0.2))
}

@(test)
test_timer_reset :: proc(t: ^testing.T) {
	timer := game.Timer {
		interval = 1.0,
		curr     = 0.5,
		done     = true,
	}

	game.utils_math_reset_timer(&timer, 2.0)
	testing.expect_value(t, timer.interval, f32(2.0))
	testing.expect_value(t, timer.curr, f32(0.0))
	testing.expect_value(t, timer.done, false)
}
