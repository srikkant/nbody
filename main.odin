package main

import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_HIGHDPI, .WINDOW_UNDECORATED})
	rl.InitWindow(1440, 810, "cellular automata")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	g := new(Game)

	assets_load_textures(g)
	defer assets_free_textures(g)

	assets_load_bg(g)
	defer assets_free_bg(g)

	assets_load_shaders(g)
	defer assets_free_shaders(g)

	sys_render_init(g)
	defer sys_render_free(g)

	sys_camera_init(g)
	sys_lifecycle_init(g)


	// TODO: Add Menus and whatnot
	// For now, just add set some params, add a star directly and start the game!
	g.params.g = 1
	g.params.masses[.Star] = 1000000
	g.params.radii[.Star] = 32
	g.params.masses[.DwarfPlanet] = 1
	g.params.radii[.DwarfPlanet] = 2
	g.params.slingshot_power = 1
	g.params.slingshot_preview_len = 2
	g.params.sim_rate = 10

	g.events[0] = Game_Event_ObjectSpawn {
		pos    = rl.Vector2(0),
		vel    = rl.Vector2(0),
		mass   = g.params.masses[.Star],
		radius = g.params.radii[.Star],
		tags   = {.Star},
	}

	for !rl.WindowShouldClose() {
		sys_input(g)
		sys_modifier(g)
		sys_emitters(g)
		sys_physics(g)
		sys_score(g)
		sys_lifecycle(g)
		// sys_camera(g)
		sys_render(g)
	}
}
