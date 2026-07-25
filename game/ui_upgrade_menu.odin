package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

ui_upgrade_menu_get_category_color :: proc(cat: Upgrade_Category) -> rl.Color {
	switch cat {
	case .Physics:
		return rl.Color{60, 200, 255, 255}
	case .Economy:
		return rl.Color{255, 215, 0, 255}
	case .Automation:
		return rl.Color{200, 100, 255, 255}
	case .Hardware:
		return rl.Color{255, 140, 0, 255}
	}
	return rl.WHITE
}

ui_upgrade_menu_calc_viewport :: proc(g: ^Game) -> rl.Rectangle {
	top_margin := (g.theme.margin_top_bar + 40.0) * g.scale
	bot_margin := 60.0 * g.scale
	return rl.Rectangle {
		x = 20.0 * g.scale,
		y = top_margin,
		width = g.screenw - 40.0 * g.scale,
		height = g.screenh - top_margin - bot_margin,
	}
}

ui_upgrade_menu_frame_frontier :: proc(g: ^Game) {
	sum_pos: rl.Vector2
	count: f32 = 0

	for id in Upgrade_Id {
		if id == .None do continue
		state := g.upgrade_states[id]
		if state == .Owned || state == .Available || state == .Maxed {
			def := &UPGRADE_DEFS[id]
			sum_pos += def.pos
			count += 1.0
		}
	}

	if count == 0 {
		for id in Upgrade_Id {
			if id == .None do continue
			if g.upgrade_states[id] != .Hidden {
				def := &UPGRADE_DEFS[id]
				sum_pos += def.pos
				count += 1.0
			}
		}
	}

	if count > 0 {
		avg_pos := sum_pos / count
		g.upgrade_menu.pan = -avg_pos * UPGRADE_NODE_SPACING * g.scale
	} else {
		g.upgrade_menu.pan = {0, 0}
	}

	g.upgrade_menu.framed = true
}

ui_upgrade_menu_draw :: proc(g: ^Game) {
	viewport := ui_upgrade_menu_calc_viewport(g)
	g.upgrade_menu.viewport = viewport

	if !g.upgrade_menu.framed {
		ui_upgrade_menu_frame_frontier(g)
	}

	rl.BeginScissorMode(
		i32(viewport.x),
		i32(viewport.y),
		i32(viewport.width),
		i32(viewport.height),
	)
	defer rl.EndScissorMode()

	viewport_center := rl.Vector2 {
		viewport.x + viewport.width * 0.5,
		viewport.y + viewport.height * 0.5,
	}
	node_r := UPGRADE_NODE_RADIUS * g.scale

	// 1. Calculate node screen centers and record rects
	node_centers: [Upgrade_Id]rl.Vector2
	font_body := g.assets.fonts[.Body].font
	font_bold := g.assets.fonts[.BodyBold].font

	for id in Upgrade_Id {
		if id == .None do continue
		def := &UPGRADE_DEFS[id]
		center := viewport_center + def.pos * UPGRADE_NODE_SPACING * g.scale + g.upgrade_menu.pan
		node_centers[id] = center

		title_cstr := t(g, def.name_msg)
		title_size := rl.MeasureTextEx(font_body, title_cstr, 11 * g.scale, 1)
		box_w := max(2.0 * node_r + 12.0 * g.scale, title_size.x + 8.0 * g.scale)
		box_h := 2.0 * node_r + 34.0 * g.scale

		g.upgrade_menu.node_rects[id] = rl.Rectangle {
			x      = center.x - box_w * 0.5,
			y      = center.y - node_r,
			width  = box_w,
			height = box_h,
		}
	}

	// 2. Draw edge connections
	for id in Upgrade_Id {
		if id == .None do continue
		state := g.upgrade_states[id]
		if state == .Hidden do continue

		def := &UPGRADE_DEFS[id]
		child_center := node_centers[id]
		dest_cat_color := ui_upgrade_menu_get_category_color(def.category)

		for req in def.requires {
			if req == .None do continue
			parent_state := g.upgrade_states[req]
			if parent_state == .Hidden do continue

			parent_center := node_centers[req]

			line_color: rl.Color
			if parent_state == .Owned && (state == .Owned || state == .Maxed) {
				line_color = dest_cat_color
			} else if parent_state == .Owned && state == .Available {
				line_color = rl.Color{dest_cat_color.r, dest_cat_color.g, dest_cat_color.b, 180}
			} else {
				line_color = rl.Color {
					dest_cat_color.r / 3,
					dest_cat_color.g / 3,
					dest_cat_color.b / 3,
					90,
				}
			}

			rl.DrawLineEx(parent_center, child_center, 3.0 * g.scale, line_color)
		}
	}

	// 3. Draw nodes
	for id in Upgrade_Id {
		if id == .None do continue
		state := g.upgrade_states[id]
		if state == .Hidden do continue

		def := &UPGRADE_DEFS[id]
		p := &g.effective_params.upgrades[id]
		center := node_centers[id]
		lvl := g.upgrade_levels[id]
		cat_color := ui_upgrade_menu_get_category_color(def.category)

		switch state {
		case .Silhouette:
			rl.DrawCircleV(center, node_r, rl.Color{20, 22, 30, 180})
			rl.DrawCircleLinesV(center, node_r, rl.Color{80, 85, 100, 150})
			rl.DrawTextEx(
				font_bold,
				"?",
				center - {5 * g.scale, 8 * g.scale},
				16 * g.scale,
				1,
				rl.Color{120, 130, 150, 180},
			)

		case .Locked:
			fill_color := rl.Color{cat_color.r / 4, cat_color.g / 4, cat_color.b / 4, 180}
			ring_color := rl.Color{80, 85, 100, 180}
			rl.DrawCircleV(center, node_r, fill_color)
			rl.DrawCircleLinesV(center, node_r, ring_color)
			rl.DrawTextEx(
				font_bold,
				"x",
				center - {4 * g.scale, 7 * g.scale},
				14 * g.scale,
				1,
				rl.Color{140, 145, 160, 180},
			)

			title_cstr := t(g, def.name_msg)
			title_sz := rl.MeasureTextEx(font_body, title_cstr, 11 * g.scale, 1)
			rl.DrawTextEx(
				font_body,
				title_cstr,
				{center.x - title_sz.x * 0.5, center.y + node_r + 4 * g.scale},
				11 * g.scale,
				1,
				rl.Color{130, 135, 150, 180},
			)

		case .Available:
			can_afford := upgrade_can_afford(g, id)
			fill_color :=
				can_afford ? rl.Color{cat_color.r / 2, cat_color.g / 2, cat_color.b / 2, 200} : rl.Color{cat_color.r / 3, cat_color.g / 3, cat_color.b / 3, 160}
			ring_color := can_afford ? cat_color : rl.Color{130, 130, 140, 180}

			rl.DrawCircleV(center, node_r, fill_color)
			rl.DrawCircleLinesV(center, node_r, ring_color)
			if can_afford {
				rl.DrawCircleLinesV(
					center,
					node_r + 2 * g.scale,
					rl.Color{ring_color.r, ring_color.g, ring_color.b, 120},
				)
			}

			rl.DrawCircleV(center, 4 * g.scale, ring_color)

			title_cstr := t(g, def.name_msg)
			title_sz := rl.MeasureTextEx(font_body, title_cstr, 11 * g.scale, 1)
			rl.DrawTextEx(
				font_body,
				title_cstr,
				{center.x - title_sz.x * 0.5, center.y + node_r + 4 * g.scale},
				11 * g.scale,
				1,
				rl.WHITE,
			)

			cost_cstr := fmt_compact(upgrade_cost(g, id))
			cost_sz := rl.MeasureTextEx(font_bold, cost_cstr, 11 * g.scale, 1)
			cost_color := can_afford ? rl.Color{255, 235, 120, 255} : rl.Color{220, 100, 100, 200}
			rl.DrawTextEx(
				font_bold,
				cost_cstr,
				{center.x - cost_sz.x * 0.5, center.y + node_r + 17 * g.scale},
				11 * g.scale,
				1,
				cost_color,
			)

		case .Owned:
			rl.DrawCircleV(center, node_r, cat_color)
			rl.DrawCircleLinesV(center, node_r, rl.WHITE)

			lvl_cstr := fmt.ctprintf("%d/%d", lvl, p.max_level)
			lvl_sz := rl.MeasureTextEx(font_bold, lvl_cstr, 12 * g.scale, 1)
			rl.DrawTextEx(
				font_bold,
				lvl_cstr,
				center - {lvl_sz.x * 0.5, lvl_sz.y * 0.5},
				12 * g.scale,
				1,
				rl.BLACK,
			)

			title_cstr := t(g, def.name_msg)
			title_sz := rl.MeasureTextEx(font_body, title_cstr, 11 * g.scale, 1)
			rl.DrawTextEx(
				font_body,
				title_cstr,
				{center.x - title_sz.x * 0.5, center.y + node_r + 4 * g.scale},
				11 * g.scale,
				1,
				rl.WHITE,
			)

		case .Maxed:
			// Animated radiant glowing halo
			halo_anim := (math.sin(f64(g.elapsed) * 3.5) + 1.0) * 0.5
			halo_r := node_r + (5.0 + f32(halo_anim) * 4.0) * g.scale
			halo_alpha := u8(100.0 + halo_anim * 120.0)

			// Soft outer ambient glow fill
			rl.DrawCircleV(
				center,
				node_r + 9.0 * g.scale,
				rl.Color{cat_color.r, cat_color.g, cat_color.b, 50},
			)
			// Pulsing halo ring
			rl.DrawCircleLinesV(
				center,
				halo_r,
				rl.Color{cat_color.r, cat_color.g, cat_color.b, halo_alpha},
			)
			rl.DrawCircleLinesV(center, node_r + 3.0 * g.scale, rl.GOLD)

			// Full category color fill
			rl.DrawCircleV(center, node_r, cat_color)
			rl.DrawCircleLinesV(center, node_r, rl.WHITE)

			max_cstr := t(g, .UpgradeMenu_Max)
			max_sz := rl.MeasureTextEx(font_bold, max_cstr, 11 * g.scale, 1)
			rl.DrawTextEx(
				font_bold,
				max_cstr,
				center - {max_sz.x * 0.5, max_sz.y * 0.5},
				11 * g.scale,
				1,
				rl.BLACK,
			)

			title_cstr := t(g, def.name_msg)
			title_sz := rl.MeasureTextEx(font_body, title_cstr, 11 * g.scale, 1)
			rl.DrawTextEx(
				font_body,
				title_cstr,
				{center.x - title_sz.x * 0.5, center.y + node_r + 5 * g.scale},
				11 * g.scale,
				1,
				cat_color,
			)

		case .Hidden:
		}
	}

	// 4. Header Overlay Bar
	header_text := fmt.ctprintf(
		"%s  ·  %s: %d  ·  %s: %s  (%s)",
		t(g, .UpgradeMenu_Header),
		t(g, .UpgradeMenu_Owned),
		upgrade_purchased_count(g),
		t(g, .UpgradeMenu_Energy),
		fmt_compact(g.score.energy),
		t(g, .UpgradeMenu_Hint),
	)
	rl.DrawTextEx(
		font_bold,
		header_text,
		{viewport.x + 10 * g.scale, viewport.y + 10 * g.scale},
		15 * g.scale,
		1,
		rl.Color{200, 220, 245, 230},
	)

	// 5. Draw Hover Tooltip
	if g.upgrade_menu.hover_node != .None {
		id := g.upgrade_menu.hover_node
		state := g.upgrade_states[id]

		if state != .Hidden && state != .Silhouette {
			def := &UPGRADE_DEFS[id]
			p := &g.effective_params.upgrades[id]
			lvl := g.upgrade_levels[id]

			mouse := rl.GetMousePosition()
			tt_w := UPGRADE_TOOLTIP_W * g.scale
			tt_h := 160.0 * g.scale

			tt_x := mouse.x + 15.0 * g.scale
			if tt_x + tt_w > viewport.x + viewport.width {
				tt_x = mouse.x - tt_w - 15.0 * g.scale
			}
			tt_y := mouse.y + 15.0 * g.scale
			if tt_y + tt_h > viewport.y + viewport.height {
				tt_y = mouse.y - tt_h - 15.0 * g.scale
			}

			tt_rect := rl.Rectangle{tt_x, tt_y, tt_w, tt_h}
			cat_color := ui_upgrade_menu_get_category_color(def.category)

			rl.DrawRectangleRec(tt_rect, rl.Color{15, 20, 30, 245})
			rl.DrawRectangleLinesEx(tt_rect, 2.0 * g.scale, cat_color)

			tx := tt_x + 12.0 * g.scale
			ty := tt_y + 10.0 * g.scale

			// Title & Category tag
			rl.DrawTextEx(font_bold, t(g, def.name_msg), {tx, ty}, 16 * g.scale, 1, rl.WHITE)
			ty += 20 * g.scale

			cat_msg: Messages
			switch def.category {
			case .Physics:
				cat_msg = .UpgradeCategory_Physics
			case .Economy:
				cat_msg = .UpgradeCategory_Economy
			case .Automation:
				cat_msg = .UpgradeCategory_Automation
			case .Hardware:
				cat_msg = .UpgradeCategory_Hardware
			}
			rl.DrawTextEx(
				font_body,
				fmt.ctprintf("[%s]", t(g, cat_msg)),
				{tx, ty},
				12 * g.scale,
				1,
				cat_color,
			)
			ty += 18 * g.scale

			// Description
			rl.DrawTextEx(
				font_body,
				t(g, def.desc_msg),
				{tx, ty},
				12 * g.scale,
				1,
				rl.Color{200, 205, 215, 230},
			)
			ty += 22 * g.scale

			// Level & Effect
			lbl_lvl := t(g, .UpgradeMenu_Level)
			lbl_eff := t(g, .UpgradeMenu_Effect)

			#partial switch e in def.effect {
			case Upgrade_Effect_Param:
				eff_curr := fmt_multiplier(e.op, p.magnitude, lvl)
				eff_next := fmt_multiplier(e.op, p.magnitude, min(lvl + 1, p.max_level))
				if lvl >= p.max_level {
					rl.DrawTextEx(
						font_body,
						fmt.ctprintf(
							"%s %d/%d (%s %s)",
							lbl_lvl,
							lvl,
							p.max_level,
							lbl_eff,
							eff_curr,
						),
						{tx, ty},
						12 * g.scale,
						1,
						rl.GOLD,
					)
				} else {
					rl.DrawTextEx(
						font_body,
						fmt.ctprintf(
							"%s %d/%d (%s %s -> %s)",
							lbl_lvl,
							lvl,
							p.max_level,
							lbl_eff,
							eff_curr,
							eff_next,
						),
						{tx, ty},
						12 * g.scale,
						1,
						rl.LIGHTGRAY,
					)
				}
			case Upgrade_Effect_Capability:
				lbl_cap := t(g, .UpgradeMenu_Capability)
				rl.DrawTextEx(
					font_body,
					fmt.ctprintf("%s %v", lbl_cap, e.capability),
					{tx, ty},
					12 * g.scale,
					1,
					rl.GOLD,
				)
			case Upgrade_Effect_Grant:
				lbl_unc := t(g, .UpgradeMenu_Unlocks)
				rl.DrawTextEx(
					font_body,
					fmt.ctprintf("%s %s", lbl_unc, get_celestial_display_name(g, e.celestial)),
					{tx, ty},
					12 * g.scale,
					1,
					rl.GOLD,
				)
			}
			ty += 22 * g.scale

			// Cost & Status line
			lbl_status := t(g, .UpgradeMenu_Status)
			lbl_cost := t(g, .UpgradeMenu_Cost)
			lbl_energy := t(g, .UpgradeMenu_Energy)

			if state == .Maxed {
				rl.DrawTextEx(
					font_bold,
					fmt.ctprintf("%s %s", lbl_status, t(g, .UpgradeMenu_StatusMaxed)),
					{tx, ty},
					13 * g.scale,
					1,
					cat_color,
				)
			} else {
				cost := upgrade_cost(g, id)
				can_afford := upgrade_can_afford(g, id)
				cost_str := fmt_compact(cost)

				if !upgrade_requires_met(g, id) {
					rl.DrawTextEx(
						font_bold,
						fmt.ctprintf("%s %s", lbl_status, t(g, .UpgradeMenu_StatusPrereqLocked)),
						{tx, ty},
						13 * g.scale,
						1,
						rl.Color{230, 100, 100, 255},
					)
				} else if !upgrade_condition_met(g, id) {
					switch def.condition.kind {
					case .None:
					case .Lifetime_Energy_Earned:
						rl.DrawTextEx(
							font_bold,
							fmt.ctprintf(
								t_str(g, .UpgradeMenu_StatusNeedLifetimeEnergy),
								fmt_compact(p.condition_threshold),
							),
							{tx, ty},
							13 * g.scale,
							1,
							rl.Color{230, 100, 100, 255},
						)
					case .Celestial_Discovered:
						rl.DrawTextEx(
							font_bold,
							fmt.ctprintf(
								t_str(g, .UpgradeMenu_StatusNeedCelestial),
								get_celestial_display_name(g, def.condition.celestial),
							),
							{tx, ty},
							13 * g.scale,
							1,
							rl.Color{230, 100, 100, 255},
						)
					case .Upgrades_Purchased:
						rl.DrawTextEx(
							font_bold,
							fmt.ctprintf(
								t_str(g, .UpgradeMenu_StatusNeedUpgrades),
								fmt.ctprintf("%.0f", p.condition_threshold),
							),
							{tx, ty},
							13 * g.scale,
							1,
							rl.Color{230, 100, 100, 255},
						)
					}
				} else if can_afford {
					rl.DrawTextEx(
						font_bold,
						fmt.ctprintf(
							"%s %s %s (%s)",
							lbl_cost,
							cost_str,
							lbl_energy,
							t(g, .UpgradeMenu_ClickToBuy),
						),
						{tx, ty},
						13 * g.scale,
						1,
						rl.GREEN,
					)
				} else {
					rl.DrawTextEx(
						font_bold,
						fmt.ctprintf(
							"%s %s %s (%s)",
							lbl_cost,
							cost_str,
							lbl_energy,
							t(g, .UpgradeMenu_InsufficientEnergy),
						),
						{tx, ty},
						13 * g.scale,
						1,
						rl.Color{230, 100, 100, 255},
					)
				}
			}
		}
	}
}

ui_upgrade_menu_handle_mouse :: proc(g: ^Game) {
	viewport := ui_upgrade_menu_calc_viewport(g)
	mouse := rl.GetMousePosition()

	g.upgrade_menu.hover_node = .None

	// Update hover node
	if rl.CheckCollisionPointRec(mouse, viewport) {
		for id in Upgrade_Id {
			if id == .None do continue
			state := g.upgrade_states[id]
			if state == .Hidden || state == .Silhouette do continue

			rect := g.upgrade_menu.node_rects[id]
			if rl.CheckCollisionPointRec(mouse, rect) {
				g.upgrade_menu.hover_node = id
				break
			}
		}
	}

	// Left Mouse Gesture: Drag to Pan / Release to Buy
	if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec(mouse, viewport) {
		g.upgrade_menu.press_pos = mouse
		g.upgrade_menu.pan_at_press = g.upgrade_menu.pan
		g.upgrade_menu.pan_drag = false
		g.upgrade_menu.pressed_node = g.upgrade_menu.hover_node
	}

	if rl.IsMouseButtonDown(.LEFT) {
		drag_dist := math_vec2_length(mouse - g.upgrade_menu.press_pos)
		if drag_dist > UPGRADE_MENU_DRAG_THRESHOLD * g.scale {
			g.upgrade_menu.pan_drag = true
			g.upgrade_menu.pressed_node = .None

			// Pan canvas
			g.upgrade_menu.pan = g.upgrade_menu.pan_at_press + (mouse - g.upgrade_menu.press_pos)
		}
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		if !g.upgrade_menu.pan_drag && g.upgrade_menu.pressed_node != .None {
			if g.upgrade_menu.pressed_node == g.upgrade_menu.hover_node {
				upgrade_purchase(g, g.upgrade_menu.pressed_node)
			}
		}
		g.upgrade_menu.pressed_node = .None
		g.upgrade_menu.pan_drag = false
	}
}
