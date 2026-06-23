package game

import "core:fmt"
import rl "vendor:raylib"

ui_draw_top_bar :: proc(g: ^Game) {
	pos := rl.Vector2(g.theme.margin_top_bar)

	if g.help.launch_done {
		energy := fmt.ctprintf("%.2f", g.score.energy)
		rl_text_draw(g, .BodyBold, energy, pos)
	}

	if g.status == .Paused {
		size := rl_text_measure(g, .Body, t(g, .Paused))
		pos.x = g.screenw - (g.theme.margin_top_bar + size.x)
		rl_text_draw(g, .BodyBold, t(g, .Paused), pos)
	}
}

ui_draw_help :: proc(g: ^Game) {
	if g.status != .Playing do return

	// Splash screen / first help message
	if !g.help.launch_done {
		title_size := rl_text_measure(g, .Title, t(g, .Title))
		tutorial_size := rl_text_measure(g, .Body, t(g, .Tutorial_Start))

		y := (3 * g.screenh / 4) // 75% of screen
		rl_text_draw(g, .Body, t(g, .Tutorial_Start), {(g.screenw - tutorial_size.x) / 2, y})

		y = y + tutorial_size.y + g.theme.spacing_l
		rl_text_draw(g, .Title, t(g, .Title), {(g.screenw - title_size.x) / 2, y})
	}
}

ui_draw :: proc(g: ^Game) {
	ui_draw_top_bar(g)
	ui_draw_help(g)
}

