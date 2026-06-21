package game

import rl "vendor:raylib"

Game_InitParams :: struct {
	w: i32,
	h: i32,
}

game_init :: proc(params: Game_InitParams) -> ^Game {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_RESIZABLE})
	rl.InitWindow(params.w, params.h, "n-body forge")
	rl.SetExitKey(.KEY_NULL)
	rl.HideCursor()

	g := new(Game)

	assets_init(g)
	params_init(g)
	theme_init(g)

	sys_camera_init(g)

	input_init(g)
	background_init(g)

	g.slingshot.output = Slingshot_Output_Celestial {
		celestial = {type = .DwarfPlanet},
	}

	g.slingshot.available_objects = {.DwarfPlanet}
	g.timers[.Score] = Timer{0, 1, false}
	g.timers[.Trail] = Timer{0, 0.05, false}

	game_reset(g)

	return g
}

game_reset :: proc(g: ^Game) {
	g.entities_count = 0
	g.free_entities_count = 0
	g.events_count = 0

	for i in 0 ..< MAX_ENTITIES {
		g.entities[i].sig = {}
	}

	g.score.energy = 0
	g.score.total_objects = 0
	g.score.energy_rate_ticker = 0
	for i in 0 ..< AVG_CALC_TICKS {
		g.score.energy_gains[i] = 0
		g.score.energy_losses[i] = 0
	}

	sys_camera_init(g)

	g.slingshot.preview = 1
	g.slingshot.status = .Inactive
	g.slingshot.snap.active = false

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
		sys_camera(g)
		sys_render(g)
	case .Paused:
		sys_render(g)
	case .Exit:
	// Do nothing, the main loop will exit after this.
	}

	ui_draw(g)
	tutorial_draw(g)

	rl.EndDrawing()
}

