package main

import rl "vendor:raylib"

get_object_color :: proc(g: ^Game) -> rl.Color {
	rand_idx := rl.GetRandomValue(0, i32(9))
	return g.available_colors[int(rand_idx)]
}
