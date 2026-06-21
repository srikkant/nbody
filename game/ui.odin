package game

import rl "vendor:raylib"

ui_draw_top_bar :: proc(g: ^Game) {
	if g.status == .Paused {
		size := rl_text_measure(g, .Body, t(g, .Paused))
		pos := rl.Vector2{g.screenw - size.x - g.theme.margin_top_bar, g.theme.margin_top_bar}
		rl_text_draw(g, .Body, t(g, .Paused), pos)
	}
}

ui_draw :: proc(g: ^Game) {
	ui_draw_top_bar(g)
}

