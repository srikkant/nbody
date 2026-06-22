package game

tutorial_draw :: proc(g: ^Game) {
	if g.status != .Playing do return

	if !g.tutorial.launch_done {
		// @TODO: Should title be rendered here?
		title_size := rl_text_measure(g, .Title, t(g, .Title))
		tutorial_size := rl_text_measure(g, .Body, t(g, .Tutorial_Start))

		y := (3 * g.screenw / 4) // 75% of screen
		rl_text_draw(g, .Body, t(g, .Tutorial_Start), {(g.screenw - tutorial_size.x) / 2, y})

		y = y + tutorial_size.y + g.theme.spacing_l
		rl_text_draw(g, .Title, t(g, .Title), {(g.screenw - title_size.x) / 2, y})
	}
}

