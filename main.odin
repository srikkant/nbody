#+build !js

package main

import "core:mem"
import "game"
import rl "vendor:raylib"

main :: proc() {
	track := game.init_memory_tracker()
	defer game.free_memory_tracker(track)
	context.allocator = mem.tracking_allocator(track)

	g := game.game_init({h = 810, w = 1440})
	defer game.game_free(g)

	for !rl.WindowShouldClose() {
		game.game_run(g)
	}
}
