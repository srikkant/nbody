package game

import "core:math"
import rl "vendor:raylib"


sys_render_init :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())

	g.render.rect = rl.Rectangle{0, 0, ww, wh}
	g.render.scale = 1.0

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
}

sys_render :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())

	g.render.rect = rl.Rectangle{0, 0, ww, wh}
	g.render.scale = 1.0

	sys_render_bg(g)

	rl.BeginMode2D(g.camera)

	for i in Game_RenderLayerType {
		g.render.layers[i].count = 0
	}

	sys_render_cursor(g)
	sys_render_slingshot(g)
	sys_render_entities(g)

	rl.EndMode2D()

	sys_render_ui(g)
}

sys_render_cursor :: proc(g: ^Game) {
	// If mouse is hovering over custom UI / input blocked, don't draw custom cursor in world space
	if g.input_blocked do return

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
				rl.Fade(e.renderable.color, 0.35 * min(trail_mult, 1.0)),
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

	// Gravity-distorted world grid overlay
	rl_begin_shader(g, .BgGrid_Shader)

	shader := g.assets.shaders[g.shaders[.BgGrid_Shader].shader]

	loc_seconds := rl.GetShaderLocation(shader, "seconds")
	rl.SetShaderValue(shader, loc_seconds, &g.elapsed, .FLOAT)

	camera_target := g.camera.target
	loc_camera_target := rl.GetShaderLocation(shader, "camera_target")
	rl.SetShaderValue(shader, loc_camera_target, &camera_target, .VEC2)

	camera_zoom := g.camera.zoom
	loc_camera_zoom := rl.GetShaderLocation(shader, "camera_zoom")
	rl.SetShaderValue(shader, loc_camera_zoom, &camera_zoom, .FLOAT)

	screen_size := rl.Vector2{ww, wh}
	loc_screen_size := rl.GetShaderLocation(shader, "screen_size")
	rl.SetShaderValue(shader, loc_screen_size, &screen_size, .VEC2)

	grid_spacing := g.params.background.grid_spacing
	loc_grid_spacing := rl.GetShaderLocation(shader, "grid_spacing")
	rl.SetShaderValue(shader, loc_grid_spacing, &grid_spacing, .FLOAT)

	grid_line_width := g.params.background.grid_line_width
	loc_grid_line_width := rl.GetShaderLocation(shader, "grid_line_width")
	rl.SetShaderValue(shader, loc_grid_line_width, &grid_line_width, .FLOAT)

	grid_col_normalized := rl.Vector4 {
		f32(g.theme.bg_grid_color.r) / 255.0,
		f32(g.theme.bg_grid_color.g) / 255.0,
		f32(g.theme.bg_grid_color.b) / 255.0,
		f32(g.theme.bg_grid_color.a) / 255.0,
	}
	loc_grid_color := rl.GetShaderLocation(shader, "grid_color")
	rl.SetShaderValue(shader, loc_grid_color, &grid_col_normalized, .VEC4)

	gravity_constant := g.params.physics.gravity_constant
	loc_gravity_constant := rl.GetShaderLocation(shader, "gravity_constant")
	rl.SetShaderValue(shader, loc_gravity_constant, &gravity_constant, .FLOAT)

	warp_strength := g.params.background.grid_warp_strength
	loc_warp_strength := rl.GetShaderLocation(shader, "warp_strength")
	rl.SetShaderValue(shader, loc_warp_strength, &warp_strength, .FLOAT)

	wells, well_count := sys_render_collect_gravity_wells(g)
	loc_well_count := rl.GetShaderLocation(shader, "well_count")
	rl.SetShaderValue(shader, loc_well_count, &well_count, .INT)

	if well_count > 0 {
		loc_wells := rl.GetShaderLocation(shader, "wells")
		rl.SetShaderValueV(shader, loc_wells, &wells[0], .VEC4, well_count)
	}

	rl_texture_draw(g, .Blank, {0, 0, ww, wh})

	rl_end_shader(g)
}

sys_render_collect_gravity_wells :: proc(
	g: ^Game,
) -> (
	wells: [MAX_GRID_WELLS]rl.Vector4,
	count: i32,
) {
	// A small struct for sorting
	WellInfo :: struct {
		pos:       rl.Vector2,
		mass:      f32,
		radius:    f32,
		influence: f32,
	}

	temp_wells: [MAX_ENTITIES]WellInfo
	temp_count := 0

	for i in 0 ..< g.entities_count {
		if temp_count >= MAX_ENTITIES do break

		e := &g.entities[i]
		if !(PHYSICS_SIG <= e.sig) do continue
		if e.mass <= 0.0 do continue

		diff := e.pos.current - g.camera.target
		dist_sq := diff.x * diff.x + diff.y * diff.y
		influence := e.mass / (dist_sq + 1.0)

		temp_wells[temp_count] = WellInfo {
			pos       = e.pos.current,
			mass      = e.mass,
			radius    = e.radius,
			influence = influence,
		}
		temp_count += 1
	}

	if g.slingshot.active && temp_count < MAX_ENTITIES {
		launch_type: CelestialType
		switch out in g.slingshot.output {
		case Game_SlingshotOutput_Emitter:
			launch_type = out.emitter.emit_celestial.type
		case Game_SlingshotOutput_Celestial:
			launch_type = out.celestial.type
		}
		density := g.params.celestials[launch_type].density
		radius := g.params.celestials[launch_type].radius
		payload_mass := density * (radius * radius)
		pull_dist := rl.Vector2Distance(g.slingshot.start_pos, g.mouse_pos)

		slingshot_well_mass := (payload_mass + 50.0) * (pull_dist / 100.0) * 1.5
		slingshot_well_mass = clamp(slingshot_well_mass, 20.0, 1500.0)
		slingshot_well_radius := radius * 2.5

		diff := g.slingshot.start_pos - g.camera.target
		dist_sq := diff.x * diff.x + diff.y * diff.y
		influence := slingshot_well_mass / (dist_sq + 1.0)

		temp_wells[temp_count] = WellInfo {
			pos       = g.slingshot.start_pos,
			mass      = slingshot_well_mass,
			radius    = slingshot_well_radius,
			influence = influence,
		}
		temp_count += 1
	}

	// Sort temp_wells by influence descending (simple insertion sort)
	for i in 1 ..< temp_count {
		key := temp_wells[i]
		j := i - 1
		for j >= 0 && temp_wells[j].influence < key.influence {
			temp_wells[j + 1] = temp_wells[j]
			j = j - 1
		}
		temp_wells[j + 1] = key
	}

	count = i32(min(temp_count, MAX_GRID_WELLS))
	for i in 0 ..< count {
		w := temp_wells[i]
		wells[i] = rl.Vector4{w.pos.x, w.pos.y, w.mass, w.radius}
	}

	return wells, count
}
