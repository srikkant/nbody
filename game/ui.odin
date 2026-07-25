package game

import rl "vendor:raylib"

ui_init :: proc(g: ^Game) {
	ui_control_menu_init(g)

	g.help.launch_done = false
}

ui_draw :: proc(g: ^Game) {
	ui_top_bar_draw(g)
	if g.status == .Paused && g.help.launch_done {
		ui_upgrade_menu_draw(g)
	}
	ui_modifiers_draw(g)
	ui_help_draw(g)
	ui_control_menu_draw(g)
	ui_cursor_draw(g)
}

ui_is_mouse_over_ui :: proc(g: ^Game) -> bool {
	if g.status == .Paused do return true
	if g.help.launch_done {
		if rl.CheckCollisionPointRec(g.input.mouse_pos_screen, g.control_menu.rect) do return true
	}
	return false
}

ui_cursor_draw :: proc(g: ^Game) {
	mouse_screen := g.input.mouse_pos_screen
	is_over_ui := ui_is_mouse_over_ui(g)

	if !is_over_ui && g.slingshot.status != .Active {
		halo_radius := g.effective_params.physics.cursor_distance * g.camera.rl_cam.zoom
		rl.DrawCircleV(mouse_screen, halo_radius, g.theme.color_cursor_collector)
	}

	scale := max(g.scale, 1.0)
	rl.DrawCircleV(mouse_screen, CURSOR_POINTER_SIZE * scale, rl.WHITE)
}

ui_modifiers_draw :: proc(g: ^Game) {
	if g.modifiers_count == 0 do return

	chip_w: f32 = 140
	chip_h: f32 = 24
	margin: f32 = 10
	start_x := g.screenw - chip_w - margin
	start_y: f32 = g.theme.margin_top_bar + 25

	for i in 0 ..< g.modifiers_count {
		m := g.modifiers[i]
		chip_y := start_y + f32(i) * (chip_h + 6)
		chip_rec := rl.Rectangle{start_x, chip_y, chip_w, chip_h}

		rl.DrawRectangleRec(chip_rec, rl.Color{25, 30, 40, 210})
		rl.DrawRectangleLinesEx(chip_rec, 1, rl.Color{70, 80, 100, 255})

		name_str: cstring
		switch m.kind {
		case .Gravity_Boost:
			name_str = "Gravity Boost"
		case .Energy_Magnet:
			name_str = "Energy Magnet"
		}

		rl.DrawText(name_str, i32(start_x + 8), i32(chip_y + 4), 12, rl.WHITE)

		if m.permanent {
			rl.DrawText("INF", i32(start_x + chip_w - 28), i32(chip_y + 4), 12, rl.GOLD)
		} else if m.timer.interval > 0 {
			remaining := max(f32(0), m.timer.interval - m.timer.curr)
			ratio := clamp(remaining / m.timer.interval, 0.0, 1.0)
			bar_rec := rl.Rectangle{start_x + 2, chip_y + chip_h - 4, (chip_w - 4) * ratio, 2}
			rl.DrawRectangleRec(bar_rec, rl.SKYBLUE)
		}
	}
}

ui_top_bar_draw :: proc(g: ^Game) {
	if g.status == .Paused {
		rl.DrawRectangle(0, 0, i32(g.screenw), i32(g.screenh), rl.Color{5, 8, 15, 230})
	}

	pos := rl.Vector2(g.theme.margin_top_bar)

	if g.help.launch_done {
		energy := fmt_compact(g.score.energy)
		rl_text_draw(g, .BodyBold, energy, pos)
	}

	if g.status == .Paused {
		title_size := rl_text_measure(g, .Title, t(g, .Title))
		title_pos := rl.Vector2{(g.screenw - title_size.x) / 2, g.theme.margin_top_bar}
		rl_text_draw(g, .Title, t(g, .Title), title_pos)

		paused_size := rl_text_measure(g, .Body, t(g, .Paused))
		paused_pos := rl.Vector2 {
			g.screenw - (g.theme.margin_top_bar + paused_size.x),
			g.theme.margin_top_bar,
		}
		rl_text_draw(g, .BodyBold, t(g, .Paused), paused_pos)
	}
}

ui_help_draw :: proc(g: ^Game) {
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
