package game

import rl "vendor:raylib"

ui_control_menu_update_output :: proc(g: ^Game) {
	switch g.control_menu.active_tab {
	case .Direct:
		g.slingshot.output = Slingshot_Output_Celestial {
			celestial = {type = g.control_menu.selected_celestial},
		}
	case .Emitter:
		preset := g.params.emitter_presets[g.control_menu.selected_preset]
		cel_type := g.control_menu.selected_celestial
		cel_params := g.params.celestials[cel_type]

		emitter := Component_Emitter {
			emit_celestial = {type = cel_type},
			max_count = preset.max_count,
			base_cost = max(f64(cel_params.launch_cost) * preset.cost_multiplier, 1.0),
		}
		emitter.timer = Timer {
			interval = preset.interval,
		}
		emitter.destroy_timer = Timer {
			interval = preset.duration,
		}

		g.slingshot.output = Slingshot_Output_Emitter {
			emitter = emitter,
		}
	case .Hardware:
		g.slingshot.output = Slingshot_Output_Hardware{}
	}
}

ui_control_menu_init :: proc(g: ^Game) {
	g.control_menu.active_tab = .Direct
	g.control_menu.selected_celestial = .DwarfPlanet
	g.control_menu.selected_preset = .Steady
	g.control_menu.opacity = 1.0

	ui_control_menu_update_output(g)
}

ui_control_menu_handle_click :: proc(g: ^Game) -> bool {
	if g.status != .Playing || !g.help.launch_done do return false

	mouse_screen := g.input.mouse_pos_screen

	// If click is not inside the menu bounding box, return false (not consumed)
	if !rl.CheckCollisionPointRec(mouse_screen, g.control_menu.rect) do return false

	// Check Tier 1 tabs
	for tab in Control_Menu_Tab {
		if tab == .Hardware do continue // Hardware is disabled, cannot select it

		if rl.CheckCollisionPointRec(mouse_screen, g.control_menu.tab_rects[tab]) {
			g.control_menu.active_tab = tab
			ui_control_menu_update_output(g)
			return true
		}
	}

	// Check Tier 2 contextual selectors
	switch g.control_menu.active_tab {
	case .Direct:
		// Check celestial picker
		for type in Celestial_Type {
			if type == .None do continue
			if !(type in g.slingshot.available_objects) do continue // Locked

			if rl.CheckCollisionPointRec(mouse_screen, g.control_menu.celestial_rects[type]) {
				g.control_menu.selected_celestial = type
				ui_control_menu_update_output(g)
				return true
			}
		}
	case .Emitter:
		// Check compact celestial picker (left)
		for type in Celestial_Type {
			if type == .None do continue
			if !(type in g.slingshot.available_objects) do continue // Locked

			if rl.CheckCollisionPointRec(mouse_screen, g.control_menu.celestial_rects[type]) {
				g.control_menu.selected_celestial = type
				ui_control_menu_update_output(g)
				return true
			}
		}

		for preset in Emitter_Preset {
			if rl.CheckCollisionPointRec(mouse_screen, g.control_menu.preset_rects[preset]) {
				g.control_menu.selected_preset = preset
				ui_control_menu_update_output(g)
				return true
			}
		}
	case .Hardware:
	// Stub, do nothing
	}

	return true
}

ui_control_menu_draw :: proc(g: ^Game) {
	if g.status != .Playing || !g.help.launch_done do return

	total_h := f32(96.0) * g.scale
	tab_h := f32(36.0) * g.scale
	deck_h := total_h - tab_h

	menu_y := g.screenh - total_h
	g.control_menu.rect = rl.Rectangle{0, menu_y, g.screenw, total_h}

	// Clear the hit-rects to avoid ghost hits if tabs change
	g.control_menu.tab_rects = {}
	g.control_menu.celestial_rects = {}
	g.control_menu.preset_rects = {}

	mouse_screen := g.input.mouse_pos_screen

	// 1. Draw Tier 1 Background
	rl.DrawRectangleRec(rl.Rectangle{0, menu_y, g.screenw, tab_h}, rl.Color{20, 20, 32, 220})

	// Draw horizontal line separator
	rl.DrawLineEx({0, menu_y + tab_h}, {g.screenw, menu_y + tab_h}, 1.0, rl.Color{50, 50, 70, 255})

	// Draw Tier 1 Tabs
	curr_x := f32(24.0) * g.scale
	tabs := [Control_Menu_Tab]string {
		.Direct   = "DIRECT LAUNCHES",
		.Emitter  = "AUTOMATED EMITTERS",
		.Hardware = "SPECIAL HARDWARE (COMING SOON)",
	}

	for tab in Control_Menu_Tab {
		cstr := cstring(raw_data(tabs[tab]))
		text_w := rl_text_measure(g, .BodyBold, cstr).x
		tab_w := text_w + 32.0 * g.scale

		tab_rect := rl.Rectangle{curr_x, menu_y, tab_w, tab_h}
		g.control_menu.tab_rects[tab] = tab_rect

		is_hovered := tab != .Hardware && rl.CheckCollisionPointRec(mouse_screen, tab_rect)
		is_selected := tab == g.control_menu.active_tab

		// Text color & indicator logic
		text_col := rl.Color{170, 170, 185, 255}
		if tab == .Hardware {
			text_col = rl.Color{100, 100, 110, 128}
		} else if is_selected {
			text_col = rl.WHITE
			// Underline indicator
			rl.DrawRectangle(
				i32(tab_rect.x),
				i32(tab_rect.y + tab_rect.height - 3.0 * g.scale),
				i32(tab_rect.width),
				i32(3.0 * g.scale),
				rl.Color{0, 230, 255, 255},
			)
		} else if is_hovered {
			text_col = rl.Color{0, 230, 255, 255}
		}

		text_size := rl_text_measure(g, .BodyBold, cstr)
		text_pos := rl.Vector2 {
			tab_rect.x + 16.0 * g.scale,
			tab_rect.y + (tab_h - text_size.y) / 2.0,
		}
		rl_text_draw(g, .BodyBold, cstr, text_pos, text_col)

		curr_x += tab_w + 12.0 * g.scale
	}

	// 2. Draw Tier 2 Background (The Deck)
	deck_y := menu_y + tab_h
	rl.DrawRectangleRec(rl.Rectangle{0, deck_y, g.screenw, deck_h}, rl.Color{12, 12, 20, 240})

	switch g.control_menu.active_tab {
	case .Direct:
		// Draw Celestial Picker
		curr_x = f32(24.0) * g.scale
		celestials := [12]Celestial_Type {
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
			.Star,
		}

		for type in celestials {
			cstr := get_celestial_display_name(type)
			is_unlocked := type in g.slingshot.available_objects

			text_size := rl_text_measure(g, .Body, cstr)
			circle_rad := f32(5.0) * g.scale
			circle_pad := f32(8.0) * g.scale

			button_w := circle_pad + 2.0 * circle_rad + text_size.x + 20.0 * g.scale
			button_h := f32(28.0) * g.scale

			button_rect := rl.Rectangle {
				curr_x,
				deck_y + (deck_h - button_h) / 2.0,
				button_w,
				button_h,
			}
			g.control_menu.celestial_rects[type] = button_rect

			is_hovered := is_unlocked && rl.CheckCollisionPointRec(mouse_screen, button_rect)
			is_selected := is_unlocked && type == g.control_menu.selected_celestial

			// Draw button background
			if !is_unlocked {
				// Muted, locked slot
				rl.DrawRectangleRec(button_rect, rl.Color{20, 20, 25, 100})
				rl.DrawCircleV(
					{button_rect.x + 12.0 * g.scale, button_rect.y + button_rect.height / 2.0},
					circle_rad,
					rl.Color{60, 60, 60, 100},
				)
				rl_text_draw(
					g,
					.Body,
					cstr,
					{
						button_rect.x + 24.0 * g.scale,
						button_rect.y + (button_rect.height - text_size.y) / 2.0,
					},
					rl.Color{80, 80, 90, 100},
				)
			} else {
				c_col := get_celestial_color(g, type)
				if is_selected {
					rl.DrawRectangleRec(button_rect, rl.Color{35, 35, 55, 255})
					rl.DrawRectangleLinesEx(button_rect, 1.2, rl.Color{0, 230, 255, 255})
					rl.DrawCircleV(
						{button_rect.x + 12.0 * g.scale, button_rect.y + button_rect.height / 2.0},
						circle_rad,
						c_col,
					)
					rl_text_draw(
						g,
						.Body,
						cstr,
						{
							button_rect.x + 24.0 * g.scale,
							button_rect.y + (button_rect.height - text_size.y) / 2.0,
						},
						rl.WHITE,
					)
				} else if is_hovered {
					rl.DrawRectangleRec(button_rect, rl.Color{25, 25, 38, 200})
					rl.DrawRectangleLinesEx(button_rect, 1.0, rl.Color{100, 100, 120, 255})
					rl.DrawCircleV(
						{button_rect.x + 12.0 * g.scale, button_rect.y + button_rect.height / 2.0},
						circle_rad,
						c_col,
					)
					rl_text_draw(
						g,
						.Body,
						cstr,
						{
							button_rect.x + 24.0 * g.scale,
							button_rect.y + (button_rect.height - text_size.y) / 2.0,
						},
						rl.WHITE,
					)
				} else {
					rl.DrawRectangleRec(button_rect, rl.Color{20, 20, 30, 150})
					rl.DrawCircleV(
						{button_rect.x + 12.0 * g.scale, button_rect.y + button_rect.height / 2.0},
						circle_rad,
						c_col,
					)
					rl_text_draw(
						g,
						.Body,
						cstr,
						{
							button_rect.x + 24.0 * g.scale,
							button_rect.y + (button_rect.height - text_size.y) / 2.0,
						},
						rl.Color{170, 170, 185, 255},
					)
				}
			}

			curr_x += button_w + 8.0 * g.scale
		}
	case .Emitter:
		// Draw Emitter section with split columns
		// Left: Payload Picker
		rl_text_draw(
			g,
			.BodyBold,
			"PAYLOAD:",
			{
				24.0 * g.scale,
				deck_y + (deck_h - rl_text_measure(g, .BodyBold, "PAYLOAD:").y) / 2.0,
			},
			rl.Color{130, 130, 150, 255},
		)

		curr_x = f32(110.0) * g.scale
		celestials := [12]Celestial_Type {
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
			.Star,
		}

		for type in celestials {
			cstr := get_celestial_display_name(type)
			is_unlocked := type in g.slingshot.available_objects

			text_size := rl_text_measure(g, .Body, cstr)
			circle_rad := f32(4.0) * g.scale

			button_w := 14.0 * g.scale + circle_rad + text_size.x + 16.0 * g.scale
			button_h := f32(24.0) * g.scale

			button_rect := rl.Rectangle {
				curr_x,
				deck_y + (deck_h - button_h) / 2.0,
				button_w,
				button_h,
			}
			g.control_menu.celestial_rects[type] = button_rect

			is_hovered := is_unlocked && rl.CheckCollisionPointRec(mouse_screen, button_rect)
			is_selected := is_unlocked && type == g.control_menu.selected_celestial

			// Draw compact button background
			if !is_unlocked {
				rl.DrawRectangleRec(button_rect, rl.Color{20, 20, 25, 80})
				rl.DrawCircleV(
					{button_rect.x + 10.0 * g.scale, button_rect.y + button_rect.height / 2.0},
					circle_rad,
					rl.Color{60, 60, 60, 80},
				)
				rl_text_draw(
					g,
					.Body,
					cstr,
					{
						button_rect.x + 20.0 * g.scale,
						button_rect.y + (button_rect.height - text_size.y) / 2.0,
					},
					rl.Color{80, 80, 90, 80},
				)
			} else {
				c_col := get_celestial_color(g, type)
				if is_selected {
					rl.DrawRectangleRec(button_rect, rl.Color{35, 35, 55, 255})
					rl.DrawRectangleLinesEx(button_rect, 1.2, rl.Color{0, 230, 255, 255})
					rl.DrawCircleV(
						{button_rect.x + 10.0 * g.scale, button_rect.y + button_rect.height / 2.0},
						circle_rad,
						c_col,
					)
					rl_text_draw(
						g,
						.Body,
						cstr,
						{
							button_rect.x + 20.0 * g.scale,
							button_rect.y + (button_rect.height - text_size.y) / 2.0,
						},
						rl.WHITE,
					)
				} else if is_hovered {
					rl.DrawRectangleRec(button_rect, rl.Color{25, 25, 38, 200})
					rl.DrawRectangleLinesEx(button_rect, 1.0, rl.Color{100, 100, 120, 255})
					rl.DrawCircleV(
						{button_rect.x + 10.0 * g.scale, button_rect.y + button_rect.height / 2.0},
						circle_rad,
						c_col,
					)
					rl_text_draw(
						g,
						.Body,
						cstr,
						{
							button_rect.x + 20.0 * g.scale,
							button_rect.y + (button_rect.height - text_size.y) / 2.0,
						},
						rl.WHITE,
					)
				} else {
					rl.DrawRectangleRec(button_rect, rl.Color{20, 20, 30, 120})
					rl.DrawCircleV(
						{button_rect.x + 10.0 * g.scale, button_rect.y + button_rect.height / 2.0},
						circle_rad,
						c_col,
					)
					rl_text_draw(
						g,
						.Body,
						cstr,
						{
							button_rect.x + 20.0 * g.scale,
							button_rect.y + (button_rect.height - text_size.y) / 2.0,
						},
						rl.Color{160, 160, 175, 255},
					)
				}
			}

			curr_x += button_w + 6.0 * g.scale
		}

		// Vertical Separator
		sep_x := g.screenw * 0.72
		rl.DrawLineEx(
			{sep_x, deck_y + 8.0 * g.scale},
			{sep_x, deck_y + deck_h - 8.0 * g.scale},
			1.0,
			rl.Color{40, 40, 55, 255},
		)

		// Right: Cadence Preset Picker
		rl_text_draw(
			g,
			.BodyBold,
			"CADENCE:",
			{
				sep_x + 16.0 * g.scale,
				deck_y + (deck_h - rl_text_measure(g, .BodyBold, "CADENCE:").y) / 2.0,
			},
			rl.Color{130, 130, 150, 255},
		)

		curr_x = sep_x + 100.0 * g.scale
		presets := [4]Emitter_Preset{.Burst, .Steady, .Sustained, .Trickle}
		preset_names := [4]string{"BURST", "STEADY", "SUSTAINED", "TRICKLE"}

		for preset, idx in presets {
			cstr := cstring(raw_data(preset_names[idx]))
			text_size := rl_text_measure(g, .Body, cstr)

			button_w := text_size.x + 24.0 * g.scale
			button_h := f32(24.0) * g.scale

			button_rect := rl.Rectangle {
				curr_x,
				deck_y + (deck_h - button_h) / 2.0,
				button_w,
				button_h,
			}
			g.control_menu.preset_rects[preset] = button_rect

			is_hovered := rl.CheckCollisionPointRec(mouse_screen, button_rect)
			is_selected := preset == g.control_menu.selected_preset

			if is_selected {
				rl.DrawRectangleRec(button_rect, rl.Color{35, 35, 55, 255})
				rl.DrawRectangleLinesEx(button_rect, 1.2, rl.Color{0, 230, 255, 255})
				rl_text_draw(
					g,
					.Body,
					cstr,
					{
						button_rect.x + 12.0 * g.scale,
						button_rect.y + (button_rect.height - text_size.y) / 2.0,
					},
					rl.WHITE,
				)
			} else if is_hovered {
				rl.DrawRectangleRec(button_rect, rl.Color{25, 25, 38, 200})
				rl.DrawRectangleLinesEx(button_rect, 1.0, rl.Color{100, 100, 120, 255})
				rl_text_draw(
					g,
					.Body,
					cstr,
					{
						button_rect.x + 12.0 * g.scale,
						button_rect.y + (button_rect.height - text_size.y) / 2.0,
					},
					rl.WHITE,
				)
			} else {
				rl.DrawRectangleRec(button_rect, rl.Color{20, 20, 30, 120})
				rl_text_draw(
					g,
					.Body,
					cstr,
					{
						button_rect.x + 12.0 * g.scale,
						button_rect.y + (button_rect.height - text_size.y) / 2.0,
					},
					rl.Color{160, 160, 175, 255},
				)
			}

			curr_x += button_w + 6.0 * g.scale
		}
	case .Hardware:
		cstr := cstring("SPECIAL HARDWARE COMING SOON")
		text_size := rl_text_measure(g, .BodyBold, cstr)
		rl_text_draw(
			g,
			.BodyBold,
			cstr,
			{(g.screenw - text_size.x) / 2.0, deck_y + (deck_h - text_size.y) / 2.0},
			rl.Color{100, 100, 110, 128},
		)
	}
}
