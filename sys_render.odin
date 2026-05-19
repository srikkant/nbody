package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

sys_render_init :: proc(g: ^Game) {
	g.render_target = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)
}

sys_render_free :: proc(g: ^Game) {
	rl.UnloadRenderTexture(g.render_target)
	rl.UnloadRenderTexture(g.bg_texture)
}

sys_render :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	sw := f32(ww) / RENDER_WIDTH

	wh := f32(rl.GetScreenHeight())
	sh := f32(wh) / RENDER_HEIGHT

	scale := math.min(sw, sh)
	fw := RENDER_WIDTH * scale
	fh := RENDER_HEIGHT * scale

	off_x := (ww - fw) / 2
	off_y := (wh - fh) / 2

	g.view = rl.Rectangle{off_x, off_y, fw, fh}
	g.view_scale = scale

	rl.BeginTextureMode(g.render_target)

	rl_begin_shader(g, .Bg_Vignette)
	rl.ClearBackground(rl.BLACK)
	rl_texture_draw(g, .Blank, {0, 0, RENDER_WIDTH, RENDER_HEIGHT}, tint = g.theme.color_bg)
	rl_end_shader(g)

	rl.BeginBlendMode(.ADDITIVE)

	rl.BeginMode2D(g.camera)

	g.render_state.orbit_points_count = 0
	g.render_state.objects_count = 0
	g.render_state.collectibles_count = 0
	g.render_state.stars_count = 0

	sys_render_cursor(g)
	sys_render_slingshot(g)
	sys_render_entities(g)

	rl.EndMode2D()

	sys_render_score_panel(g)

	rl.EndTextureMode()

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.DrawTexturePro(
		g.render_target.texture,
		rl.Rectangle {
			0,
			0,
			f32(g.render_target.texture.width),
			f32(-g.render_target.texture.height),
		},
		g.view,
		rl.Vector2(0),
		0,
		rl.WHITE,
	)

	if (g.draw_debug_panel) {
		rl.DrawFPS(rl.GetScreenWidth() - 80, rl.GetScreenHeight() - 30)
	}

	rl.EndDrawing()
}

sys_render_cursor :: proc(g: ^Game) {
	// TODO: Move to a custom texture
	rl.DrawCircle(i32(g.mouse_pos.x), i32(g.mouse_pos.y), 4, rl.WHITE)

	if g.slingshot.active do return

	rl.DrawCircle(
		i32(g.mouse_pos.x),
		i32(g.mouse_pos.y),
		g.params.k_collect_dist,
		rl.Color{255, 255, 255, 64},
	)
}

sys_render_slingshot :: proc(g: ^Game) {
	if !g.slingshot.active do return
	end := g.mouse_pos

	// TODO: Update this
	ss_obj_radius := g.params.radii[.DwarfPlanet]

	// Slingshot trigger
	line_col := g.slingshot.can_launch ? rl.GRAY : rl.RED
	rl.DrawLineEx(g.slingshot.start_pos, end, 1, line_col)
	rl.DrawCircle(
		i32(g.slingshot.start_pos.x),
		i32(g.slingshot.start_pos.y),
		ss_obj_radius,
		rl.Color{255, 255, 255, 255},
	)

	if g.slingshot.preview == 0 || !g.slingshot.can_launch do return

	// Slingshot path: for now, we draw around 1 second worth of path (60 steps)
	pos := g.slingshot.start_pos
	vel := physics_get_slingshot_release_velocity(g, end)

	dt := frame_time() * g.params.sim_rate * 5 // 5x realtime for the preview

	star := &g.entities[Entity(0)]

	frames := g.params.slingshot_preview_len * i32(g.slingshot.preview)

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
	rl.DrawLineStrip(raw_ptr, frames, rl.Color{255, 255, 255, 200})
}

sys_render_entities :: proc(g: ^Game) {
	for id in 0 ..< g.entities_count {
		e := g.entities[id]

		if RENDER_SIG <= e.sig {
			if .Celestial in e.sig {
				// Celestials will be further classified.
				if e.celestial.type == .Star {
					g.render_state.stars[g.render_state.stars_count] = Entity(id)
					g.render_state.stars_count += 1
				} else {
					g.render_state.objects[g.render_state.objects_count] = Entity(id)
					g.render_state.objects_count += 1
				}
			}

			if .Orbit in e.sig {
				g.render_state.orbit_points[g.render_state.orbit_points_count] = Entity(id)
				g.render_state.orbit_points_count += 1
			}

			if .CollectibleEnergy in e.sig {
				g.render_state.collectibles[g.render_state.collectibles_count] = Entity(id)
				g.render_state.collectibles_count += 1
			}
		}
	}

	rl_begin_shader(g, .Stars_Layer)

	shader := g.assets.shaders[g.shaders[.Stars_Layer].shader]
	loc := rl.GetShaderLocation(shader, "seconds")
	rl.SetShaderValue(shader, loc, &g.elapsed, .FLOAT)

	for i in 0 ..< g.render_state.stars_count {
		e := &g.entities[g.render_state.stars[i]]
		r := e.radius
		tint := e.renderable.color

		dest_rect := rl.Rectangle{e.pos.current.x, e.pos.current.y, r * 4, r * 4}
		rl_texture_draw(g, .Objects_Celestial, dest_rect, rl.Vector2(r * 2), tint = tint)
	}

	rl_end_shader(g)

	rl_begin_shader(g, .Objects_Layer)

	for i in 0 ..< g.render_state.objects_count {
		texture: Game_TextureType = .Objects_Celestial

		e := &g.entities[g.render_state.objects[i]]
		r := e.radius
		tint := e.renderable.color

		dest_rect := rl.Rectangle{e.pos.current.x, e.pos.current.y, r * 4, r * 4}
		hit_pos, out_of_bounds := geometry_get_rectangle_intersection_point(
			rl.Rectangle{-g.camera.offset.x, -g.camera.offset.y, RENDER_WIDTH, RENDER_HEIGHT},
			e.pos.current,
			40.0,
		)

		if (out_of_bounds) {
			dest_rect.x = hit_pos.x
			dest_rect.y = hit_pos.y
			texture = .Markers_OutOfBounds
		}

		if .Emitter in e.sig {
			texture = .Objects_Emitter
			tint = e.emitter.emit_color
		}

		rl_texture_draw(g, texture, dest_rect, rl.Vector2(r * 2), tint = tint)
	}

	rl_end_shader(g)

	rl_begin_shader(g, .Objects_Layer)

	for i in 0 ..< g.render_state.collectibles_count {
		e := &g.entities[g.render_state.collectibles[i]]

		rl_texture_draw(
			g,
			.Collectibles_Energy,
			rl.Rectangle{e.pos.current.x, e.pos.current.y, e.radius * 4, e.radius * 4},
			rl.Vector2(e.radius * 2),
			tint = rl.BLUE, // TODO: Change to some collectible energy color
		)
	}

	rl_end_shader(g)

	for i in 0 ..< g.render_state.orbit_points_count {
		e := &g.entities[g.render_state.orbit_points[i]]

		zero: rl.Vector2

		for j in 0 ..< POSITION_TRAIL_LENGTH - 1 {
			start := (e.pos.trail_head + j) % POSITION_TRAIL_LENGTH
			end := (e.pos.trail_head + j + 1) % POSITION_TRAIL_LENGTH

			if e.pos.trail[start] == e.pos.trail[end] do break
			if e.pos.trail[start] == zero || e.pos.trail[end] == zero do continue

			fade_factor := (f32(j) / f32(POSITION_TRAIL_LENGTH))
			trail_col := e.renderable.color
			trail_col.a = u8(255.0 * fade_factor)
			thickness := 2 * e.radius * fade_factor

			rl.DrawLineEx(e.pos.trail[start], e.pos.trail[end], thickness, trail_col)

			if j == POSITION_TRAIL_LENGTH - 2 {
				rl.DrawLineEx(e.pos.trail[end], e.pos.current, e.radius * 2, e.renderable.color)
			}
		}

		ordered_points: [MAX_ORBIT_LENGTH + 1]rl.Vector2
		for j in 0 ..< e.orbit.count {
			// Find the oldest point and work forward
			oldest_index :=
				(e.orbit.head - e.orbit.count + j + MAX_ORBIT_LENGTH) % MAX_ORBIT_LENGTH
			ordered_points[j] = e.orbit.points[oldest_index]
		}

		ordered_points[e.orbit.count] = e.pos.current
		if g.show_orbits {
			rl.DrawLineStrip(
				raw_data(ordered_points[:]),
				i32(e.orbit.count + 1),
				rl.Fade(e.renderable.color, 0.1),
			)
		}
	}
}

sys_render_score_panel :: proc(g: ^Game) {
	draw_pos := rl.Vector2{20, 20}
	size: rl.Vector2

	cstr: cstring

	str := fmt.bprintf(g.render_state.score_energy_buf[:], "energy = %.2f", g.energy)
	cstr = cstring(raw_data(str))
	size = rl_text_measure(g, .Body, cstr)
	rl_text_draw(g, .Body, cstr, draw_pos)


	draw_pos.y += size.y + g.fonts[.Body].size
	str = fmt.bprintf(g.render_state.score_objects_count_buf[:], "objects = %d", g.total_objects)
	cstr = cstring(raw_data(str))
	size = rl_text_measure(g, .Body, cstr)
	rl_text_draw(g, .Body, cstr, draw_pos)

	avg_energy: f64
	for i in 0 ..< RATE_CALC_TICKS {
		avg_energy += g.energy_gains[i] / RATE_CALC_TICKS
	}

	draw_pos.y += size.y + g.fonts[.Body].size
	str = fmt.bprintf(
		g.render_state.score_avg_energy_buf[:],
		"energy gain per s = %.2f",
		avg_energy,
	)
	cstr = cstring(raw_data(str))
	rl_text_draw(g, .Body, cstr, draw_pos)
}
