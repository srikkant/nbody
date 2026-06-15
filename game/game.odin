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

	assets_map_load(g)
	assets_textures_load(g)
	assets_fonts_load(g)
	assets_shaders_load(g)

	params_init(&g.params)
	theme_init(&g.theme)

	sys_render_init(g)
	sys_camera_init(g)
	sys_lifecycle_init(g)

	g.slingshot.output = Game_SlingshotOutput_Celestial {
		celestial = {type = .DwarfPlanet},
	}

	g.slingshot.available_objects = {.DwarfPlanet}
	g.timers[.Score] = Timer{0, 1, false}
	g.timers[.Trail] = Timer{0, 0.05, false}

	g.debug = {
		hover_celestial = -1,
		hover_mode      = -1,
	}

	push_event(
		g,
		Game_Event_ObjectSpawn {
			pos = rl.Vector2(0),
			celestial = {.Star},
			density = g.params.celestials[.Star].density,
			radius = g.params.celestials[.Star].radius,
			energy_source = {output = 10, timer = {interval = 1}},
			renderable = {g.params.celestials[.Star].color},
		},
	)

	g.status = .Menu

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

	for i in Game_TimerType {
		g.timers[i].curr = 0
	}

	push_event(
		g,
		Game_Event_ObjectSpawn {
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
	assets_map_free(g)
	free(g)

	rl.CloseWindow()
}

game_run :: proc(g: ^Game) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	frame_setup(g)
	input_process(g)

	switch g.status {
	case .Menu:
		sys_camera(g)
		sys_render(g)
		sys_render_menu_main(g)
	case .Playing:
		sys_slingshot(g)
		sys_modifier(g)
		sys_automation(g)
		sys_physics(g)
		sys_score(g)
		sys_lifecycle(g)
		sys_camera(g)
		sys_render(g)
		sys_debug(g) // TODO: Figure out best way to handle this.
	case .Paused:
		sys_render(g)
		sys_render_menu_pause(g)
	case .Exit:
	// Do nothing, the main loop will exit after this.
	}

	rl.EndDrawing()
}

