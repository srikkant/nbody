package main

import rl "vendor:raylib"

main :: proc() {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_HIGHDPI, .WINDOW_UNDECORATED})
	rl.InitWindow(1440, 810, "cellular automata")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	g := game_init()

	for !rl.WindowShouldClose() {
		game_run(g)
	}
}
