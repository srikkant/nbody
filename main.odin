#+build !js

package main

import rl "vendor:raylib"

main :: proc() {
	g := game_init()
	defer game_free(g)

	for !rl.WindowShouldClose() {
		game_run(g)
	}
}
