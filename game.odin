package main

import rl "vendor:raylib"

Game_InitParams :: struct {
	w: i32,
	h: i32,
}

game_init :: proc(params: Game_InitParams) -> ^Game {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_RESIZABLE})
	rl.InitWindow(params.w, params.h, "n-body forge")
	rl.SetTargetFPS(60)
	rl.HideCursor()

	g := new(Game)

	assets_map_load(g)
	assets_textures_load(g)
	assets_fonts_load(g)
	assets_shaders_load(g)

	params_init_defaults(&g.params)
	theme_init_default(&g.theme)

	sys_render_init(g)
	sys_camera_init(g)
	sys_lifecycle_init(g)
	sys_debug_init(g)

	/*
	TODO: Move to a dynamic menu
	Sets up a new game.
	This will eventually move to a menu system and allow the player to start a game.
	*/

	g.slingshot.output = Game_SlingshotOutput_Celestial {
		celestial = {type = .DwarfPlanet},
	}

	g.render.menu = Game_MenuState {
		selected_mode      = .Normal,
		selected_celestial = .DwarfPlanet,
	}

	g.available_objects = {.Asteroid, .Moonlet, .DwarfPlanet}

	g.timers[.Score] = Timer {
		interval = 1,
	}

	g.timers[.Trail] = Timer {
		interval = 0.05,
	}

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

	return g
}

game_free :: proc(g: ^Game) {
	rl.CloseWindow()

	sys_render_free(g)
	assets_map_free(g)
	free(g)
}

game_run :: proc(g: ^Game) {
	sys_debug_input(g)
	sys_input(g)
	sys_modifier(g)
	sys_emitters(g)
	sys_physics(g)
	sys_score(g)
	sys_lifecycle(g)
	sys_camera(g)

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	sys_render(g)

	if g.draw_debug_panel {
		sys_debug_render_world(g)
		sys_debug(g)
	}

	rl.EndDrawing()
}
