#+build !js

package main

import rl "vendor:raylib"

main :: proc() {
	g := game_init({h = 810, w = 1440})
	defer game_free(g)

	for !rl.WindowShouldClose() {
		game_run(g)
	}
}
