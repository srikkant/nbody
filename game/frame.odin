package game

import "core:math"
import rl "vendor:raylib"

/*
 * Runs once per game on reset
 */
frame_init :: proc(g: ^Game) {
	g.timers[.Score] = Timer{0, 1, false}
	g.timers[.Trail] = Timer{0, 0.05, false}
	g.timers[.Autosave] = Timer{0, SAVE_AUTOSAVE_INTERVAL_SEC, false}
}

/*
 * Runs at the beginning of every frame
 * Sets up some essentials for the frame
 */
frame_setup :: proc(g: ^Game) {
	g.dt = math.min(rl.GetFrameTime(), MAX_DT)
	g.elapsed += g.dt
	g.screenw = f32(rl.GetScreenWidth())
	g.screenh = f32(rl.GetScreenHeight())

	scalew := g.screenw / UI_BASE_WIDTH
	scaleh := g.screenh / UI_BASE_HEIGHT

	scale := math.min(scalew, scaleh)

	if scale != g.scale {
		g.scale = scale
		theme_init(g)
		assets_free(g)
		assets_init(g)
	}

	for i in Timer_BuiltIn {
		math_update_timer(&g.timers[i], g.dt)
	}
}
