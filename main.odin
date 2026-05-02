package main

import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_HIGHDPI, .WINDOW_UNDECORATED})
	rl.InitWindow(1440, 960, "cellular automata")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	g := Game{}
	g.render_texture = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)
	defer rl.UnloadRenderTexture(g.render_texture)

	g.camera.zoom = 1.0
	g.camera.offset = rl.Vector2{RENDER_WIDTH / 2, RENDER_HEIGHT / 2}
	g.camera.target = rl.Vector2(0)

	// TODO: Add Menus and whatnot
	// For now, just add a star directly and start the game!
	id := entity_create(&g)
	entity_add_star(&g, id)
	entity_add_size(&g, id, SizeComponent{STAR_MASS, STAR_RADIUS})
	entity_add_position(&g, id, rl.Vector2(0))
	entity_add_renderable(&g, id, RenderableComponent{rl.YELLOW})
	entity_add_velocity(&g, id, rl.Vector2{0, 0})

	for !rl.WindowShouldClose() {
		input_update(&g)

		sys_physics(&g)

		// TODO: enable this once slingshot is decoupled from world space
		// sys_camera(&g)

		sys_render(&g)
	}
}
