//
// DEBUG SYSTEM
// This is almost entirely vibecoded.
//

package game

import "core:c"
import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

sys_debug :: proc(g: ^Game) {
	sys_debug_input(g)
	sys_debug_init_once(g)
	sys_debug_draw_panel(g)
}

sys_debug_input :: proc(g: ^Game) {
	if rl.IsKeyPressed(.D) {
		g.debug.draw_panel = !g.debug.draw_panel
	}

	if !g.debug.draw_panel {
		g.debug.input_blocked = false
		rl.HideCursor()
		return
	}

	rl.ShowCursor()
	debug_rect := debug_get_panel_rect(g)
	g.debug.input_blocked = rl.CheckCollisionPointRec(rl.GetMousePosition(), debug_rect)
}

debug_get_panel_rect :: proc(g: ^Game) -> rl.Rectangle {
	width: f32 = 380
	margin: f32 = 10
	return rl.Rectangle {
		x = g.screenw - width - margin,
		y = margin,
		width = width,
		height = g.screenh - margin * 2,
	}
}

sys_debug_init_once :: proc(g: ^Game) {
	if g.debug.initialized || !g.debug.draw_panel do return

	// Use custom style overrides on Raygui defaults to match Cosmic Space theme
	rl.GuiSetStyle(rl.GuiControl.DEFAULT, c.int(rl.GuiDefaultProperty.TEXT_SIZE), 11)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiDefaultProperty.BACKGROUND_COLOR),
		color_to_int(rl.Color{12, 16, 28, 240}),
	)

	// Normal colors (translucent dark panel, cool light text, dim cyan borders)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.BASE_COLOR_NORMAL),
		color_to_int(rl.Color{12, 16, 28, 240}),
	)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.TEXT_COLOR_NORMAL),
		color_to_int(rl.Color{200, 210, 220, 255}),
	)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.BORDER_COLOR_NORMAL),
		color_to_int(rl.Color{0, 200, 255, 80}),
	)

	// Focused / Hover colors (glowing cyan borders)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.BASE_COLOR_FOCUSED),
		color_to_int(rl.Color{20, 30, 50, 255}),
	)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.TEXT_COLOR_FOCUSED),
		color_to_int(rl.WHITE),
	)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.BORDER_COLOR_FOCUSED),
		color_to_int(rl.Color{0, 230, 255, 255}),
	)

	// Pressed / Slider bar filling colors (cyan highlights)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.BASE_COLOR_PRESSED),
		color_to_int(rl.Color{0, 200, 255, 60}),
	)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.TEXT_COLOR_PRESSED),
		color_to_int(rl.Color{0, 230, 255, 255}),
	)
	rl.GuiSetStyle(
		rl.GuiControl.DEFAULT,
		c.int(rl.GuiControlProperty.BORDER_COLOR_PRESSED),
		color_to_int(rl.Color{0, 230, 255, 255}),
	)

	// Text alignment and padding for toggle buttons to look premium with inline color swatch dots
	rl.GuiSetStyle(
		rl.GuiControl.TOGGLE,
		c.int(rl.GuiControlProperty.TEXT_ALIGNMENT),
		c.int(rl.GuiTextAlignment.TEXT_ALIGN_LEFT),
	)
	rl.GuiSetStyle(rl.GuiControl.TOGGLE, c.int(rl.GuiControlProperty.TEXT_PADDING), 24)

	g.debug.initialized = true

	// Expand initial focus areas
	g.debug.sections_open = {.LaunchControls, .Diagnostics, .Actions}
}

draw_section_header :: proc(
	g: ^Game,
	title: string,
	section: Game_Debug_Section,
	x: f32,
	y: ^f32,
	w: f32,
) -> bool {
	open := section in g.debug.sections_open
	prefix := open ? "[-] " : "[+] "

	buf: [128]byte
	full_title := fmt.bprintf(buf[:], "%s%s", prefix, title)
	full_title_cstr := cstring(raw_data(full_title))

	h: f32 = 24
	rect := rl.Rectangle{x, y^, w, h}

	if rl.GuiButton(rect, full_title_cstr) {
		if open {
			g.debug.sections_open -= {section}
		} else {
			g.debug.sections_open += {section}
		}
		open = !open
	}

	y^ += h + 4
	return open
}

draw_slider :: proc(
	label: cstring,
	val_ptr: ^f32,
	min_val, max_val: f32,
	x: f32,
	y: ^f32,
	w: f32,
) {
	h: f32 = 18

	label_rect := rl.Rectangle{x, y^, w * 0.4, h}
	rl.GuiLabel(label_rect, label)

	slider_rect := rl.Rectangle{x + w * 0.4, y^, w * 0.45, h}

	val_buf: [32]byte
	val_str := fmt.bprintf(val_buf[:], "%.3f", val_ptr^)
	val_cstr := cstring(raw_data(val_str))

	rl.GuiSlider(slider_rect, nil, val_cstr, val_ptr, min_val, max_val)

	y^ += h + 4
}

draw_slider_i32 :: proc(
	label: cstring,
	val_ptr: ^i32,
	min_val, max_val: i32,
	x: f32,
	y: ^f32,
	w: f32,
) {
	h: f32 = 18

	label_rect := rl.Rectangle{x, y^, w * 0.4, h}
	rl.GuiLabel(label_rect, label)

	slider_rect := rl.Rectangle{x + w * 0.4, y^, w * 0.45, h}

	val_buf: [32]byte
	val_str := fmt.bprintf(val_buf[:], "%d", val_ptr^)
	val_cstr := cstring(raw_data(val_str))

	val_f32 := f32(val_ptr^)
	rl.GuiSlider(slider_rect, nil, val_cstr, &val_f32, f32(min_val), f32(max_val))
	val_ptr^ = i32(val_f32)

	y^ += h + 4
}

draw_label_val :: proc(label: cstring, value: cstring, x: f32, y: ^f32, w: f32) {
	h: f32 = 18
	label_rect := rl.Rectangle{x, y^, w * 0.55, h}
	rl.GuiLabel(label_rect, label)

	val_rect := rl.Rectangle{x + w * 0.55, y^, w * 0.45, h}
	rl.GuiLabel(val_rect, value)

	y^ += h + 4
}

draw_color_preview :: proc(label: cstring, color: rl.Color, x: f32, y: ^f32, w: f32) {
	h: f32 = 18
	label_rect := rl.Rectangle{x, y^, w * 0.4, h}
	rl.GuiLabel(label_rect, label)

	swatch_rect := rl.Rectangle{x + w * 0.4, y^ + 2, 40, h - 4}
	rl.DrawRectangleRec(swatch_rect, color)
	rl.DrawRectangleLines(
		i32(swatch_rect.x),
		i32(swatch_rect.y),
		i32(swatch_rect.width),
		i32(swatch_rect.height),
		rl.GRAY,
	)

	y^ += h + 4
}

draw_button :: proc(label: cstring, x: f32, y: ^f32, w: f32) -> bool {
	h: f32 = 22
	rect := rl.Rectangle{x, y^, w, h}
	clicked := rl.GuiButton(rect, label)
	y^ += h + 4
	return clicked
}

spawn_random_celestials :: proc(g: ^Game) {
	for _ in 0 ..< 10 {
		ct := CelestialType(rand.int_range(1, 12)) // Asteroid to SuperJupiter
		pos := rl.Vector2{rand.float32_range(-600.0, 600.0), rand.float32_range(-600.0, 600.0)}
		vel := rl.Vector2{rand.float32_range(-80.0, 80.0), rand.float32_range(-80.0, 80.0)}
		color := get_celestial_color(g, ct)
		push_event(
			g,
			Game_Event_ObjectSpawn {
				pos = pos,
				density = g.params.celestials[ct].density,
				radius = g.params.celestials[ct].radius,
				velocity = vel,
				show_orbit = true,
				renderable = RenderableComponent{color},
				celestial = CelestialComponent{ct},
			},
		)
	}
}

debug_menu_apply_slingshot :: proc(g: ^Game) {
	ct := g.debug.selected_slingshot_celestial
	switch g.debug.selected_slingshot_mode {
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

sys_debug_draw_panel :: proc(g: ^Game) {
	if !g.debug.draw_panel do return

	rl.BeginMode2D(g.camera.rl_cam)
	sys_debug_render_world(g)
	rl.EndMode2D()

	panel_rect := debug_get_panel_rect(g)

	// Render background raygui panel window
	rl.GuiPanel(panel_rect, "DEBUG PANEL (Tweaks & Controls)")

	// Define scrollable viewport bounds
	view_rect := panel_rect
	view_rect.x += 10
	view_rect.y += 30
	view_rect.width -= 20
	view_rect.height -= 40

	// Set content bounding box using height computed from last frame
	content_rect := view_rect
	content_rect.width -= 16 // leave room for scrollbar
	content_rect.height = g.debug.scroll_bounds.height

	actual_view: rl.Rectangle
	rl.GuiScrollPanel(view_rect, nil, content_rect, &g.debug.scroll_offset, &actual_view)

	// Set stable clipping area to only draw inside the scroll view limits (using virtual screen coordinates)
	rl.BeginScissorMode(
		i32(view_rect.x),
		i32(view_rect.y),
		i32(view_rect.width),
		i32(view_rect.height),
	)

	curr_y := view_rect.y + g.debug.scroll_offset.y
	startX := view_rect.x + 8
	w := view_rect.width - 28

	// =========================================================================
	// LAUNCH CONTROLS (UPGRADE MENU)
	// =========================================================================
	if draw_section_header(g, "Launch Controller", .LaunchControls, startX, &curr_y, w) {
		item_h: f32 = 26

		rl.GuiLabel(rl.Rectangle{startX, curr_y, w, 18}, "Launch Mode:")
		curr_y += 20

		active_normal := g.debug.selected_slingshot_mode == .Normal
		prev_active_normal := active_normal
		// Temporarily center text and remove padding for these buttons
		rl.GuiSetStyle(
			rl.GuiControl.TOGGLE,
			c.int(rl.GuiControlProperty.TEXT_ALIGNMENT),
			c.int(rl.GuiTextAlignment.TEXT_ALIGN_CENTER),
		)
		rl.GuiSetStyle(rl.GuiControl.TOGGLE, c.int(rl.GuiControlProperty.TEXT_PADDING), 0)
		rl.GuiToggle(rl.Rectangle{startX, curr_y, w * 0.48, item_h}, "normal", &active_normal)
		if active_normal != prev_active_normal {
			if active_normal {
				g.debug.selected_slingshot_mode = .Normal
				debug_menu_apply_slingshot(g)
			} else {
				active_normal = true
			}
		}

		active_emitter := g.debug.selected_slingshot_mode == .Emitter
		prev_active_emitter := active_emitter
		rl.GuiToggle(
			rl.Rectangle{startX + w * 0.52, curr_y, w * 0.48, item_h},
			"emitter",
			&active_emitter,
		)
		if active_emitter != prev_active_emitter {
			if active_emitter {
				g.debug.selected_slingshot_mode = .Emitter
				debug_menu_apply_slingshot(g)
			} else {
				active_emitter = true
			}
		}
		// Restore left-alignment and padding for subsequent celestial toggles
		rl.GuiSetStyle(
			rl.GuiControl.TOGGLE,
			c.int(rl.GuiControlProperty.TEXT_ALIGNMENT),
			c.int(rl.GuiTextAlignment.TEXT_ALIGN_LEFT),
		)
		rl.GuiSetStyle(rl.GuiControl.TOGGLE, c.int(rl.GuiControlProperty.TEXT_PADDING), 24)

		curr_y += item_h + 8

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12

		rl.GuiLabel(rl.Rectangle{startX, curr_y, w, 18}, "Celestial Selection:")
		curr_y += 20

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

		g.debug.hover_celestial = -1
		for ct, idx in launchable_celestials {
			row_rect := rl.Rectangle{startX, curr_y, w, item_h}
			selected := g.debug.selected_slingshot_celestial == ct

			t_state := selected
			prev_state := t_state

			name_cstr := get_celestial_display_name(ct)

			// Native raygui GuiToggle button
			rl.GuiToggle(row_rect, name_cstr, &t_state)


			if rl.CheckCollisionPointRec(rl.GetMousePosition(), row_rect) {
				g.debug.hover_celestial = idx
			}

			if t_state != prev_state {
				if t_state {
					g.debug.selected_slingshot_celestial = ct
					debug_menu_apply_slingshot(g)
				}
			}

			// Draw premium color dot next to the label (aligned)
			dot_color := g.params.celestials[ct].color
			dot_color.a = 255
			rl.DrawCircle(i32(row_rect.x + 12), i32(row_rect.y + item_h / 2), 3.5, dot_color)

			curr_y += item_h + 4
		}

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// HUD TELEMETRY & DIAGNOSTICS
	// =========================================================================
	if draw_section_header(g, "Telemetry & Diagnostics", .Diagnostics, startX, &curr_y, w) {
		buf: [128]byte
		str: string

		rl.GuiLabel(rl.Rectangle{startX, curr_y, w, 18}, "Diagnostics:")
		curr_y += 18

		// FPS
		str = fmt.bprintf(buf[:], "%d", rl.GetFPS())
		buf[len(str)] = 0
		draw_label_val("fps", cstring(raw_data(str)), startX, &curr_y, w)

		// Frame Time
		str = fmt.bprintf(buf[:], "%.2f ms", g.dt * 1000.0)
		buf[len(str)] = 0
		draw_label_val("frame time", cstring(raw_data(str)), startX, &curr_y, w)

		// Elapsed Time
		minutes := int(g.elapsed) / 60
		seconds := int(g.elapsed) % 60
		str = fmt.bprintf(buf[:], "%02d:%02d", minutes, seconds)
		buf[len(str)] = 0
		draw_label_val("elapsed time", cstring(raw_data(str)), startX, &curr_y, w)

		// ECS Active Entities
		active_entities := 0
		for idx in 0 ..< g.entities_count {
			if g.entities[idx].sig != {} {
				active_entities += 1
			}
		}
		str = fmt.bprintf(buf[:], "%d / %d", active_entities, MAX_ENTITIES)
		buf[len(str)] = 0
		draw_label_val("ecs active load", cstring(raw_data(str)), startX, &curr_y, w)

		// Camera Zoom
		str = fmt.bprintf(buf[:], "%.2fx", g.camera.rl_cam.zoom)
		buf[len(str)] = 0
		draw_label_val("camera zoom", cstring(raw_data(str)), startX, &curr_y, w)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12

		rl.GuiLabel(rl.Rectangle{startX, curr_y, w, 18}, "Energy Grid:")
		curr_y += 18

		// Reserves
		str = fmt.bprintf(buf[:], "%.1f", g.score.energy)
		buf[len(str)] = 0
		draw_label_val("reserves", cstring(raw_data(str)), startX, &curr_y, w)

		avg_gain: f64 = 0
		avg_loss: f64 = 0
		for i in 0 ..< AVG_CALC_TICKS {
			avg_gain += g.score.energy_gains[i] / AVG_CALC_TICKS
			avg_loss += g.score.energy_losses[i] / AVG_CALC_TICKS
		}
		net_rate := avg_gain - avg_loss

		// Avg Gain
		str = fmt.bprintf(buf[:], "+%.1f /s", avg_gain)
		buf[len(str)] = 0
		draw_label_val("generation", cstring(raw_data(str)), startX, &curr_y, w)

		// Avg Loss
		str = fmt.bprintf(buf[:], "-%.1f /s", avg_loss)
		buf[len(str)] = 0
		draw_label_val("kinetic loss", cstring(raw_data(str)), startX, &curr_y, w)

		// Net
		str = fmt.bprintf(buf[:], "%s%.1f /s", net_rate >= 0 ? "+" : "", net_rate)
		buf[len(str)] = 0
		draw_label_val("net rate", cstring(raw_data(str)), startX, &curr_y, w)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12

		// ==========================================
		// POPULATION SURVEY
		// ==========================================
		rl.GuiLabel(rl.Rectangle{startX, curr_y, w, 18}, "Population Registry:")
		curr_y += 18

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
				draw_label_val(name, cstring(raw_data(str)), startX, &curr_y, w)
				total_planets += counts[t]
			}
		}

		if total_planets == 0 {
			draw_label_val("planets", "none", startX, &curr_y, w)
		}

		if emitters > 0 {
			str = fmt.bprintf(buf[:], "%d", emitters)
			buf[len(str)] = 0
			draw_label_val("emitters", cstring(raw_data(str)), startX, &curr_y, w)
		}

		if energy_orbs > 0 {
			str = fmt.bprintf(buf[:], "%d", energy_orbs)
			buf[len(str)] = 0
			draw_label_val("energy orbs", cstring(raw_data(str)), startX, &curr_y, w)
		}

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12

		// ==========================================
		// TARGET INSPECTOR
		// ==========================================
		rl.GuiLabel(rl.Rectangle{startX, curr_y, w, 18}, "Target Inspector:")
		curr_y += 18

		closest_id, found_target := get_inspected_entity(g)

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

		if found_target {
			target := &g.entities[closest_id]
			name := get_celestial_display_name(target.celestial.type)

			draw_label_val("target class", name, startX, &curr_y, w)

			str = fmt.bprintf(buf[:], "%d", closest_id)
			buf[len(str)] = 0
			draw_label_val("entity id", cstring(raw_data(str)), startX, &curr_y, w)

			str = fmt.bprintf(buf[:], "%.1f", target.mass)
			buf[len(str)] = 0
			draw_label_val("mass", cstring(raw_data(str)), startX, &curr_y, w)

			str = fmt.bprintf(buf[:], "%.1f", target.radius)
			buf[len(str)] = 0
			draw_label_val("radius", cstring(raw_data(str)), startX, &curr_y, w)

			str = fmt.bprintf(buf[:], "x:%.0f, y:%.0f", target.pos.current.x, target.pos.current.y)
			buf[len(str)] = 0
			draw_label_val("coordinates", cstring(raw_data(str)), startX, &curr_y, w)

			speed := vec2_length(target.velocity.current)
			str = fmt.bprintf(buf[:], "%.1f", speed)
			buf[len(str)] = 0
			draw_label_val("speed", cstring(raw_data(str)), startX, &curr_y, w)

			star_pos := found_star ? g.entities[star_id].pos.current : rl.Vector2{0, 0}
			dist := rl.Vector2Distance(target.pos.current, star_pos)
			str = fmt.bprintf(buf[:], "%.1f", dist)
			buf[len(str)] = 0
			draw_label_val("orbit radius", cstring(raw_data(str)), startX, &curr_y, w)
		} else {
			draw_label_val("lock-on", "offline", startX, &curr_y, w)
			draw_label_val("proximity grid", "[hover cursor]", startX, &curr_y, w)
		}

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// LIVE STAR MANIPULATION
	// =========================================================================
	if draw_section_header(g, "Live Star Override", .Star, startX, &curr_y, w) {
		star_idx := -1
		for idx in 0 ..< int(g.entities_count) {
			e := &g.entities[idx]
			if e.sig != {} && .Celestial in e.sig && e.celestial.type == .Star {
				star_idx = idx
				break
			}
		}

		if star_idx != -1 {
			star := &g.entities[star_idx]
			draw_slider("Star Mass", &star.mass, 1.0, 2000000.0, startX, &curr_y, w)
			draw_slider("Star Radius", &star.radius, 5.0, 1000.0, startX, &curr_y, w)
			draw_slider(
				"Star Energy Source",
				&star.energy_source.output,
				0.0,
				5000.0,
				startX,
				&curr_y,
				w,
			)
			draw_slider(
				"Star Source Ticker",
				&star.energy_source.timer.interval,
				0.01,
				20.0,
				startX,
				&curr_y,
				w,
			)
			draw_slider("Star Pos X", &star.pos.current.x, -5000.0, 5000.0, startX, &curr_y, w)
			draw_slider("Star Pos Y", &star.pos.current.y, -5000.0, 5000.0, startX, &curr_y, w)
		} else {
			draw_label_val("Anchor Star Status", "NOT FOUND (Offline)", startX, &curr_y, w)
		}

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// PHYSICS CORE
	// =========================================================================
	if draw_section_header(g, "Physics Settings", .Physics, startX, &curr_y, w) {
		draw_slider(
			"Gravity Const",
			&g.params.physics.gravity_constant,
			0.0,
			100.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Softening Factor",
			&g.params.physics.gravity_softening_factor,
			0.0,
			100.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Sim Rate Mult",
			&g.params.physics.simulation_rate_multiplier,
			0.0,
			200.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Max dt Clamp",
			&g.params.physics.max_delta_time_sec,
			0.001,
			1.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"World Radius",
			&g.params.physics.world_radius,
			1000.0,
			200000.0,
			startX,
			&curr_y,
			w,
		)

		// Recompute helper squared fields
		g.params.physics.world_radius_squared =
			g.params.physics.world_radius * g.params.physics.world_radius

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// SLINGSHOT
	// =========================================================================
	if draw_section_header(g, "Slingshot Setup", .Slingshot, startX, &curr_y, w) {
		draw_slider(
			"Launch Power",
			&g.params.physics.slingshot_launch_power,
			0.01,
			50.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider_i32(
			"Preview Length",
			&g.params.physics.slingshot_preview_length,
			1,
			200,
			startX,
			&curr_y,
			w,
		)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// ENERGY ECONOMY
	// =========================================================================
	if draw_section_header(g, "Energy Economy", .Energy, startX, &curr_y, w) {
		draw_slider(
			"Gain Coefficient",
			&g.params.physics.energy_gain_coefficient,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Loss Coefficient",
			&g.params.physics.energy_loss_coefficient,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Gen Coefficient",
			&g.params.physics.energy_generation_coefficient,
			0.0,
			100.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Momentum Coeff",
			&g.params.physics.energy_momentum_coefficient,
			1.0,
			100000.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Star Gen Mult",
			&g.params.physics.star_energy_multiplier,
			0.0,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Collect Distance",
			&g.params.physics.energy_collect_distance,
			5.0,
			2000.0,
			startX,
			&curr_y,
			w,
		)

		// Recompute helper squared fields
		g.params.physics.energy_collect_distance_squared =
			g.params.physics.energy_collect_distance * g.params.physics.energy_collect_distance

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// COLLISIONS & BREAKS
	// =========================================================================
	if draw_section_header(g, "Collisions & Lifecycles", .Collision, startX, &curr_y, w) {
		draw_slider(
			"Collision Mass Scale",
			&g.params.physics.collision_mass_scaling_factor,
			0.1,
			100.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Shatter Base Energy",
			&g.params.physics.shatter_base_energy,
			0.1,
			10000.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Debris Mass Loss Frac",
			&g.params.physics.debris_mass_loss_fraction,
			0.0,
			1.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Collision Max Loss",
			&g.params.physics.collision_debris_max_loss_fraction,
			0.0,
			1.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Collision Speed Coeff",
			&g.params.physics.collision_debris_speed_coefficient,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Spawn Invincibility",
			&g.params.physics.spawn_invincibility_duration_sec,
			0.0,
			30.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Mass Loss Rate",
			&g.params.physics.mass_loss_rate,
			0.0,
			50.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"OOB Refund Fraction",
			&g.params.physics.out_of_bounds_refund_fraction,
			0.0,
			1.0,
			startX,
			&curr_y,
			w,
		)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// CELESTIAL INDIVIDUAL PARAMETERS
	// =========================================================================
	if draw_section_header(g, "Celestial Types Tuning", .Celestials, startX, &curr_y, w) {
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

		nested_sections := [11]Game_Debug_Section {
			.Celestial_Asteroid,
			.Celestial_Moonlet,
			.Celestial_DwarfPlanet,
			.Celestial_SubEarth,
			.Celestial_SuperEarth,
			.Celestial_MegaEarth,
			.Celestial_MiniNeptune,
			.Celestial_SubNeptune,
			.Celestial_SuperNeptune,
			.Celestial_GiantPlanet,
			.Celestial_SuperJupiter,
		}

		for ct, idx in launchable_celestials {
			nested_sec := nested_sections[idx]
			name_cstr := get_celestial_display_name(ct)
			name_str := string(name_cstr)

			// Indent child header
			if draw_section_header(g, name_str, nested_sec, startX + 10, &curr_y, w - 10) {
				p := &g.params.celestials[ct]

				draw_color_preview("Planet Color", p.color, startX + 15, &curr_y, w - 15)
				draw_slider("Density", &p.density, 0.01, 500.0, startX + 15, &curr_y, w - 15)
				draw_slider("Base Radius", &p.radius, 0.1, 500.0, startX + 15, &curr_y, w - 15)
				draw_slider(
					"Launch Cost",
					&p.launch_cost,
					0.0,
					10000.0,
					startX + 15,
					&curr_y,
					w - 15,
				)
				draw_slider(
					"Quad Draw Mult",
					&p.quad_multiplier,
					0.1,
					50.0,
					startX + 15,
					&curr_y,
					w - 15,
				)
				draw_slider(
					"Trail Scale",
					&p.trail_multiplier,
					0.0,
					50.0,
					startX + 15,
					&curr_y,
					w - 15,
				)
				draw_slider(
					"Shader Glow",
					&p.glow_intensity,
					0.0,
					10.0,
					startX + 15,
					&curr_y,
					w - 15,
				)
			}
		}

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// CAMERA PREFERENCES
	// =========================================================================
	if draw_section_header(g, "Camera Configuration", .Camera, startX, &curr_y, w) {
		draw_slider("Zoom Minimum", &g.params.camera.zoom_min, 0.001, 0.1, startX, &curr_y, w)
		draw_slider("Zoom Maximum", &g.params.camera.zoom_max, 1.0, 10.0, startX, &curr_y, w)
		draw_slider(
			"Decay Zoom In",
			&g.params.camera.zoom_in_interpolation_decay,
			0.01,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Decay Zoom Out",
			&g.params.camera.zoom_out_interpolation_decay,
			0.1,
			20.0,
			startX,
			&curr_y,
			w,
		)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// VFX SHOCKWAVES
	// =========================================================================
	if draw_section_header(g, "VFX Shockwaves", .VfxShockwaves, startX, &curr_y, w) {
		draw_slider(
			"Shockwave Init R",
			&g.params.vfx.shockwave_radius_start,
			0.1,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Shockwave Base Dur",
			&g.params.vfx.shockwave_duration_base_sec,
			0.1,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Shockwave Dur Coeff",
			&g.params.vfx.shockwave_duration_ln_coefficient,
			0.0,
			0.5,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Shockwave Growth B",
			&g.params.vfx.shockwave_growth_base,
			1.0,
			500.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Shockwave Growth Co",
			&g.params.vfx.shockwave_growth_sqrt_coefficient,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Shockwave Decel S",
			&g.params.vfx.shockwave_decel_start,
			0.1,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Shockwave Decel De",
			&g.params.vfx.shockwave_decel_decay,
			0.1,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Shockwave Quad Mult",
			&g.params.vfx.shockwave_quad_multiplier,
			0.5,
			10.0,
			startX,
			&curr_y,
			w,
		)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// VFX PARTICLES
	// =========================================================================
	if draw_section_header(g, "VFX Particle Bursts", .VfxParticles, startX, &curr_y, w) {
		draw_slider(
			"Particle Quad Mult",
			&g.params.vfx.particle_quad_multiplier,
			0.5,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Energy Quad Mult",
			&g.params.vfx.energy_quad_multiplier,
			0.5,
			20.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Dur Base",
			&g.params.vfx.particle_burst_duration_base_sec,
			0.1,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Dur Coeff",
			&g.params.vfx.particle_burst_duration_ln_coefficient,
			0.0,
			0.5,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Count Coeff",
			&g.params.vfx.particle_burst_count_sqrt_coefficient,
			0.0,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider_i32(
			"Burst Count Base",
			&g.params.vfx.particle_burst_count_base,
			1,
			200,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Speed Base",
			&g.params.vfx.particle_burst_speed_base,
			1.0,
			200.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Speed Coeff",
			&g.params.vfx.particle_burst_speed_sqrt_coefficient,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Speed Var Min",
			&g.params.vfx.particle_burst_speed_variance_min,
			1.0,
			500.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Speed Var Max",
			&g.params.vfx.particle_burst_speed_variance_max,
			1.0,
			500.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Drag Coeff",
			&g.params.vfx.particle_burst_drag_coefficient,
			0.0,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Size Base",
			&g.params.vfx.particle_burst_size_base,
			0.1,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Size Coeff",
			&g.params.vfx.particle_burst_size_ln_coefficient,
			0.0,
			0.5,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Size Var Min",
			&g.params.vfx.particle_burst_size_variance_min,
			1.0,
			500.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Size Var Max",
			&g.params.vfx.particle_burst_size_variance_max,
			1.0,
			500.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Size Min",
			&g.params.vfx.particle_burst_size_min,
			0.1,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Burst Size Max",
			&g.params.vfx.particle_burst_size_max,
			0.1,
			10.0,
			startX,
			&curr_y,
			w,
		)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// VFX FRAGMENTS
	// =========================================================================
	if draw_section_header(g, "VFX Debris Fragments", .VfxFragments, startX, &curr_y, w) {
		draw_slider_i32(
			"Frag Count Min",
			&g.params.vfx.fragments_count_min,
			1,
			50,
			startX,
			&curr_y,
			w,
		)
		draw_slider_i32(
			"Frag Count Base",
			&g.params.vfx.fragments_count_base,
			1,
			50,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Speed Mult",
			&g.params.vfx.fragments_count_speed_multiplier,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Count Mod",
			&g.params.vfx.fragments_count_mod,
			1.0,
			20.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Divisor Mass",
			&g.params.vfx.fragments_radius_mass_divisor,
			1.0,
			500.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Max Mass",
			&g.params.vfx.fragments_radius_mass_max,
			0.1,
			50.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Pull Dist Mult",
			&g.params.vfx.fragments_pull_distance_multiplier,
			0.1,
			20.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Pull Min Dist",
			&g.params.vfx.fragments_pull_minimum_distance,
			0.01,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Pull Speed B",
			&g.params.vfx.fragments_pull_speed_base,
			10.0,
			1000.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Drift Phase",
			&g.params.vfx.fragments_drift_phase_multiplier,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Freq X",
			&g.params.vfx.fragments_drift_frequency_x,
			0.1,
			20.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Freq Y",
			&g.params.vfx.fragments_drift_frequency_y,
			0.1,
			20.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Amp X",
			&g.params.vfx.fragments_drift_amplitude_x,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Amp Y",
			&g.params.vfx.fragments_drift_amplitude_y,
			0.0,
			5.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Frag Energy Size",
			&g.params.vfx.energy_fragment_size,
			0.1,
			20.0,
			startX,
			&curr_y,
			w,
		)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// WORLD BACKGROUND & GRID
	// =========================================================================
	if draw_section_header(g, "Background Grid", .Background, startX, &curr_y, w) {
		draw_slider(
			"Grid Spacing",
			&g.params.background.grid_spacing,
			5.0,
			200.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Grid Line Width",
			&g.params.background.grid_line_width,
			0.1,
			10.0,
			startX,
			&curr_y,
			w,
		)
		draw_slider(
			"Grid Warp Strength",
			&g.params.background.grid_warp_strength,
			0.0,
			10.0,
			startX,
			&curr_y,
			w,
		)

		rl.GuiLine(rl.Rectangle{startX, curr_y, w, 10}, nil)
		curr_y += 12
	}

	// =========================================================================
	// 13. QUICK ACTIONS
	// =========================================================================
	if draw_section_header(g, "Quick Simulation Actions", .Actions, startX, &curr_y, w) {
		if draw_button("Reset Params to Defaults", startX, &curr_y, w) {
			params_init(&g.params)
		}

		if draw_button("Kill All Non-Star Entities", startX, &curr_y, w) {
			for idx in 0 ..< int(g.entities_count) {
				e := &g.entities[idx]
				if e.sig != {} {
					is_star := .Celestial in e.sig && e.celestial.type == .Star
					if !is_star {
						e.sig = {}
					}
				}
			}
		}

		if draw_button("Spawn 10 Random Bodies", startX, &curr_y, w) {
			spawn_random_celestials(g)
		}

	}

	rl.EndScissorMode()

	// Track scroll content height dynamically for scroll calculations next frame
	content_height := curr_y - (view_rect.y + g.debug.scroll_offset.y)
	if content_height < view_rect.height {
		content_height = view_rect.height
	}
	g.debug.scroll_bounds.height = content_height + 20
}

sys_debug_render_world :: proc(g: ^Game) {
	rl.BeginMode2D(g.camera.rl_cam)
	defer rl.EndMode2D()

	closest_id, found := get_inspected_entity(g)
	if !found do return

	e := &g.entities[closest_id]
	pos := e.pos.current
	radius := e.radius

	pulse := 1.0 + 0.12 * math.sin(g.elapsed * 5.0)
	reticle_radius := radius * 2.2 * pulse

	col := g.theme.ui_menu_item_selected_color
	col.a = 180

	rl.DrawCircleLines(i32(pos.x), i32(pos.y), reticle_radius, col)

	notch_len := clamp(radius * 0.8, 4.0, 30.0)
	rl.DrawLineEx(
		{pos.x - reticle_radius, pos.y - reticle_radius},
		{pos.x - reticle_radius + notch_len, pos.y - reticle_radius},
		1.2,
		col,
	)
	rl.DrawLineEx(
		{pos.x - reticle_radius, pos.y - reticle_radius},
		{pos.x - reticle_radius, pos.y - reticle_radius + notch_len},
		1.2,
		col,
	)
	rl.DrawLineEx(
		{pos.x + reticle_radius, pos.y - reticle_radius},
		{pos.x + reticle_radius - notch_len, pos.y - reticle_radius},
		1.2,
		col,
	)
	rl.DrawLineEx(
		{pos.x + reticle_radius, pos.y - reticle_radius},
		{pos.x + reticle_radius, pos.y - reticle_radius + notch_len},
		1.2,
		col,
	)
	rl.DrawLineEx(
		{pos.x - reticle_radius, pos.y + reticle_radius},
		{pos.x - reticle_radius + notch_len, pos.y + reticle_radius},
		1.2,
		col,
	)
	rl.DrawLineEx(
		{pos.x - reticle_radius, pos.y + reticle_radius},
		{pos.x - reticle_radius, pos.y + reticle_radius - notch_len},
		1.2,
		col,
	)
	rl.DrawLineEx(
		{pos.x + reticle_radius, pos.y + reticle_radius},
		{pos.x + reticle_radius - notch_len, pos.y + reticle_radius},
		1.2,
		col,
	)
	rl.DrawLineEx(
		{pos.x + reticle_radius, pos.y + reticle_radius},
		{pos.x + reticle_radius, pos.y + reticle_radius - notch_len},
		1.2,
		col,
	)
	rl.DrawCircle(i32(pos.x), i32(pos.y), 1.5, col)
}

