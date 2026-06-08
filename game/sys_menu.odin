package game

import "core:fmt"
import rl "vendor:raylib"

sys_render_menu_main :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())

	// Centered glassmorphic panel config
	panel_width: f32 = 450
	panel_height: f32 = 160
	panel_x := (ww - panel_width) / 2.0
	panel_y := (wh - panel_height) / 2.0

	panel_rect := rl.Rectangle{panel_x, panel_y, panel_width, panel_height}
	rl.DrawRectangleRounded(panel_rect, 0.04, 4, g.theme.ui_menu_bg_color)
	rl.DrawRectangleRoundedLines(panel_rect, 0.04, 4, g.theme.ui_menu_accent_color)

	// Buttons
	btn_width: f32 = 240
	btn_height: f32 = 44
	btn_x := panel_x + (panel_width - btn_width) / 2.0

	new_game_y := panel_y + 25
	exit_y := new_game_y + btn_height + 14

	if ui_draw_button(g, "new game", {btn_x, new_game_y, btn_width, btn_height}) {
		game_reset(g)
		g.status = .Playing
	}

	if ui_draw_button(g, "exit", {btn_x, exit_y, btn_width, btn_height}) {
		g.status = .Exit
	}
}

sys_render_menu_pause :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())

	panel_width: f32 = 450
	panel_height: f32 = 420
	panel_x := (ww - panel_width) / 2.0
	panel_y := (wh - panel_height) / 2.0

	panel_rect := rl.Rectangle{panel_x, panel_y, panel_width, panel_height}
	rl.DrawRectangleRounded(panel_rect, 0.04, 4, g.theme.ui_menu_bg_color)
	rl.DrawRectangleRoundedLines(panel_rect, 0.04, 4, g.theme.ui_menu_accent_color)

	// Pause Title
	title_str: cstring = "SIMULATION PAUSED"
	title_size := rl_text_measure(g, .Title, title_str)
	title_x := panel_x + (panel_width - title_size.x) / 2.0
	title_y := panel_y + 40

	// Text shadow
	rl_text_draw(g, .Title, title_str, {title_x + 2, title_y + 2}, rl.Color{0, 0, 0, 160})
	rl_text_draw(g, .Title, title_str, {title_x, title_y}, g.theme.ui_menu_item_selected_color)

	// Stats readout
	stats_buf: [128]byte
	stats_str := fmt.bprintf(
		stats_buf[:],
		"RESERVES: %.2f ENERGY | %d CELESTIALS",
		g.score.energy,
		g.score.total_objects,
	)
	stats_buf[len(stats_str)] = 0
	stats_cstr := cstring(raw_data(stats_str))

	sub_size := rl_text_measure(g, .Menu_Label, stats_cstr)
	sub_x := panel_x + (panel_width - sub_size.x) / 2.0
	sub_y := title_y + 50
	rl_text_draw(g, .Menu_Label, stats_cstr, {sub_x, sub_y}, g.theme.ui_menu_item_color)

	// Divider
	divider_y := sub_y + 25
	rl.DrawLineEx(
		{panel_x + 30, divider_y},
		{panel_x + panel_width - 30, divider_y},
		1.0,
		g.theme.ui_menu_divider_color,
	)

	// Buttons
	btn_width: f32 = 240
	btn_height: f32 = 44
	btn_x := panel_x + (panel_width - btn_width) / 2.0

	resume_y := divider_y + 25
	restart_y := resume_y + btn_height + 12
	menu_y := restart_y + btn_height + 12
	exit_y := menu_y + btn_height + 12

	if ui_draw_button(g, "RESUME", {btn_x, resume_y, btn_width, btn_height}) {
		g.status = .Playing
	}

	if ui_draw_button(g, "RESTART", {btn_x, restart_y, btn_width, btn_height}) {
		game_reset(g)
	}

	if ui_draw_button(g, "MAIN MENU", {btn_x, menu_y, btn_width, btn_height}) {
		g.status = .Menu
	}

	if ui_draw_button(g, "EXIT", {btn_x, exit_y, btn_width, btn_height}) {
		g.status = .Exit
	}
}

