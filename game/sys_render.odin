package game

import "core:math"
import rl "vendor:raylib"

sys_render :: proc(g: ^Game) {
	g.render.rect = rl.Rectangle{0, 0, g.screenw, g.screenh}
	g.render.scale = 1.0

	rl.BeginMode2D(g.camera.rl_cam)

	for i in Render_LayerType {
		g.render.layers[i].count = 0
	}

	sys_render_slingshot(g)
	sys_render_entities(g)

	rl.EndMode2D()
}

sys_render_slingshot_trigger :: proc(g: ^Game) {
	star := &g.entities[Entity_Id(0)]

	drag := g.slingshot.end_pos - g.slingshot.start_pos
	pull_dist := math_vec2_length(drag)
	P0 := g.slingshot.start_pos
	P2 := g.slingshot.end_pos
	mid := (P0 + P2) / 2.0

	// Curve towards central star
	to_star := star.pos.current - mid
	to_star_norm := rl.Vector2Normalize(to_star)
	grav_pull := to_star_norm * clamp(pull_dist * f32(0.12), f32(0.0), f32(50.0))

	// Side bow sag perpendicular to pull
	drag_dir := rl.Vector2Normalize(drag)
	perp := rl.Vector2{-drag_dir.y, drag_dir.x}
	bow_sag := perp * (pull_dist * f32(0.08))

	P1 := mid + grav_pull + bow_sag

	BEZIER_STEPS :: 20
	prev_point := P0
	for step in 1 ..= BEZIER_STEPS {
		t_val := f32(step) / f32(BEZIER_STEPS)
		one_minus_t := f32(1.0) - t_val
		curr_point :=
			one_minus_t * one_minus_t * P0 +
			f32(2.0) * one_minus_t * t_val * P1 +
			t_val * t_val * P2

		line_col :=
			g.slingshot.can_launch ? g.theme.color_slingshot_trail : g.theme.color_slingshot_trail_error
		line_col.a = u8(math.lerp(f32(220.0), f32(90.0), t_val))

		rl.DrawLineEx(prev_point, curr_point, 1.2, line_col)
		prev_point = curr_point
	}
}

sys_render_slingshot_preview :: proc(g: ^Game) {
	actual_frames := i32(g.slingshot.preview_count)
	if actual_frames == 0 do return

	// Draw base preview
	for i in 0 ..< actual_frames {
		pt := g.slingshot.preview_points[i]
		t_val := f32(i) / f32(actual_frames)
		dot_col := g.slingshot.obj_color
		dot_col.a = u8(math.lerp(f32(255.0), f32(0.0), t_val))

		rl.DrawCircleV(pt, g.slingshot.obj_radius, dot_col)
	}

	// Shimmer for the preview
	if actual_frames > 0 {
		total_sim_time := g.slingshot.preview_times[actual_frames - 1]
		if total_sim_time > 0.0 {
			g.slingshot.shimmer_time = math.mod(g.slingshot.shimmer_time + g.dt, total_sim_time)

			if g.slingshot.shimmer_time < total_sim_time {
				shimmer_idx := 0
				best_diff := math.abs(g.slingshot.preview_times[0] - g.slingshot.shimmer_time)
				for i in 1 ..< actual_frames {
					diff := math.abs(g.slingshot.preview_times[i] - g.slingshot.shimmer_time)
					if diff < best_diff {
						best_diff = diff
						shimmer_idx = int(i)
					}
				}

				rl.BeginBlendMode(.ADDITIVE)

				TRAIL_LEN :: 10 // points to draw for the shimmer
				for k in 0 ..< TRAIL_LEN {
					idx := shimmer_idx - k
					if idx >= 0 && idx < int(actual_frames) {
						pt := g.slingshot.preview_points[idx]
						trail_t := f32(k) / f32(TRAIL_LEN)

						shimmer_glow_col := g.slingshot.obj_color
						shimmer_glow_col.a = u8(f32(255.0) * (f32(1.0) - trail_t))

						rl.DrawCircleV(pt, g.slingshot.obj_radius, shimmer_glow_col)
					}
				}

				rl.EndBlendMode()
			}
		}
	}
}

sys_render_slingshot :: proc(g: ^Game) {
	if g.slingshot.status != .Active do return

	sys_render_slingshot_trigger(g)
	sys_render_slingshot_preview(g)
}

sys_add_entity_to_layer :: proc(g: ^Game, id: Entity_Id, layer: Render_LayerType) {
	g.render.layers[layer].entities[g.render.layers[layer].count] = Entity_Id(id)
	g.render.layers[layer].count += 1
}

sys_render_draw_celestial_entity :: proc(g: ^Game, id: Entity_Id) {
	e := &g.entities[id]
	cp := g.params.celestials[e.celestial.type]
	qm := cp.quad_multiplier
	rect := rl.Rectangle{e.pos.current.x, e.pos.current.y, e.radius * qm, e.radius * qm}

	rl_texture_draw(g, .Objects_Celestial, rect, rl.Vector2(rect.width / 2.0), tint = cp.color)
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

		if SHOCKWAVE_SIG <= e.sig {
			sys_add_entity_to_layer(g, id, .Effects)
		}
	}

	{
		rl_begin_shader(g, .Celestial_Debris_Layer)
		defer rl_end_shader(g)

		layer := &g.render.layers[.Debris]
		for id in layer.entities[:layer.count] {
			sys_render_draw_celestial_entity(g, id)
		}
	}

	{
		rl_begin_shader(g, .Celestial_Terrestrial_Layer)
		defer rl_end_shader(g)

		shader_terr := assets_get_shader(g, .Celestial_Terrestrial_Layer)
		loc_glow_terr := rl.GetShaderLocation(shader_terr, "glow_intensity")

		layer := &g.render.layers[.Terrestrial]
		for id in layer.entities[:layer.count] {
			e := &g.entities[id]
			cp := g.params.celestials[e.celestial.type]
			rl.SetShaderValue(shader_terr, loc_glow_terr, &cp.glow_intensity, .FLOAT)

			sys_render_draw_celestial_entity(g, id)
		}
	}

	{
		rl_begin_shader(g, .Celestial_GasGiant_Layer)
		defer rl_end_shader(g)

		shader_gas := assets_get_shader(g, .Celestial_GasGiant_Layer)

		loc_gas_sec := rl.GetShaderLocation(shader_gas, "seconds")
		loc_glow_gas := rl.GetShaderLocation(shader_gas, "glow_intensity")
		rl.SetShaderValue(shader_gas, loc_gas_sec, &g.elapsed, .FLOAT)

		layer := &g.render.layers[.GasGiant]
		for id in layer.entities[:layer.count] {
			e := &g.entities[id]
			cp := g.params.celestials[e.celestial.type]
			rl.SetShaderValue(shader_gas, loc_glow_gas, &cp.glow_intensity, .FLOAT)
			sys_render_draw_celestial_entity(g, id)
		}
	}

	{
		rl_begin_shader(g, .Celestial_Star_Layer)
		defer rl_end_shader(g)

		shader_star := assets_get_shader(g, .Celestial_Star_Layer)
		loc_star_sec := rl.GetShaderLocation(shader_star, "seconds")
		rl.SetShaderValue(shader_star, loc_star_sec, &g.elapsed, .FLOAT)

		for i in 0 ..< g.render.layers[.Stars].count {
			id := g.render.layers[.Stars].entities[i]
			sys_render_draw_celestial_entity(g, id)
		}
	}

	{
		layer := &g.render.layers[.EmitterStations]
		for id in layer.entities[:layer.count] {
			e := &g.entities[id]
			r := e.radius
			p := e.pos.current
			color := rl.Color{220, 225, 230, 255}

			// Diamond shape
			// TODO: Maybe move to a custom texture.
			rl.DrawLineEx({p.x, p.y - r * 1.5}, {p.x + r * 1.5, p.y}, 1.5, color)
			rl.DrawLineEx({p.x + r * 1.5, p.y}, {p.x, p.y + r * 1.5}, 1.5, color)
			rl.DrawLineEx({p.x, p.y + r * 1.5}, {p.x - r * 1.5, p.y}, 1.5, color)
			rl.DrawLineEx({p.x - r * 1.5, p.y}, {p.x, p.y - r * 1.5}, 1.5, color)
			rl.DrawLineEx(
				{p.x - r * 2, p.y},
				{p.x + r * 2, p.y},
				0.5,
				rl.Color{220, 225, 230, 100},
			)
			rl.DrawLineEx(
				{p.x, p.y - r * 2},
				{p.x, p.y + r * 2},
				0.5,
				rl.Color{220, 225, 230, 100},
			)
		}
	}

	{
		if g.render.show_orbits {
			layer := &g.render.layers[.OrbitPoints]
			for id in layer.entities[:layer.count] {
				e := &g.entities[id]

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

						i0 := max(seg - 1, 0)
						i1 := seg
						i2 := min(seg + 1, valid_count - 1)
						i3 := min(seg + 2, valid_count - 1)

						curr_pt := math_catmull_rom(
							valid_pts[i0],
							valid_pts[i1],
							valid_pts[i2],
							valid_pts[i3],
							local_t,
						)

						progress := f32(step) / f32(total_steps)
						thickness := e.radius * 2.0 * progress * trail_mult
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

				rl.DrawLineStrip(
					raw_data(ordered_points[:]),
					i32(e.orbit.count + 1),
					rl.Fade(e.renderable.color, 0.35 * min(trail_mult, 1.0)),
				)
			}
		}
	}
	{
		rl_begin_shader(g, .Energy_Shader)
		defer rl_end_shader(g)

		energy_shader := assets_get_shader(g, .Energy_Shader)
		energy_loc := rl.GetShaderLocation(energy_shader, "seconds")
		rl.SetShaderValue(energy_shader, energy_loc, &g.elapsed, .FLOAT)

		layer := &g.render.layers[.Collectibles]
		for id in layer.entities[:layer.count] {
			e := &g.entities[id]

			rl_texture_draw(
				g,
				.Collectibles_Energy,
				rl.Rectangle{e.pos.current.x, e.pos.current.y, e.radius, e.radius},
				rl.Vector2(e.radius / 2.0),
				tint = rl.WHITE,
			)
		}
	}

	{
		rl_begin_shader(g, .Vfx_Shader)
		defer rl_end_shader(g)

		vfx_shader := assets_get_shader(g, .Vfx_Shader)
		loc_vfx_sec := rl.GetShaderLocation(vfx_shader, "seconds")

		rl.SetShaderValue(vfx_shader, loc_vfx_sec, &g.elapsed, .FLOAT)

		layer := &g.render.layers[.Effects]
		for id in layer.entities[:layer.count] {
			e := &g.entities[id]

			if .Shockwave in e.sig {
				t := e.life.remaining.curr
				dur := e.life.remaining.interval
				fade := dur > 0 ? (1.0 - (t / dur)) : 1.0
				fade = math.clamp(fade, 0.0, 1.0)
				col := e.shockwave.color
				col.a = u8(fade * 255.0)

				rl_texture_draw(
					g,
					.Blank,
					rl.Rectangle{e.pos.current.x, e.pos.current.y, e.radius * 2.0, e.radius * 2.0},
					rl.Vector2(e.radius),
					tint = col,
				)
			}
		}
	}
}
