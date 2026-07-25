package game

import rl "vendor:raylib"

Game_InitParams :: struct {
	w: i32,
	h: i32,
}

game_init :: proc(params: Game_InitParams) -> ^Game {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_UNDECORATED})
	rl.InitWindow(params.w, params.h, "gigawatt galaxy")
	rl.SetExitKey(.KEY_NULL)
	rl.HideCursor()

	g := new(Game)
	g.screenw = f32(params.w)
	g.screenh = f32(params.h)

	assets_init(g)
	params_init(g)
	theme_init(g)

	input_init(g)
	background_init(g)
	ui_init(g)

	// Resume from save if present and valid; otherwise start fresh.
	if !persist_load_from_disk(g) {
		game_reset(g)
	}

	return g
}

game_reset :: proc(g: ^Game) {
	sys_camera_init(g)
	sys_lifecycle_init(g)
	sys_score_init(g)
	upgrade_reset(g, .Run, all = true)
	frame_init(g)
}

game_free :: proc(g: ^Game) {
	assets_free(g)
	free(g)
	rl.CloseWindow()
}

game_run :: proc(g: ^Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	frame_setup(g)
	input_process(g)

	background_draw(g)

	switch g.status {
	case .Playing:
		sys_modifier(g)
		sys_automation(g)
		sys_physics(g)
		sys_score(g)
		sys_lifecycle(g)

		// Autosave the game if required before moving to the rendering
		persist_maybe_autosave(g)

		sys_camera(g)
		sys_render(g)
	case .Paused:
		sys_modifier(g)
		sys_render(g)
	case .Exit:
	// Do nothing, the main loop will exit after this.
	}

	ui_draw(g)

	rl.EndDrawing()
}
