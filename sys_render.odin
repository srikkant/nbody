package main

import "core:math"
import rl "vendor:raylib"

redraw_bg_grid :: proc(g: ^Game, ww, wh: f32) {
	rl.BeginTextureMode(g.bg_texture)
	rl.ClearBackground(rl.Color{0, 0, 0, 0})

	grid_color := g.theme.bg_grid_color

	cx := ww / 2
	cy := wh / 2
	spacing := g.params.background.grid_spacing

	// Draw vertical lines from center outwards
	x_count := int(ww / spacing) / 2 + 1
	for x_int := -x_count; x_int <= x_count; x_int += 1 {
		x := cx + f32(x_int) * spacing
		rl.DrawLineEx(rl.Vector2{x, 0}, rl.Vector2{x, wh}, 1.0, grid_color)
	}

	// Draw horizontal lines from center outwards
	y_count := int(wh / spacing) / 2 + 1
	for y_int := -y_count; y_int <= y_count; y_int += 1 {
		y := cy + f32(y_int) * spacing
		rl.DrawLineEx(rl.Vector2{0, y}, rl.Vector2{ww, y}, 1.0, grid_color)
	}

	rl.EndTextureMode()
}

sys_render_init :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())

	g.render.rect = rl.Rectangle{0, 0, ww, wh}
	g.render.scale = 1.0
	g.bg_texture = rl.LoadRenderTexture(i32(ww), i32(wh))
	redraw_bg_grid(g, ww, wh)

	for i in 0 ..< BG_STAR_COUNT {
		layer := 0
		if i >= int(g.params.background.star_layer3_start_index) {
			layer = 3
		} else if i >= int(g.params.background.star_layer2_start_index) {
			layer = 2
		} else if i >= int(g.params.background.star_layer1_start_index) {
			layer = 1
		}

		x :=
			f32(
				rl.GetRandomValue(
					i32(-g.params.background.star_spawn_bounds_x * 10),
					i32(g.params.background.star_spawn_bounds_x * 10),
				),
			) /
			10.0
		y :=
			f32(
				rl.GetRandomValue(
					i32(-g.params.background.star_spawn_bounds_y * 10),
					i32(g.params.background.star_spawn_bounds_y * 10),
				),
			) /
			10.0

		rand_val := f32(rl.GetRandomValue(0, 100)) / 100.0
		size :=
			g.params.background.star_sizes[layer][0] +
			g.params.background.star_sizes[layer][1] * rand_val

		blink_speed :=
			f32(
				rl.GetRandomValue(
					i32(g.params.background.star_blink_speed_min * 10),
					i32(g.params.background.star_blink_speed_max * 10),
				),
			) /
			10.0
		blink_phase :=
			f32(rl.GetRandomValue(0, i32(g.params.background.star_blink_phase_max * 100))) / 100.0

		color := g.theme.star_colors[rl.GetRandomValue(0, 4)]

		g.bg_stars[i] = Game_BgStar {
			pos         = rl.Vector2{x, y},
			layer       = layer,
			size        = size,
			blink_speed = blink_speed,
			blink_phase = blink_phase,
			color       = color,
		}
	}

	for i in 0 ..< BG_NEBULA_COUNT {
		neb_x :=
			f32(
				rl.GetRandomValue(
					i32(-g.params.background.nebula_spawn_bounds_x * 10),
					i32(g.params.background.nebula_spawn_bounds_x * 10),
				),
			) /
			10.0
		neb_y :=
			f32(
				rl.GetRandomValue(
					i32(-g.params.background.nebula_spawn_bounds_y * 10),
					i32(g.params.background.nebula_spawn_bounds_y * 10),
				),
			) /
			10.0

		r_min := g.params.background.nebula_radius_ranges[i][0]
		r_max := g.params.background.nebula_radius_ranges[i][1]
		radius := f32(rl.GetRandomValue(i32(r_min), i32(r_max)))

		s_min := g.params.background.nebula_drift_speed_ranges[i][0]
		s_max := g.params.background.nebula_drift_speed_ranges[i][1]
		drift_speed := f32(rl.GetRandomValue(i32(s_min * 10), i32(s_max * 10))) / 10.0

		drift_phase :=
			f32(rl.GetRandomValue(0, i32(g.params.background.star_blink_phase_max * 100))) / 100.0

		g.bg_nebulae[i] = Game_BgNebula {
			pos         = rl.Vector2{neb_x, neb_y},
			color       = g.theme.bg_nebula_colors[i],
			radius      = radius,
			drift_speed = drift_speed,
			drift_phase = drift_phase,
		}
	}
}

sys_render_free :: proc(g: ^Game) {
	rl.UnloadRenderTexture(g.bg_texture)
}

sys_render :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())

	g.render.rect = rl.Rectangle{0, 0, ww, wh}
	g.render.scale = 1.0

	if g.bg_texture.texture.width != i32(ww) || g.bg_texture.texture.height != i32(wh) {
		rl.UnloadRenderTexture(g.bg_texture)
		g.bg_texture = rl.LoadRenderTexture(i32(ww), i32(wh))
		redraw_bg_grid(g, ww, wh)
	}

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	sys_render_bg(g)

	rl.BeginMode2D(g.camera)

	for i in Game_RenderLayerType {
		g.render.layers[i].count = 0
	}

	sys_render_cursor(g)
	sys_render_slingshot(g)
	sys_render_entities(g)
	sys_render_stats_reticle(g)

	rl.EndMode2D()

	sys_render_ui(g)

	if g.draw_debug_panel {
		rl.DrawFPS(rl.GetScreenWidth() - 80, rl.GetScreenHeight() - 30)
	}

	rl.EndDrawing()
}

sys_render_cursor :: proc(g: ^Game) {
	// TODO: Move to a custom texture?
	rl.DrawCircle(
		i32(g.mouse_pos.x),
		i32(g.mouse_pos.y),
		g.params.ui.cursor_indicator_radius,
		rl.WHITE,
	)

	if g.slingshot.active do return

	rl.DrawCircle(
		i32(g.mouse_pos.x),
		i32(g.mouse_pos.y),
		g.params.physics.energy_collect_distance,
		rl.Color{255, 255, 255, g.theme.ui_collect_area_opacity},
	)
}

sys_render_slingshot :: proc(g: ^Game) {
	if !g.slingshot.active do return
	end := g.mouse_pos

	// TODO: Update this, this should rely on the slingshot output maybe?
	ss_obj_radius := g.params.celestials[.DwarfPlanet].radius

	// Slingshot trigger
	line_col :=
		g.slingshot.can_launch ? g.theme.ui_slingshot_launch_ok_color : g.theme.ui_slingshot_launch_err_color
	rl.DrawLineEx(g.slingshot.start_pos, end, 1, line_col)
	rl.DrawCircle(
		i32(g.slingshot.start_pos.x),
		i32(g.slingshot.start_pos.y),
		ss_obj_radius,
		rl.Color{255, 255, 255, 255},
	)

	if g.slingshot.preview == 0 || !g.slingshot.can_launch do return

	pos := g.slingshot.start_pos
	vel := physics_get_slingshot_release_velocity(g, end)

	dt :=
		frame_time(g) *
		g.params.physics.simulation_rate_multiplier *
		f32(g.params.physics.slingshot_preview_length) // slingshot_preview_len x realtime for the preview

	star := &g.entities[Entity(0)]

	frames := g.params.physics.slingshot_preview_length * i32(g.slingshot.preview)

	g.slingshot.preview_points[0] = g.slingshot.start_pos
	for idx in 1 ..= frames {
		acc, dist := physics_get_gravitational_acceleration(
			g,
			pos,
			ss_obj_radius,
			star.pos.current,
			star.mass,
			star.radius,
		)

		collision := dist < (ss_obj_radius + star.radius) * (ss_obj_radius + star.radius)
		if collision {
			frames = idx
			break
		}

		vel += acc * dt
		pos += vel * dt

		g.slingshot.preview_points[idx] = pos
	}

	raw_ptr := ([^][2]f32)(&g.slingshot.preview_points[0])
	rl.DrawLineStrip(raw_ptr, frames, g.theme.ui_slingshot_preview_color)
}

sys_add_entity_to_layer :: proc(g: ^Game, id: Entity, layer: Game_RenderLayerType) {
	g.render.layers[layer].entities[g.render.layers[layer].count] = Entity(id)
	g.render.layers[layer].count += 1
}

sys_render_get_entity_draw_info :: proc(
	g: ^Game,
	id: Entity,
	qm: f32,
) -> (
	dest: rl.Rectangle,
	texture: Game_TextureType,
	is_oob: bool,
) {
	e := &g.entities[id]
	r := e.radius
	dest = rl.Rectangle{e.pos.current.x, e.pos.current.y, r * qm, r * qm}
	texture = .Objects_Celestial

	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())
	world_screen_rect := rl.Rectangle {
		g.camera.target.x - (ww / 2) / g.camera.zoom,
		g.camera.target.y - (wh / 2) / g.camera.zoom,
		ww / g.camera.zoom,
		wh / g.camera.zoom,
	}

	hit_pos, out_of_bounds := geometry_get_rectangle_intersection_point(
		world_screen_rect,
		e.pos.current,
		g.theme.ui_out_of_bounds_margin,
	)

	if out_of_bounds {
		dest.x = hit_pos.x
		dest.y = hit_pos.y
		texture = .Markers_OutOfBounds
		is_oob = true
	}

	return
}

catmull_rom :: proc(p0, p1, p2, p3: rl.Vector2, t: f32) -> rl.Vector2 {
	t2 := t * t
	t3 := t2 * t
	return(
		0.5 *
		((2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3) \
	)
}


sys_render_entities :: proc(g: ^Game) {
	for id in 0 ..< g.entities_count {
		id := Entity(id)
		e := g.entities[id]

		if RENDER_SIG <= e.sig {
			if .Emitter in e.sig {
				// Emitters always get their own layer (geometric render)
				sys_add_entity_to_layer(g, id, .EmitterStations)
			} else if .Celestial in e.sig {
				cp := g.params.celestials[e.celestial.type]
				switch cp.visual_class {
				case .Debris:
					sys_add_entity_to_layer(g, id, .Debris)
				case .Terrestrial:
					sys_add_entity_to_layer(g, id, .Terrestrial)
				case .GasGiant:
					sys_add_entity_to_layer(g, id, .GasGiant)
				case .Anchor:
					sys_add_entity_to_layer(g, id, .Stars)
				}
			}

			if .Orbit in e.sig {
				sys_add_entity_to_layer(g, id, .OrbitPoints)
			}

			if .CollectibleEnergy in e.sig {
				sys_add_entity_to_layer(g, id, .Collectibles)
			}
		}

		if SHOCKWAVE_SIG <= e.sig || PARTICLE_BURST_SIG <= e.sig {
			sys_add_entity_to_layer(g, id, .Effects)
		}
	}

	rl_begin_shader(g, .Celestial_Debris_Layer)

	for i in 0 ..< g.render.layers[.Debris].count {
		id := g.render.layers[.Debris].entities[i]
		e := &g.entities[id]
		cp := g.params.celestials[e.celestial.type]

		dest_rect, tex, _ := sys_render_get_entity_draw_info(g, id, cp.quad_multiplier)
		rl_texture_draw(g, tex, dest_rect, rl.Vector2(dest_rect.width / 2.0), tint = cp.color)
	}

	rl_end_shader(g)

	rl_begin_shader(g, .Celestial_Terrestrial_Layer)

	shader_terr := g.assets.shaders[g.shaders[.Celestial_Terrestrial_Layer].shader]
	loc_glow_terr := rl.GetShaderLocation(shader_terr, "glow_intensity")

	for i in 0 ..< g.render.layers[.Terrestrial].count {
		id := g.render.layers[.Terrestrial].entities[i]
		e := &g.entities[id]
		cp := g.params.celestials[e.celestial.type]

		rl.SetShaderValue(shader_terr, loc_glow_terr, &cp.glow_intensity, .FLOAT)

		dest_rect, tex, _ := sys_render_get_entity_draw_info(g, id, cp.quad_multiplier)
		rl_texture_draw(g, tex, dest_rect, rl.Vector2(dest_rect.width / 2.0), tint = cp.color)
	}

	rl_end_shader(g)

	rl_begin_shader(g, .Celestial_GasGiant_Layer)

	shader_gas := g.assets.shaders[g.shaders[.Celestial_GasGiant_Layer].shader]
	loc_gas_sec := rl.GetShaderLocation(shader_gas, "seconds")
	loc_glow_gas := rl.GetShaderLocation(shader_gas, "glow_intensity")
	rl.SetShaderValue(shader_gas, loc_gas_sec, &g.elapsed, .FLOAT)

	for i in 0 ..< g.render.layers[.GasGiant].count {
		id := g.render.layers[.GasGiant].entities[i]
		e := &g.entities[id]
		cp := g.params.celestials[e.celestial.type]

		rl.SetShaderValue(shader_gas, loc_glow_gas, &cp.glow_intensity, .FLOAT)

		dest_rect, tex, _ := sys_render_get_entity_draw_info(g, id, cp.quad_multiplier)
		rl_texture_draw(g, tex, dest_rect, rl.Vector2(dest_rect.width / 2.0), tint = cp.color)
	}

	rl_end_shader(g)

	rl_begin_shader(g, .Celestial_Star_Layer)

	shader_star := g.assets.shaders[g.shaders[.Celestial_Star_Layer].shader]
	loc_star_sec := rl.GetShaderLocation(shader_star, "seconds")
	rl.SetShaderValue(shader_star, loc_star_sec, &g.elapsed, .FLOAT)

	for i in 0 ..< g.render.layers[.Stars].count {
		id := g.render.layers[.Stars].entities[i]
		e := &g.entities[id]
		cp := g.params.celestials[e.celestial.type]

		dest_rect, tex, _ := sys_render_get_entity_draw_info(g, id, cp.quad_multiplier)
		rl_texture_draw(g, tex, dest_rect, rl.Vector2(dest_rect.width / 2.0), tint = cp.color)
	}

	rl_end_shader(g)

	for i in 0 ..< g.render.layers[.EmitterStations].count {
		id := g.render.layers[.EmitterStations].entities[i]
		e := &g.entities[id]
		r := e.radius

		dest_rect, tex, is_oob := sys_render_get_entity_draw_info(g, id, 4.0) // Emitter default multiplier
		if is_oob {
			rl_texture_draw(
				g,
				tex,
				dest_rect,
				rl.Vector2(dest_rect.width / 2.0),
				tint = e.emitter.emit_color,
			)
		} else {
			pos := e.pos.current
			color := rl.Color{220, 225, 230, 255}

			// Diamond shape
			// TODO: Maybe move to a custom texture.
			rl.DrawLineEx({pos.x, pos.y - r * 1.5}, {pos.x + r * 1.5, pos.y}, 1.5, color)
			rl.DrawLineEx({pos.x + r * 1.5, pos.y}, {pos.x, pos.y + r * 1.5}, 1.5, color)
			rl.DrawLineEx({pos.x, pos.y + r * 1.5}, {pos.x - r * 1.5, pos.y}, 1.5, color)
			rl.DrawLineEx({pos.x - r * 1.5, pos.y}, {pos.x, pos.y - r * 1.5}, 1.5, color)
			rl.DrawLineEx(
				{pos.x - r * 2, pos.y},
				{pos.x + r * 2, pos.y},
				0.5,
				rl.Color{220, 225, 230, 100},
			)
			rl.DrawLineEx(
				{pos.x, pos.y - r * 2},
				{pos.x, pos.y + r * 2},
				0.5,
				rl.Color{220, 225, 230, 100},
			)
		}
	}

	rl_begin_shader(g, .Energy_Shader)

	energy_shader := g.assets.shaders[g.shaders[.Energy_Shader].shader]
	energy_loc := rl.GetShaderLocation(energy_shader, "seconds")
	rl.SetShaderValue(energy_shader, energy_loc, &g.elapsed, .FLOAT)

	for i in 0 ..< g.render.layers[.Collectibles].count {
		e := &g.entities[g.render.layers[.Collectibles].entities[i]]

		rl_texture_draw(
			g,
			.Collectibles_Energy,
			rl.Rectangle {
				e.pos.current.x,
				e.pos.current.y,
				e.radius * g.params.vfx.energy_quad_multiplier,
				e.radius * g.params.vfx.energy_quad_multiplier,
			},
			rl.Vector2(e.radius * g.params.vfx.energy_quad_multiplier / 2.0),
			tint = rl.WHITE,
		)
	}

	rl_end_shader(g)

	for i in 0 ..< g.render.layers[.OrbitPoints].count {
		e := &g.entities[g.render.layers[.OrbitPoints].entities[i]]

		// Get trail multiplier — skip if 0 (no trail)
		trail_mult: f32 = 1.0
		if .Celestial in e.sig {
			trail_mult = g.params.celestials[e.celestial.type].trail_multiplier
		}
		if trail_mult <= 0.0 do continue

		trail_col_base := e.renderable.color

		valid_pts: [POSITION_TRAIL_LENGTH + 1]rl.Vector2
		valid_count := 0
		zero: rl.Vector2

		for j in 0 ..< POSITION_TRAIL_LENGTH {
			idx := (e.pos.trail_head + j) % POSITION_TRAIL_LENGTH
			if e.pos.trail[idx] != zero {
				valid_pts[valid_count] = e.pos.trail[idx]
				valid_count += 1
			}
		}

		valid_pts[valid_count] = e.pos.current
		valid_count += 1

		if valid_count >= 2 {
			total_steps := (valid_count - 1) * TRAIL_SUBDIVISIONS

			prev_pt := valid_pts[0]
			for step in 1 ..= total_steps {
				seg_f := f32(step) / f32(TRAIL_SUBDIVISIONS)
				seg := int(seg_f)
				local_t := seg_f - f32(seg)

				if seg >= valid_count - 1 {
					seg = valid_count - 2
					local_t = 1.0
				}

				// Catmull-Rom control points with clamped boundary
				i0 := max(seg - 1, 0)
				i1 := seg
				i2 := min(seg + 1, valid_count - 1)
				i3 := min(seg + 2, valid_count - 1)

				curr_pt := catmull_rom(
					valid_pts[i0],
					valid_pts[i1],
					valid_pts[i2],
					valid_pts[i3],
					local_t,
				)

				// Progress 0→1 from oldest to newest
				progress := f32(step) / f32(total_steps)

				// Width tapers continuously: thin at tail → thick at head
				thickness := e.radius * 2.0 * progress * trail_mult

				// Alpha also fades continuously
				col := trail_col_base
				col.a = u8(255.0 * progress * min(trail_mult, 1.0))

				if thickness > 0.1 {
					rl.DrawLineEx(prev_pt, curr_pt, thickness, col)
				}

				prev_pt = curr_pt
			}
		}

		ordered_points: [MAX_ORBIT_LENGTH + 1]rl.Vector2
		for j in 0 ..< e.orbit.count {
			oldest_index :=
				(e.orbit.head - e.orbit.count + j + MAX_ORBIT_LENGTH) % MAX_ORBIT_LENGTH
			ordered_points[j] = e.orbit.points[oldest_index]
		}
		ordered_points[e.orbit.count] = e.pos.current

		if g.show_orbits {
			rl.DrawLineStrip(
				raw_data(ordered_points[:]),
				i32(e.orbit.count + 1),
				rl.Fade(e.renderable.color, 0.2 * min(trail_mult, 1.0)),
			)
		}
	}

	rl_begin_shader(g, .Vfx_Shader)
	vfx_shader := g.assets.shaders[g.shaders[.Vfx_Shader].shader]
	loc_vfx_type := rl.GetShaderLocation(vfx_shader, "u_vfx_type")
	loc_vfx_sec := rl.GetShaderLocation(vfx_shader, "seconds")
	rl.SetShaderValue(vfx_shader, loc_vfx_sec, &g.elapsed, .FLOAT)

	type_shockwave: f32 = 1.0
	rl.SetShaderValue(vfx_shader, loc_vfx_type, &type_shockwave, .FLOAT)

	for i in 0 ..< g.render.layers[.Effects].count {
		id := g.render.layers[.Effects].entities[i]
		e := &g.entities[id]

		if .Shockwave in e.sig {
			t := e.life.remaining.curr
			dur := e.life.remaining.interval
			fade := dur > 0 ? (1.0 - (t / dur)) : 1.0
			fade = math.clamp(fade, 0.0, 1.0)
			alpha := u8(fade * 255.0)
			col := rl.Color{255, 255, 255, alpha}

			size := e.radius * g.params.vfx.shockwave_quad_multiplier
			rl_texture_draw(
				g,
				.Blank,
				rl.Rectangle{e.pos.current.x, e.pos.current.y, size, size},
				rl.Vector2(size / 2.0),
				tint = col,
			)
		}
	}

	type_particle: f32 = 0.0
	rl.SetShaderValue(vfx_shader, loc_vfx_type, &type_particle, .FLOAT)

	for i in 0 ..< g.render.layers[.Effects].count {
		id := g.render.layers[.Effects].entities[i]
		e := &g.entities[id]

		if .ParticleBurst in e.sig {
			t := e.life.remaining.curr
			dur := e.life.remaining.interval
			fade := dur > 0 ? (1.0 - (t / dur)) : 1.0
			fade = math.clamp(fade, 0.0, 1.0)

			for j in 0 ..< e.particle_burst.active_count {
				p := &e.particle_burst.particles[j]
				col := p.color
				col.a = u8(f32(p.color.a) * fade)

				size := p.size * g.params.vfx.particle_quad_multiplier
				rl_texture_draw(
					g,
					.Blank,
					rl.Rectangle{p.pos.x, p.pos.y, size, size},
					rl.Vector2(size / 2.0),
					tint = col,
				)
			}
		}
	}

	rl_end_shader(g)
}

sys_render_bg :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())
	cx := ww / 2.0
	cy := wh / 2.0

	// Torus mapping bounds
	L_x := g.params.background.parallax_torus_width
	L_y := g.params.background.parallax_torus_height

	depths := g.params.background.parallax_layer_depths
	zoom_scales := g.params.background.parallax_layer_zoom_multipliers
	size_zoom_scales := g.params.background.parallax_layer_size_zoom_multipliers

	rl_begin_shader(g, .Bg_Vignette)
	rl.ClearBackground(rl.BLACK)
	rl_texture_draw(g, .Blank, {0, 0, ww, wh}, tint = g.theme.color_bg)
	rl_end_shader(g)

	// Render the nebulae
	for i in 0 ..< BG_NEBULA_COUNT {
		neb := g.bg_nebulae[i]

		depth := g.params.background.nebula_layer_depth
		zoom_scale := g.params.background.nebula_zoom_multiplier

		dx := neb.pos.x - g.camera.target.x / depth
		dy := neb.pos.y - g.camera.target.y / depth

		dx_wrapped := math.mod(dx + L_x / 2.0, L_x)
		if dx_wrapped < 0 do dx_wrapped += L_x
		dx_wrapped -= L_x / 2.0

		dy_wrapped := math.mod(dy + L_y / 2.0, L_y)
		if dy_wrapped < 0 do dy_wrapped += L_y
		dy_wrapped -= L_y / 2.0

		draw_x := cx + dx_wrapped * (1.0 + (g.camera.zoom - 1.0) * zoom_scale)
		draw_y := cy + dy_wrapped * (1.0 + (g.camera.zoom - 1.0) * zoom_scale)

		breath :=
			g.params.background.nebula_pulsation_base +
			g.params.background.nebula_pulsation_amplitude *
				math.sin(g.elapsed * neb.drift_speed + neb.drift_phase)
		draw_radius :=
			neb.radius *
			breath *
			(1.0 + (g.camera.zoom - 1.0) * g.params.background.nebula_zoom_radius_multiplier)
		alpha_scale := clamp(
			g.params.background.nebula_alpha_zoom_numerator / g.camera.zoom,
			g.params.background.nebula_alpha_zoom_min,
			g.params.background.nebula_alpha_zoom_max,
		)

		color_inner := neb.color
		color_inner.a = u8(f32(neb.color.a) * alpha_scale)
		color_outer := neb.color
		color_outer.a = 0

		rl.DrawCircleGradient(i32(draw_x), i32(draw_y), draw_radius, color_inner, color_outer)
	}

	// Render the Starfield
	for i in 0 ..< BG_STAR_COUNT {
		star := g.bg_stars[i]

		depth := depths[star.layer]
		zoom_scale := zoom_scales[star.layer]
		size_zoom_scale := size_zoom_scales[star.layer]

		// Compute parallax relative to camera target
		dx := star.pos.x - g.camera.target.x / depth
		dy := star.pos.y - g.camera.target.y / depth

		dx_wrapped := math.mod(dx + L_x / 2.0, L_x)
		if dx_wrapped < 0 do dx_wrapped += L_x
		dx_wrapped -= L_x / 2.0

		dy_wrapped := math.mod(dy + L_y / 2.0, L_y)
		if dy_wrapped < 0 do dy_wrapped += L_y
		dy_wrapped -= L_y / 2.0

		draw_x := cx + dx_wrapped * (1.0 + (g.camera.zoom - 1.0) * zoom_scale)
		draw_y := cy + dy_wrapped * (1.0 + (g.camera.zoom - 1.0) * zoom_scale)

		padding := g.theme.bg_star_render_padding
		if draw_x < -padding ||
		   draw_x > ww + padding ||
		   draw_y < -padding ||
		   draw_y > wh + padding {
			continue
		}

		draw_size := star.size * (1.0 + (g.camera.zoom - 1.0) * size_zoom_scale)
		draw_size = clamp(
			draw_size,
			g.params.background.star_size_min,
			g.params.background.star_size_max,
		)
		blink :=
			g.theme.bg_star_blink_amp_base +
			g.theme.bg_star_blink_amp_scale *
				math.sin(g.elapsed * star.blink_speed + star.blink_phase)

		alpha_scale: f32 = 1.0
		switch star.layer {
		case 0:
			alpha_scale = clamp(
				g.params.background.star_layer_alpha_clamp_configs[0][0] / g.camera.zoom,
				g.params.background.star_layer_alpha_clamp_configs[0][1],
				g.params.background.star_layer_alpha_clamp_configs[0][2],
			)
		case 1:
			alpha_scale = clamp(
				g.params.background.star_layer_alpha_clamp_configs[1][0] / g.camera.zoom,
				g.params.background.star_layer_alpha_clamp_configs[1][1],
				g.params.background.star_layer_alpha_clamp_configs[1][2],
			)
		case 2:
			alpha_scale = clamp(
				g.camera.zoom * g.params.background.star_layer_alpha_clamp_configs[2][0],
				g.params.background.star_layer_alpha_clamp_configs[2][1],
				g.params.background.star_layer_alpha_clamp_configs[2][2],
			)
		case 3:
			alpha_scale = clamp(
				(g.camera.zoom - g.params.background.star_layer_alpha_clamp_configs[3][0]) /
				g.params.background.star_layer_alpha_clamp_configs[3][0],
				g.params.background.star_layer_alpha_clamp_configs[3][1],
				g.params.background.star_layer_alpha_clamp_configs[3][2],
			)
		}

		color := star.color
		color.a = u8(f32(color.a) * blink * alpha_scale)

		if color.a == 0 do continue

		// Foreground stars (layer 3) use custom lens flare texture.
		// All other layers use the standard soft circular glow texture.
		tex_type: Game_TextureType = star.layer == 3 ? .BgStarFlare : .BgStarGlow

		radius := draw_size
		dest_rect := rl.Rectangle{draw_x, draw_y, radius * 2.0, radius * 2.0}
		origin := rl.Vector2{radius, radius}

		// Apply a randomized rotation to foreground stars so their flares don't all align uniformly
		rotation := f32(0.0)
		if star.layer == 3 {
			rotation = star.blink_phase * 25.0
		}

		rl_texture_draw(g, tex_type, dest_rect, origin, rotation, color)

		if star.layer >= 2 {
			core_radius := radius * 0.28
			if core_radius >= 0.5 {
				core_col := rl.WHITE
				core_col.a = u8(f32(color.a) * 0.92)
				core_rect := rl.Rectangle{draw_x, draw_y, core_radius * 2.0, core_radius * 2.0}
				core_origin := rl.Vector2{core_radius, core_radius}
				rl_texture_draw(g, .BgStarGlow, core_rect, core_origin, 0.0, core_col)
			}
		}
	}

	// Shimmering grid overlay
	rl_begin_shader(g, .BgGrid_Shader)

	shader := g.assets.shaders[g.shaders[.BgGrid_Shader].shader]
	loc := rl.GetShaderLocation(shader, "seconds")
	rl.SetShaderValue(shader, loc, &g.elapsed, .FLOAT)

	rl.DrawTexturePro(
		g.bg_texture.texture,
		rl.Rectangle{0, 0, f32(g.bg_texture.texture.width), -f32(g.bg_texture.texture.height)},
		rl.Rectangle{0, 0, ww, wh},
		rl.Vector2{0, 0},
		0,
		rl.WHITE,
	)

	rl_end_shader(g)
}

sys_render_stats_reticle :: proc(g: ^Game) {
	if !g.render.show_stats_panel do return

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
	// Top Left
	rl.DrawLineEx({pos.x - reticle_radius, pos.y - reticle_radius}, {pos.x - reticle_radius + notch_len, pos.y - reticle_radius}, 1.2, col)
	rl.DrawLineEx({pos.x - reticle_radius, pos.y - reticle_radius}, {pos.x - reticle_radius, pos.y - reticle_radius + notch_len}, 1.2, col)
	// Top Right
	rl.DrawLineEx({pos.x + reticle_radius, pos.y - reticle_radius}, {pos.x + reticle_radius - notch_len, pos.y - reticle_radius}, 1.2, col)
	rl.DrawLineEx({pos.x + reticle_radius, pos.y - reticle_radius}, {pos.x + reticle_radius, pos.y - reticle_radius + notch_len}, 1.2, col)
	// Bottom Left
	rl.DrawLineEx({pos.x - reticle_radius, pos.y + reticle_radius}, {pos.x - reticle_radius + notch_len, pos.y + reticle_radius}, 1.2, col)
	rl.DrawLineEx({pos.x - reticle_radius, pos.y + reticle_radius}, {pos.x - reticle_radius, pos.y + reticle_radius - notch_len}, 1.2, col)
	// Bottom Right
	rl.DrawLineEx({pos.x + reticle_radius, pos.y + reticle_radius}, {pos.x + reticle_radius - notch_len, pos.y + reticle_radius}, 1.2, col)
	rl.DrawLineEx({pos.x + reticle_radius, pos.y + reticle_radius}, {pos.x + reticle_radius, pos.y + reticle_radius - notch_len}, 1.2, col)

	// Draw target indicator line and crosshair
	rl.DrawCircle(i32(pos.x), i32(pos.y), 1.5, col)
}
