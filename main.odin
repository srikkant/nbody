#+build !js

package main

import "core:mem"
import "game"

main :: proc() {
	track := init_memory_tracker()
	defer free_memory_tracker(track)
	context.allocator = mem.tracking_allocator(track)

	g := game.game_init({h = 810, w = 1440})
	defer game.game_free(g)

	for g.status != .Exit {
		game.game_run(g)
	}
}

