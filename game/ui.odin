package game

import "core:fmt"
import rl "vendor:raylib"

ui_init :: proc(g: ^Game) {
	ui_control_menu_init(g)

	g.help.launch_done = false
}

ui_draw :: proc(g: ^Game) {
	ui_top_bar_draw(g)
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
		halo_radius := g.params.physics.cursor_distance * g.camera.rl_cam.zoom
		rl.DrawCircleV(mouse_screen, halo_radius, g.theme.color_cursor_collector)
	}

	scale := max(g.scale, 1.0)
	rl.DrawCircleV(mouse_screen, CURSOR_POINTER_SIZE * scale, rl.WHITE)
}

ui_top_bar_draw :: proc(g: ^Game) {
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
