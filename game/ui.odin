package game

import "core:fmt"
import rl "vendor:raylib"

ui_draw_top_bar :: proc(g: ^Game) {
	if g.status == .Paused {
		rl.DrawRectangle(0, 0, i32(g.screenw), i32(g.screenh), rl.Color{0, 0, 0, 150})
	}

	pos := rl.Vector2(g.theme.margin_top_bar)

	if g.help.launch_done {
		energy := fmt.ctprintf("%.2f", g.score.energy)
		rl_text_draw(g, .BodyBold, energy, pos)
	}

	if g.status == .Paused {
		title_size := rl_text_measure(g, .Title, t(g, .Title))
		title_pos := rl.Vector2{(g.screenw - title_size.x) / 2, g.theme.margin_top_bar}
		rl_text_draw(g, .Title, t(g, .Title), title_pos)

		paused_size := rl_text_measure(g, .Body, t(g, .Paused))
		paused_pos := rl.Vector2{g.screenw - (g.theme.margin_top_bar + paused_size.x), g.theme.margin_top_bar}
		rl_text_draw(g, .BodyBold, t(g, .Paused), paused_pos)
	}
}

ui_draw_help :: proc(g: ^Game) {
	if g.status != .Playing do return

	if !g.help.launch_done {
		title_size := rl_text_measure(g, .Title, t(g, .Title))
		tutorial_size := rl_text_measure(g, .Body, t(g, .Tutorial_Start))

		title_y := g.screenh * 0.20
		rl_text_draw(g, .Title, t(g, .Title), {(g.screenw - title_size.x) / 2, title_y})

		tutorial_y := g.screenh * 0.75
		rl_text_draw(
			g,
			.Body,
			t(g, .Tutorial_Start),
			{(g.screenw - tutorial_size.x) / 2, tutorial_y},
		)
	}
}

ui_draw :: proc(g: ^Game) {
	ui_draw_top_bar(g)
	ui_draw_help(g)
}
