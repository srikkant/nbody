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

	// Right-side HUD Stats Panel
	stats_width := g.params.ui.menu_width + 40
	stats_rect := rl.Rectangle {
		x      = f32(rl.GetScreenWidth()) - stats_width - sx,
		y      = sy + 45,
		width  = stats_width,
		height = wh - (sy + 45) - sy,
	}
	g.render.stats_panel_rect = stats_rect

	sys_render_ui_stats(g, stats_rect)
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

sys_render_ui_stats :: proc(g: ^Game, rect: rl.Rectangle) {
	if !g.render.show_stats_panel do return

	rl.DrawRectangleRounded(
		rect,
		g.params.ui.menu_border_rounding,
		g.params.ui.menu_segments,
		g.theme.ui_menu_bg_color,
	)

	rl.DrawRectangleRec(rl.Rectangle{rect.x, rect.y, rect.width, 2}, g.theme.ui_menu_accent_color)

	padding := g.params.ui.menu_inner_padding
	y := rect.y + padding + 4

	draw_stat_row :: proc(
		g: ^Game,
		rect: rl.Rectangle,
		y: ^f32,
		key: cstring,
		value: cstring,
		val_color: rl.Color = rl.WHITE,
	) {
		padding := g.params.ui.menu_inner_padding
		item_h: f32 = 16

		rl_text_draw(g, .Body, key, {rect.x + padding, y^}, g.theme.ui_menu_item_color)

		val_size := rl_text_measure(g, .Body, value)
		rl_text_draw(g, .Body, value, {rect.x + rect.width - padding - val_size.x, y^}, val_color)

		y^ += item_h
	}

	draw_section_header :: proc(g: ^Game, rect: rl.Rectangle, y: ^f32, title: cstring) {
		padding := g.params.ui.menu_inner_padding
		rl_text_draw(g, .Menu_Label, title, {rect.x + padding, y^}, g.theme.ui_menu_header_color)
		y^ += 14
	}

	draw_divider :: proc(g: ^Game, rect: rl.Rectangle, y: ^f32) {
		padding := g.params.ui.menu_inner_padding
		y^ += 4
		rl.DrawLineEx(
			{rect.x + padding, y^},
			{rect.x + rect.width - padding, y^},
			1.0,
			g.theme.ui_menu_divider_color,
		)
		y^ += 6
	}

	buf: [128]byte
	str: string

	draw_section_header(g, rect, &y, "system telemetry")

	// FPS
	str = fmt.bprintf(buf[:], "%d", rl.GetFPS())
	buf[len(str)] = 0
	draw_stat_row(g, rect, &y, "fps", cstring(raw_data(str)))

	// DT
	str = fmt.bprintf(buf[:], "%.2f ms", frame_time(g) * 1000.0)
	buf[len(str)] = 0
	draw_stat_row(g, rect, &y, "frame time", cstring(raw_data(str)))

	// Elapsed Time
	minutes := int(g.elapsed) / 60
	seconds := int(g.elapsed) % 60
	str = fmt.bprintf(buf[:], "%02d:%02d", minutes, seconds)
	buf[len(str)] = 0
	draw_stat_row(g, rect, &y, "elapsed time", cstring(raw_data(str)))

	// Active Entities
	active_entities := 0
	for idx in 0 ..< g.entities_count {
		if g.entities[idx].sig != {} {
			active_entities += 1
		}
	}
	str = fmt.bprintf(buf[:], "%d / %d", active_entities, MAX_ENTITIES)
	buf[len(str)] = 0
	draw_stat_row(g, rect, &y, "ecs active load", cstring(raw_data(str)))

	// Camera Zoom
	str = fmt.bprintf(buf[:], "%.2fx", g.camera.zoom)
	buf[len(str)] = 0
	draw_stat_row(g, rect, &y, "camera zoom", cstring(raw_data(str)))

	draw_divider(g, rect, &y)

	draw_section_header(g, rect, &y, "energy grid")

	// Reserves
	str = fmt.bprintf(buf[:], "%.1f", g.energy)
	buf[len(str)] = 0
	draw_stat_row(g, rect, &y, "reserves", cstring(raw_data(str)))

	avg_gain: f64 = 0
	avg_loss: f64 = 0
	for i in 0 ..< AVG_CALC_TICKS {
		avg_gain += g.energy_gains[i] / AVG_CALC_TICKS
		avg_loss += g.energy_losses[i] / AVG_CALC_TICKS
	}
	net_rate := avg_gain - avg_loss

	// Avg Gain
	str = fmt.bprintf(buf[:], "+%.1f /s", avg_gain)
	buf[len(str)] = 0
	draw_stat_row(g, rect, &y, "generation", cstring(raw_data(str)), rl.Color{0, 220, 100, 255})

	// Avg Loss
	str = fmt.bprintf(buf[:], "-%.1f /s", avg_loss)
	buf[len(str)] = 0
	draw_stat_row(g, rect, &y, "kinetic loss", cstring(raw_data(str)), rl.Color{255, 80, 80, 255})

	// Net
	str = fmt.bprintf(buf[:], "%s%.1f /s", net_rate >= 0 ? "+" : "", net_rate)
	buf[len(str)] = 0
	net_col := net_rate >= 0 ? rl.Color{0, 220, 100, 255} : rl.Color{255, 80, 80, 255}
	draw_stat_row(g, rect, &y, "net rate", cstring(raw_data(str)), net_col)

	draw_divider(g, rect, &y)

	// ==========================================
	// ANCHOR STAR
	// ==========================================
	draw_section_header(g, rect, &y, "anchor star spec")

	star_id: Entity = 0
	found_star := false
	for idx in 0 ..< g.entities_count {
		e := &g.entities[idx]
		if e.sig != {} && .Celestial in e.sig && e.celestial.type == .Star {
			star_id = Entity(idx)
			found_star = true
			break
		}
	}

	if found_star {
		star := &g.entities[star_id]

		// Mass
		str = fmt.bprintf(buf[:], "%.1f", star.mass)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "mass", cstring(raw_data(str)))

		// Radius
		str = fmt.bprintf(buf[:], "%.1f", star.radius)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "radius", cstring(raw_data(str)))

		// Live Density
		str = fmt.bprintf(buf[:], "%.2f", star.mass / (star.radius * star.radius))
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "core density", cstring(raw_data(str)))

		// Solar output
		str = fmt.bprintf(buf[:], "%.1f /s", star.energy_source.output)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "output", cstring(raw_data(str)))
	} else {
		draw_stat_row(g, rect, &y, "anchor", "offline", rl.RED)
	}

	draw_divider(g, rect, &y)

	// ==========================================
	// POPULATION SURVEY
	// ==========================================
	draw_section_header(g, rect, &y, "population registry")

	counts: [CelestialType]int
	emitters := 0
	energy_orbs := 0
	for idx in 0 ..< g.entities_count {
		e := &g.entities[idx]
		if e.sig == {} do continue
		if .Celestial in e.sig {
			counts[e.celestial.type] += 1
		}
		if .Emitter in e.sig {
			emitters += 1
		}
		if .CollectibleEnergy in e.sig {
			energy_orbs += 1
		}
	}

	total_planets := 0
	for t in CelestialType {
		if t == .Star || t == .None do continue
		if counts[t] > 0 {
			name := get_celestial_display_name(t)
			str = fmt.bprintf(buf[:], "%d", counts[t])
			buf[len(str)] = 0
			draw_stat_row(g, rect, &y, name, cstring(raw_data(str)), g.params.celestials[t].color)
			total_planets += counts[t]
		}
	}

	if total_planets == 0 {
		draw_stat_row(g, rect, &y, "planets", "none", rl.GRAY)
	}

	if emitters > 0 {
		str = fmt.bprintf(buf[:], "%d", emitters)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "emitters", cstring(raw_data(str)), rl.WHITE)
	}

	if energy_orbs > 0 {
		str = fmt.bprintf(buf[:], "%d", energy_orbs)
		buf[len(str)] = 0
		draw_stat_row(
			g,
			rect,
			&y,
			"energy orbs",
			cstring(raw_data(str)),
			rl.Color{0, 200, 255, 255},
		)
	}

	draw_divider(g, rect, &y)

	// ==========================================
	// TARGET INSPECTOR
	// ==========================================
	draw_section_header(g, rect, &y, "target inspector")

	closest_id, found_target := get_inspected_entity(g)

	if found_target {
		target := &g.entities[closest_id]
		name := get_celestial_display_name(target.celestial.type)

		// Type Class
		draw_stat_row(
			g,
			rect,
			&y,
			"target class",
			name,
			g.params.celestials[target.celestial.type].color,
		)

		// Entity ID
		str = fmt.bprintf(buf[:], "%d", closest_id)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "entity id", cstring(raw_data(str)))

		// Mass
		str = fmt.bprintf(buf[:], "%.1f", target.mass)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "mass", cstring(raw_data(str)))

		// Radius
		str = fmt.bprintf(buf[:], "%.1f", target.radius)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "radius", cstring(raw_data(str)))

		// Position
		str = fmt.bprintf(buf[:], "x:%.0f, y:%.0f", target.pos.current.x, target.pos.current.y)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "coordinates", cstring(raw_data(str)))

		// Velocity
		speed := rl.Vector2Length(target.velocity.current)
		str = fmt.bprintf(buf[:], "%.1f", speed)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "speed", cstring(raw_data(str)))

		// Star distance
		star_pos := found_star ? g.entities[star_id].pos.current : rl.Vector2{0, 0}
		dist := rl.Vector2Distance(target.pos.current, star_pos)
		str = fmt.bprintf(buf[:], "%.1f", dist)
		buf[len(str)] = 0
		draw_stat_row(g, rect, &y, "orbit radius", cstring(raw_data(str)))
	} else {
		draw_stat_row(g, rect, &y, "lock-on", "offline", rl.GRAY)
		draw_stat_row(g, rect, &y, "proximity grid", "[hover cursor]", rl.GRAY)
	}

	// Bottom glowing sci-fi accent line
	rl.DrawRectangleRec(
		rl.Rectangle{rect.x, rect.y + rect.height - 2, rect.width, 2},
		g.theme.ui_menu_accent_color,
	)
}
