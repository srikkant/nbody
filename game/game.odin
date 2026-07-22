package game

import rl "vendor:raylib"

Game_InitParams :: struct {
	w: i32,
	h: i32,
}

game_init :: proc(params: Game_InitParams) -> ^Game {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_RESIZABLE})
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

	g.slingshot.output = Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}

	g.slingshot.available_objects = {.DwarfPlanet}
	g.timers[.Score] = Timer{0, 1, false}
	g.timers[.Trail] = Timer{0, 0.05, false}
	g.timers[.Autosave] = Timer{0, SAVE_AUTOSAVE_INTERVAL_SEC, false}

	// Resume from save if present and valid; otherwise start fresh.
	if !persist_load_from_disk(g) {
		game_reset(g)
	}

	return g
}

game_reset :: proc(g: ^Game) {
	g.camera.rl_cam.zoom = 1
	g.camera.rl_cam.offset = rl.Vector2{g.screenw / 2, g.screenh / 2}
	g.camera.rl_cam.target = rl.Vector2(0)
	g.slingshot.preview = 1
	g.slingshot.status = .Inactive
	g.slingshot.snap.active = false
	g.entities_count = 0
	g.free_entities_count = 0
	g.events_count = 0

	g.score.energy = 100000 // TODO: added for debugging.
	g.score.total_objects = 0
	g.score.energy_rate_ticker = 0

	for i in 0 ..< MAX_ENTITIES {
		g.entities[i].sig = {}
	}

	for i in 0 ..< AVG_CALC_TICKS {
		g.score.energy_gains[i] = 0
		g.score.energy_losses[i] = 0
	}

	for i in Timer_BuiltIn {
		g.timers[i].curr = 0
	}

	push_event(
		g,
		GameEvent_ObjectSpawn {
			pos = rl.Vector2(0),
			celestial = {.Star},
			density = g.params.celestials[.Star].density,
			radius = g.params.celestials[.Star].radius,
			energy_source = {output = 10, timer = {interval = 1}},
			renderable = {g.params.celestials[.Star].color},
		},
	)
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
		sys_slingshot(g)
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
		sys_render(g)
	case .Exit:
	// Do nothing, the main loop will exit after this.
	}

	ui_draw(g)

	rl.EndDrawing()
}
