package main

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

sys_render_init :: proc(g: ^Game) {
	g.render_target = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)

	// TODO: This just draws a tiled images.
	// Needs to be overhauled fully
	g.bg_texture = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)

	rl.BeginTextureMode(g.bg_texture)
	rl.ClearBackground(rl.BLACK)

	tile_size: f32 = 512
	half_tile: f32 = tile_size / 2

	for y: f32 = 0; y < RENDER_HEIGHT; y += 512 {
		for x: f32 = 0; x < RENDER_WIDTH; x += 512 {
			rotation := f32(rl.GetRandomValue(0, 3)) * 90.0

			source_rect := rl.Rectangle{0, 0, tile_size, tile_size}
			dest_rect := rl.Rectangle{x + half_tile, y + half_tile, tile_size, tile_size}
			origin := rl.Vector2{half_tile, half_tile}

			rl.DrawTexturePro(
				g.assets.textures[.Bg],
				source_rect,
				dest_rect,
				origin,
				rotation,
				rl.Color{255, 255, 255, 60},
			)
		}
	}
	rl.EndTextureMode()
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
	rl.ClearBackground(rl.BLACK)
	rl.DrawTexturePro(
		g.bg_texture.texture,
		rl.Rectangle{0, 0, f32(g.bg_texture.texture.width), f32(-g.bg_texture.texture.height)},
		rl.Rectangle{0, 0, RENDER_WIDTH, RENDER_HEIGHT},
		rl.Vector2(0),
		0,
		rl.WHITE,
	)

	rl.BeginMode2D(g.camera)

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

		// TODO: For now, all entities are just drawn as circles
		if RENDER_SIG <= e.sig {
			r := e.radius
			dest_rect := rl.Rectangle{e.pos.current.x, e.pos.current.y, r * 2, r * 2}
			origin := rl.Vector2{r, r}

			hit_pos, out_of_bounds := geometry_get_rectangle_intersection_point(
				rl.Rectangle{-g.camera.offset.x, -g.camera.offset.y, RENDER_WIDTH, RENDER_HEIGHT},
				e.pos.current,
				40.0,
			)

			texture: Game_TextureType = .Objects_Star

			if (out_of_bounds) {
				dest_rect.x = hit_pos.x
				dest_rect.y = hit_pos.y
				texture = .Markers_OutOfBounds
			}

			if .Emitter in e.sig {
				texture = .Objects_Emitter
			}

			if .CollectibleEnergy in e.sig {
				texture = .Collectibles_Energy
			}

			rl_texture_draw(g, texture, dest_rect, origin)

			// Draw the trail if present
			if g.show_trails && TRAIL_SIG <= e.sig {
				ordered_points: [MAX_TRAIL_LENGTH + 1]rl.Vector2

				for i in 0 ..< e.trail.count {
					// Find the oldest point and work forward
					oldest_index :=
						(e.trail.head - e.trail.count + i + MAX_TRAIL_LENGTH) % MAX_TRAIL_LENGTH
					ordered_points[i] = e.trail.points[oldest_index]
				}

				ordered_points[e.trail.count] = e.pos.current
				rl.DrawLineStrip(
					raw_data(ordered_points[:]),
					i32(e.trail.count + 1),
					rl.Fade(e.renderable.color, 0.5),
				)
			}
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
