package game

import "core:math"
import rl "vendor:raylib"

frame_setup :: proc(g: ^Game) {
	g.dt = math.min(rl.GetFrameTime(), MAX_DT)
	g.elapsed += g.dt
	g.screenw = f32(rl.GetScreenWidth())
	g.screenh = f32(rl.GetScreenHeight())

	for i in Timer_BuiltIn {
		math_update_timer(&g.timers[i], g.dt)
	}
}

