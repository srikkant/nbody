package main

import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_HIGHDPI, .WINDOW_UNDECORATED})
	rl.InitWindow(1440, 960, "cellular automata")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	g := new(Game)
	g.render_texture = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)
	defer rl.UnloadRenderTexture(g.render_texture)

	g.camera.zoom = 1.0
	g.camera.offset = rl.Vector2{RENDER_WIDTH / 2, RENDER_HEIGHT / 2}
	g.camera.target = rl.Vector2(0)

	// TODO: Add Menus and whatnot
	// For now, just add a star directly and start the game!
	g.events_count = 1
	g.events[0] = Game_Event_ObjectSpawn {
		pos    = rl.Vector2(0),
		vel    = rl.Vector2(0),
		mass   = STAR_MASS,
		radius = STAR_RADIUS,
		color  = rl.YELLOW,
		tags   = {.Star},
	}

	for !rl.WindowShouldClose() {
		sys_input(g)
		sys_physics(g)
		sys_lifecycle(g)
		sys_render(g)

		// TODO: enable this before the render system once slingshot is decoupled from world space
		// sys_camera(&g)
	}
}
