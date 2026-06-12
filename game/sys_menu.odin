package game

import rl "vendor:raylib"

sys_render_menu_main :: proc(g: ^Game) {
	panel_width: f32 = 450
	panel_height: f32 = 160
	panel_x := (g.screenw - panel_width) / 2.0
	panel_y := (g.screenh - panel_height) / 2.0
	panel_rect := rl.Rectangle{panel_x, panel_y, panel_width, panel_height}

	ui_draw_panel(g, panel_rect)

	// Buttons
	btn_width: f32 = 240
	btn_height: f32 = 44
	btn_x := panel_x + (panel_width - btn_width) / 2.0

	new_game_y := panel_y + 25
	exit_y := new_game_y + btn_height + 14

	if ui_draw_button(g, t(g, .NewGame), {btn_x, new_game_y, btn_width, btn_height}) {
		game_reset(g)
		g.status = .Playing
	}

	if ui_draw_button(g, t(g, .Exit), {btn_x, exit_y, btn_width, btn_height}) {
		g.status = .Exit
	}
}

sys_render_menu_pause :: proc(g: ^Game) {
	panel_width: f32 = 450
	panel_height: f32 = 280
	panel_x := (g.screenw - panel_width) / 2.0
	panel_y := (g.screenh - panel_height) / 2.0

	panel_rect := rl.Rectangle{panel_x, panel_y, panel_width, panel_height}
	ui_draw_panel(g, panel_rect)

	// Buttons
	btn_width: f32 = 240
	btn_height: f32 = 44
	btn_x := panel_x + (panel_width - btn_width) / 2.0

	resume_y := panel_y + 25
	restart_y := resume_y + btn_height + 12
	menu_y := restart_y + btn_height + 12
	exit_y := menu_y + btn_height + 12

	if ui_draw_button(g, t(g, .Resume), {btn_x, resume_y, btn_width, btn_height}) {
		g.status = .Playing
	}

	if ui_draw_button(g, t(g, .Restart), {btn_x, restart_y, btn_width, btn_height}) {
		game_reset(g)
	}

	if ui_draw_button(g, t(g, .MainMenu), {btn_x, menu_y, btn_width, btn_height}) {
		g.status = .Menu
	}

	if ui_draw_button(g, t(g, .Exit), {btn_x, exit_y, btn_width, btn_height}) {
		g.status = .Exit
	}
}

