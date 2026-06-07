package game

import "core:math"
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
	rl.SetExitKey(.KEY_NULL)

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

	g.state = .Menu

	return g
}

game_reset :: proc(g: ^Game) {
	g.entities_count = 0
	g.free_entities_count = 0
	g.events_count = 0

	for i in 0 ..< MAX_ENTITIES {
		g.entities[i].sig = {}
	}

	g.energy = 0
	g.total_objects = 0
	g.energy_rate_ticker = 0
	for i in 0 ..< AVG_CALC_TICKS {
		g.energy_gains[i] = 0
		g.energy_losses[i] = 0
	}

	sys_camera_init(g)

	g.slingshot.active = false
	g.slingshot_snap.active = false
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
	sys_render_free(g)
	assets_map_free(g)
	free(g)

	rl.CloseWindow()
}

game_run :: proc(g: ^Game) {
	g.dt = math.min(rl.GetFrameTime(), g.params.physics.max_delta_time_sec)
	g.elapsed += g.dt

	g.mouse_pos = input_mouse_pos(g)

	// Centralized premium cursor visibility management
	if g.state == .Menu || g.paused || g.draw_debug_panel {
		rl.ShowCursor()
	} else {
		rl.HideCursor()
	}

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	switch g.state {
	case .Menu:
		{
			sys_camera(g)
			sys_render(g)
			sys_render_menu_main(g)
		}
	case .Playing:
		{}
	}

	if g.state == .Menu {
		sys_camera(g)
		sys_render(g)
		sys_render_menu_main(g)
	} else if g.state == .Playing {
		if rl.IsKeyPressed(.ESCAPE) {
			g.paused = !g.paused
		}

		if !g.paused {
			sys_input(g)
			sys_modifier(g)
			sys_automation(g)
			sys_physics(g)
			sys_score(g)
			sys_lifecycle(g)
			sys_camera(g)
			sys_render(g)
		} else {
			sys_render(g)
			sys_render_menu_pause(g)
		}

		// Always allow debug panel tweaks
		sys_debug(g)
	}

	rl.EndDrawing()
}

