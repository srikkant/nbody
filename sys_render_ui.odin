package main

import "core:fmt"
import rl "vendor:raylib"

UI_PADDING: f32 = 10

sys_render_ui :: proc(g: ^Game) {
	wh := f32(rl.GetScreenHeight())

	sx, sy: f32 = 20, 20

	_ = sys_render_ui_score(g, sx, sy)

	menu_rect := rl.Rectangle {
		x      = sx,
		y      = sy + 45,
		width  = g.params.ui.menu_width,
		height = wh - (sy + 45) - sy,
	}
	g.render.upgrade_menu_rect = menu_rect

	sys_render_ui_menu(g, menu_rect)
}

sys_render_ui_score :: proc(g: ^Game, sx: f32, sy: f32) -> f32 {
	x, icon_y, icon_size: f32 = sx + UI_PADDING * 2, sy + UI_PADDING * 2, 24
	text_y := icon_y + (icon_size - g.fonts[.Body].size) / 2

	cstr: cstring
	text_size: rl.Vector2
	avg_energy: f64
	for i in 0 ..< AVG_CALC_TICKS {
		avg_energy += g.energy_gains[i] / AVG_CALC_TICKS
	}

	rl_texture_draw(g, .UI_Energy, {x, icon_y, icon_size, icon_size})
	str := fmt.bprintf(g.render.score_energy[:], "%.2f", g.energy)
	g.render.score_energy[len(str)] = 0
	cstr = cstring(raw_data(str))

	x += icon_size + UI_PADDING
	text_size = rl_text_measure(g, .Body, cstr)
	rl_text_draw(g, .Body, cstr, {x, text_y})

	x += text_size.x + UI_PADDING * 2
	rl_texture_draw(g, .UI_EnergyAverage, {x, icon_y, icon_size, icon_size})
	str = fmt.bprintf(g.render.score_avg_energy[:], "%.2f/sec", avg_energy)
	g.render.score_avg_energy[len(str)] = 0
	cstr = cstring(raw_data(str))

	x += icon_size + UI_PADDING
	text_size = rl_text_measure(g, .Body, cstr)
	rl_text_draw(g, .Body, cstr, {x, text_y})

	x += text_size.x + UI_PADDING * 2
	rl_texture_draw(g, .UI_ObjectCount, {x, icon_y, icon_size, icon_size})
	str = fmt.bprintf(g.render.score_objects_count[:], "%d", g.total_objects)
	g.render.score_objects_count[len(str)] = 0
	cstr = cstring(raw_data(str))

	x += icon_size + UI_PADDING
	text_size = rl_text_measure(g, .Body, cstr)
	rl_text_draw(g, .Body, cstr, {x, text_y})

	total_width := x + text_size.x + UI_PADDING
	return total_width
}

sys_render_ui_menu :: proc(g: ^Game, rect: rl.Rectangle) {
	if !g.render.show_upgrade_menu do return

	// 1. Translucent Panel Background
	rl.DrawRectangleRounded(
		rect,
		g.params.ui.menu_border_rounding,
		g.params.ui.menu_segments,
		g.theme.ui_menu_bg_color,
	)

	// Top glowing sci-fi header accent rl.DrawRectangleRec(rl.Rectangle{rect.x, rect.y, rect.width, 2}, g.theme.ui_menu_accent_color)

	padding := g.params.ui.menu_inner_padding
	item_h := g.params.ui.menu_item_height
	y := rect.y + padding + 4

	rl_text_draw(
		g,
		.Menu_Label,
		"launch mode",
		{rect.x + padding, y},
		g.theme.ui_menu_header_color,
	)
	y += 18

	g.render.menu.hover_mode = -1
	for mode in Game_SlingshotMode {
		row_rect := rl.Rectangle{rect.x + padding, y, rect.width - 2 * padding, item_h}

		mouse_pos := rl.GetMousePosition()
		hovered := rl.CheckCollisionPointRec(mouse_pos, row_rect)
		selected := g.render.menu.selected_mode == mode

		if hovered {
			g.render.menu.hover_mode = int(mode)
			rl.DrawRectangleRec(row_rect, g.theme.ui_menu_item_hover_color)

			if rl.IsMouseButtonPressed(.LEFT) {
				g.render.menu.selected_mode = mode
				menu_apply_slingshot(g)
			}
		}

		if selected {
			rl.DrawRectangleRec(
				{row_rect.x, row_rect.y, 3, row_rect.height},
				g.theme.ui_menu_item_selected_color,
			)
		}

		label: cstring = mode == .Normal ? "normal" : "emitter"
		text_color :=
			selected ? g.theme.ui_menu_item_selected_color : (hovered ? rl.WHITE : g.theme.ui_menu_item_color)

		rl_text_draw(
			g,
			.Body,
			label,
			{row_rect.x + 12, row_rect.y + (item_h - g.fonts[.Body].size) / 2},
			text_color,
		)

		y += item_h + 4
	}

	// Divider
	y += 8
	rl.DrawLineEx(
		{rect.x + padding, y},
		{rect.x + rect.width - padding, y},
		1.0,
		g.theme.ui_menu_divider_color,
	)
	y += 12

	rl_text_draw(
		g,
		.Menu_Label,
		"celestial selection",
		{rect.x + padding, y},
		g.theme.ui_menu_header_color,
	)
	y += 18

	launchable_celestials := [11]CelestialType {
		.Asteroid,
		.Moonlet,
		.DwarfPlanet,
		.SubEarth,
		.SuperEarth,
		.MegaEarth,
		.MiniNeptune,
		.SubNeptune,
		.SuperNeptune,
		.GiantPlanet,
		.SuperJupiter,
	}

	g.render.menu.hover_celestial = -1
	for ct, idx in launchable_celestials {
		row_rect := rl.Rectangle{rect.x + padding, y, rect.width - 2 * padding, item_h}

		mouse_pos := rl.GetMousePosition()
		hovered := rl.CheckCollisionPointRec(mouse_pos, row_rect)
		selected := g.render.menu.selected_celestial == ct
		unlocked := ct in g.available_objects

		if unlocked && hovered {
			g.render.menu.hover_celestial = idx
			rl.DrawRectangleRec(row_rect, g.theme.ui_menu_item_hover_color)

			if rl.IsMouseButtonPressed(.LEFT) {
				g.render.menu.selected_celestial = ct
				menu_apply_slingshot(g)
			}
		}

		if selected {
			rl.DrawRectangleRec(
				{row_rect.x, row_rect.y, 3, row_rect.height},
				g.theme.ui_menu_item_selected_color,
			)
		}

		dot_color := unlocked ? g.params.celestials[ct].color : g.theme.ui_menu_item_locked_color
		dot_color.a = 255
		rl.DrawCircle(i32(row_rect.x + 12), i32(row_rect.y + item_h / 2), 3.5, dot_color)

		name_str := get_celestial_display_name(ct)
		text_color: rl.Color
		if !unlocked {
			text_color = g.theme.ui_menu_item_locked_color
		} else if selected {
			text_color = g.theme.ui_menu_item_selected_color
		} else if hovered {
			text_color = rl.WHITE
		} else {
			text_color = g.theme.ui_menu_item_color
		}

		rl_text_draw(
			g,
			.Body,
			name_str,
			{row_rect.x + 24, row_rect.y + (item_h - g.fonts[.Body].size) / 2},
			text_color,
		)

		y += item_h + 2
	}

	rl.DrawRectangleRec(
		rl.Rectangle{rect.x, rect.y + rect.height - 2, rect.width, 2},
		g.theme.ui_menu_accent_color,
	)
}

menu_apply_slingshot :: proc(g: ^Game) {
	ct := g.render.menu.selected_celestial
	switch g.render.menu.selected_mode {
	case .Normal:
		g.slingshot.output = Game_SlingshotOutput_Celestial {
			celestial = {type = ct},
		}
	case .Emitter:
		g.slingshot.output = Game_SlingshotOutput_Emitter {
			emitter = {
				emit_celestial = {type = ct},
				emit_density = g.params.celestials[ct].density,
				emit_radius = g.params.celestials[ct].radius,
				base_cost = f64(g.params.celestials[ct].launch_cost),
				timer = Timer{interval = 2},
				destroy_timer = Timer{interval = 10},
			},
		}
	}
}
