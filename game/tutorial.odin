package game

import rl "vendor:raylib"

tutorial_draw :: proc(g: ^Game) {
    if g.status != .Playing do return

	if !g.tutorial.launch_done {
		size := rl_text_measure(g, .Body, t(g, .Tutorial_Start))
		pos := rl.Vector2{(g.screenw - size.x) / 2, g.screenh - 100 - size.y}

		rl_text_draw(g, .Body, t(g, .Tutorial_Start), pos)
	}
}

