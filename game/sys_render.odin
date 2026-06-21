package game

import "core:math"
import rl "vendor:raylib"

sys_render_init :: proc(g: ^Game) {
}

sys_render_free :: proc(g: ^Game) {}

sys_render :: proc(g: ^Game) {
	g.render.rect = rl.Rectangle{0, 0, g.screenw, g.screenh}
	g.render.scale = 1.0

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
		g.theme.cursor_size,
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
			rl.Rectangle{e.pos.current.x, e.pos.current.y, e.radius, e.radius},
			rl.Vector2(e.radius / 2.0),
			tint = rl.WHITE,
		)
	}

	rl_end_shader(g)

	for i in 0 ..< g.render.layers[.OrbitPoints].count {
		e := &g.entities[g.render.layers[.OrbitPoints].entities[i]]

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
	loc_vfx_sec := rl.GetShaderLocation(vfx_shader, "seconds")

	rl.SetShaderValue(vfx_shader, loc_vfx_sec, &g.elapsed, .FLOAT)

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

			rl_texture_draw(
				g,
				.Blank,
				rl.Rectangle{e.pos.current.x, e.pos.current.y, e.radius, e.radius},
				rl.Vector2(e.radius / 2.0),
				tint = col,
			)
		}
	}
}

