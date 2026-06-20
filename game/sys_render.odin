package game

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

sys_render_generate_bg_stars :: proc(g: ^Game) {
	p := &g.params.background

	for i in 0 ..< BG_STAR_COUNT {
		layer := 0
		if i >= int(p.star_layer3_start_index) {
			layer = 3
		} else if i >= int(p.star_layer2_start_index) {
			layer = 2
		} else if i >= int(p.star_layer1_start_index) {
			layer = 1
		}

		x := rand.float32_range(-p.star_spawn_bounds_x, p.star_spawn_bounds_x)
		y := rand.float32_range(-p.star_spawn_bounds_y, p.star_spawn_bounds_y)

		rand_val := rand.float32()
		size := p.star_sizes[layer][0] + p.star_sizes[layer][1] * rand_val

		blink_speed := rand.float32_range(p.star_blink_speed_min, p.star_blink_speed_max)
		blink_phase := rand.float32_range(0.0, p.star_blink_phase_max)

		color := rand.choice(g.theme.star_colors[:])

		g.render.bg.stars[i] = Render_Background_Star {
			pos         = rl.Vector2{x, y},
			layer       = layer,
			size        = size,
			blink_speed = blink_speed,
			blink_phase = blink_phase,
			color       = color,
		}
	}

}

sys_render_generate_bg_nebulae :: proc(g: ^Game) {
	p := &g.params.background
	for i in 0 ..< BG_NEBULA_COUNT {
		neb_x := rand.float32_range(-p.nebula_spawn_bounds_x, p.nebula_spawn_bounds_x)
		neb_y := rand.float32_range(-p.nebula_spawn_bounds_y, p.nebula_spawn_bounds_y)

		r_min := p.nebula_radius_ranges[i][0]
		r_max := p.nebula_radius_ranges[i][1]
		radius := rand.float32_range(r_min, r_max)

		s_min := p.nebula_drift_speed_ranges[i][0]
		s_max := p.nebula_drift_speed_ranges[i][1]
		drift_speed := rand.float32_range(s_min, s_max)

		drift_phase := rand.float32_range(0.0, p.star_blink_phase_max)

		g.render.bg.nebulae[i] = Render_Background_Nebula {
			pos         = rl.Vector2{neb_x, neb_y},
			color       = g.theme.bg_nebula_colors[i],
			radius      = radius,
			drift_speed = drift_speed,
			drift_phase = drift_phase,
		}
	}
}

sys_render_init :: proc(g: ^Game) {
	sys_render_generate_bg_stars(g)
	sys_render_generate_bg_nebulae(g)
}

sys_render_free :: proc(g: ^Game) {}

sys_render :: proc(g: ^Game) {
	g.render.rect = rl.Rectangle{0, 0, g.screenw, g.screenh}
	g.render.scale = 1.0

	sys_render_bg(g)

	rl.BeginMode2D(g.camera.rl_cam)

	for i in Render_LayerType {
		g.render.layers[i].count = 0
	}

	sys_render_slingshot(g)
	sys_render_entities(g)
	sys_render_cursor(g)

	rl.EndMode2D()

	sys_render_ui(g)
}

sys_render_cursor :: proc(g: ^Game) {
	rl.DrawCircle(
		i32(g.input.mouse_pos.x),
		i32(g.input.mouse_pos.y),
		g.params.ui.cursor_indicator_radius,
		rl.WHITE,
	)

	if g.slingshot.status == .Active do return

	rl.DrawCircle(
		i32(g.input.mouse_pos.x),
		i32(g.input.mouse_pos.y),
		g.params.physics.cursor_distance,
		rl.Color{255, 255, 255, g.theme.ui_collect_area_opacity},
	)
}

sys_add_entity_to_layer :: proc(g: ^Game, id: Entity_Id, layer: Render_LayerType) {
	g.render.layers[layer].entities[g.render.layers[layer].count] = Entity_Id(id)
	g.render.layers[layer].count += 1
}

sys_render_get_entity_draw_info :: proc(
	g: ^Game,
	id: Entity_Id,
	qm: f32,
) -> (
	dest: rl.Rectangle,
	texture: Assets_TextureType,
	is_oob: bool,
) {
	e := &g.entities[id]
	r := e.radius
	dest = rl.Rectangle{e.pos.current.x, e.pos.current.y, r * qm, r * qm}
	texture = .Objects_Celestial

	world_screen_rect := rl.Rectangle {
		g.camera.rl_cam.target.x - (g.screenw / 2) / g.camera.rl_cam.zoom,
		g.camera.rl_cam.target.y - (g.screenh / 2) / g.camera.rl_cam.zoom,
		g.screenw / g.camera.rl_cam.zoom,
		g.screenh / g.camera.rl_cam.zoom,
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
		id := Entity_Id(id)
		e := g.entities[id]

		if RENDER_SIG <= e.sig {
			if .Emitter in e.sig {
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

	shader_terr := assets_get_shader(g, .Celestial_Terrestrial_Layer)
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

	shader_gas := assets_get_shader(g, .Celestial_GasGiant_Layer)
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

	shader_star := assets_get_shader(g, .Celestial_Star_Layer)
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

	energy_shader := assets_get_shader(g, .Energy_Shader)
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

		if g.render.show_orbits {
			rl.DrawLineStrip(
				raw_data(ordered_points[:]),
				i32(e.orbit.count + 1),
				rl.Fade(e.renderable.color, 0.35 * min(trail_mult, 1.0)),
			)
		}
	}

	rl_begin_shader(g, .Vfx_Shader)
	vfx_shader := assets_get_shader(g, .Vfx_Shader)
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
	cx := g.screenw / 2.0
	cy := g.screenh / 2.0

	L_x := g.params.background.parallax_torus_width
	L_y := g.params.background.parallax_torus_height

	depths := g.params.background.parallax_layer_depths
	zoom_scales := g.params.background.parallax_layer_zoom_multipliers
	size_zoom_scales := g.params.background.parallax_layer_size_zoom_multipliers

	rl_begin_shader(g, .Bg_Vignette)
	rl.ClearBackground(rl.BLACK)
	rl_texture_draw(g, .Blank, {0, 0, g.screenw, g.screenh}, tint = g.theme.color_bg)
	rl_end_shader(g)

	// Render the nebulae
	for i in 0 ..< BG_NEBULA_COUNT {
		neb := g.render.bg.nebulae[i]

		depth := g.params.background.nebula_layer_depth
		zoom_scale := g.params.background.nebula_zoom_multiplier

		dx := neb.pos.x - g.camera.rl_cam.target.x / depth
		dy := neb.pos.y - g.camera.rl_cam.target.y / depth

		dx_wrapped := math.mod(dx + L_x / 2.0, L_x)
		if dx_wrapped < 0 do dx_wrapped += L_x
		dx_wrapped -= L_x / 2.0

		dy_wrapped := math.mod(dy + L_y / 2.0, L_y)
		if dy_wrapped < 0 do dy_wrapped += L_y
		dy_wrapped -= L_y / 2.0

		draw_x := cx + dx_wrapped * (1.0 + (g.camera.rl_cam.zoom - 1.0) * zoom_scale)
		draw_y := cy + dy_wrapped * (1.0 + (g.camera.rl_cam.zoom - 1.0) * zoom_scale)

		breath :=
			g.params.background.nebula_pulsation_base +
			g.params.background.nebula_pulsation_amplitude *
				math.sin(g.elapsed * neb.drift_speed + neb.drift_phase)
		draw_radius :=
			neb.radius *
			breath *
			(1.0 +
					(g.camera.rl_cam.zoom - 1.0) *
						g.params.background.nebula_zoom_radius_multiplier)

		alpha_scale := clamp(
			g.params.background.nebula_alpha_zoom_numerator / g.camera.rl_cam.zoom,
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
		star := g.render.bg.stars[i]

		depth := depths[star.layer]
		zoom_scale := zoom_scales[star.layer]
		size_zoom_scale := size_zoom_scales[star.layer]

		// Compute parallax relative to camera target
		dx := star.pos.x - g.camera.rl_cam.target.x / depth
		dy := star.pos.y - g.camera.rl_cam.target.y / depth

		dx_wrapped := math.mod(dx + L_x / 2.0, L_x)
		if dx_wrapped < 0 do dx_wrapped += L_x
		dx_wrapped -= L_x / 2.0

		dy_wrapped := math.mod(dy + L_y / 2.0, L_y)
		if dy_wrapped < 0 do dy_wrapped += L_y
		dy_wrapped -= L_y / 2.0

		draw_x := cx + dx_wrapped * (1.0 + (g.camera.rl_cam.zoom - 1.0) * zoom_scale)
		draw_y := cy + dy_wrapped * (1.0 + (g.camera.rl_cam.zoom - 1.0) * zoom_scale)

		padding := g.theme.bg_star_render_padding
		if draw_x < -padding ||
		   draw_x > g.screenw + padding ||
		   draw_y < -padding ||
		   draw_y > g.screenh + padding {
			continue
		}

		draw_size := star.size * (1.0 + (g.camera.rl_cam.zoom - 1.0) * size_zoom_scale)
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
				g.params.background.star_layer_alpha_clamp_configs[0][0] / g.camera.rl_cam.zoom,
				g.params.background.star_layer_alpha_clamp_configs[0][1],
				g.params.background.star_layer_alpha_clamp_configs[0][2],
			)
		case 1:
			alpha_scale = clamp(
				g.params.background.star_layer_alpha_clamp_configs[1][0] / g.camera.rl_cam.zoom,
				g.params.background.star_layer_alpha_clamp_configs[1][1],
				g.params.background.star_layer_alpha_clamp_configs[1][2],
			)
		case 2:
			alpha_scale = clamp(
				g.camera.rl_cam.zoom * g.params.background.star_layer_alpha_clamp_configs[2][0],
				g.params.background.star_layer_alpha_clamp_configs[2][1],
				g.params.background.star_layer_alpha_clamp_configs[2][2],
			)
		case 3:
			alpha_scale = clamp(
				(g.camera.rl_cam.zoom - g.params.background.star_layer_alpha_clamp_configs[3][0]) /
				g.params.background.star_layer_alpha_clamp_configs[3][0],
				g.params.background.star_layer_alpha_clamp_configs[3][1],
				g.params.background.star_layer_alpha_clamp_configs[3][2],
			)
		}

		color := star.color
		color.a = u8(f32(color.a) * blink * alpha_scale)

		if color.a == 0 do continue

		tex_type: Assets_TextureType = star.layer == 3 ? .Bg_StarFlare : .Bg_StarGlow

		radius := draw_size
		dest_rect := rl.Rectangle{draw_x, draw_y, radius * 2.0, radius * 2.0}
		origin := rl.Vector2{radius, radius}

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
				rl_texture_draw(g, .Bg_StarGlow, core_rect, core_origin, 0.0, core_col)
			}
		}
	}
}

