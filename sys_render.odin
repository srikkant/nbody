package main

import "core:math"
import rl "vendor:raylib"

sys_render_init :: proc(g: ^Game) {
	g.render_target = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)
	g.bg_texture = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)

	rl.BeginTextureMode(g.bg_texture)
	rl.ClearBackground(rl.Color{0, 0, 0, 0})

	grid_color := rl.Color{0, 183, 255, 60}
	for y_int := -9; y_int <= 9; y_int += 1 {
		y := f32(RENDER_HEIGHT / 2 + y_int * 60)
		rl.DrawLineEx(rl.Vector2{0, y}, rl.Vector2{RENDER_WIDTH, y}, 1.0, grid_color)
	}

	for x_int := -16; x_int <= 16; x_int += 1 {
		x := f32(RENDER_WIDTH / 2 + x_int * 60)
		rl.DrawLineEx(rl.Vector2{x, 0}, rl.Vector2{x, RENDER_HEIGHT}, 1.0, grid_color)
	}

	rl.EndTextureMode()

	for i in 0 ..< BG_STAR_COUNT {
		layer := int(rl.GetRandomValue(0, 2))
		x := f32(rl.GetRandomValue(0, RENDER_WIDTH))
		y := f32(rl.GetRandomValue(0, RENDER_HEIGHT))

		size: f32 = 0.8 + 0.4 * f32(layer)

		blink_speed := f32(rl.GetRandomValue(10, 35)) / 10.0
		blink_phase := f32(rl.GetRandomValue(0, 628)) / 100.0

		color := rl.WHITE
		if rl.GetRandomValue(0, 3) == 0 {
			color = rl.Color{185, 235, 255, 255}
		}

		g.bg_stars[i] = Game_BgStar {
			pos         = rl.Vector2{x, y},
			layer       = layer,
			size        = size,
			blink_speed = blink_speed,
			blink_phase = blink_phase,
			color       = color,
		}
	}
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
	rl.BeginBlendMode(.ADDITIVE)

	sys_render_bg(g)

	rl.BeginMode2D(g.camera)

	for i in Game_RenderLayerType {
		g.render_state.layers[i].count = 0
	}

	sys_render_cursor(g)
	sys_render_slingshot(g)
	sys_render_entities(g)

	rl.EndMode2D()

	sys_render_ui(g)

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

sys_add_entity_to_layer :: proc(g: ^Game, id: Entity, layer: Game_RenderLayerType) {
	g.render_state.layers[layer].entities[g.render_state.layers[layer].count] = Entity(id)
	g.render_state.layers[layer].count += 1
}

sys_render_entities :: proc(g: ^Game) {
	for id in 0 ..< g.entities_count {
		id := Entity(id)
		e := g.entities[id]

		if RENDER_SIG <= e.sig {
			if .Celestial in e.sig {
				// Celestials will be further classified.
				if e.celestial.type == .Star {
					sys_add_entity_to_layer(g, id, .Stars)
				} else {
					sys_add_entity_to_layer(g, id, .Objects)
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

	rl_begin_shader(g, .Stars_Layer)

	shader := g.assets.shaders[g.shaders[.Stars_Layer].shader]
	loc := rl.GetShaderLocation(shader, "seconds")
	rl.SetShaderValue(shader, loc, &g.elapsed, .FLOAT)

	for i in 0 ..< g.render_state.layers[.Stars].count {
		e := &g.entities[g.render_state.layers[.Stars].entities[i]]
		r := e.radius
		tint := e.renderable.color

		dest_rect := rl.Rectangle{e.pos.current.x, e.pos.current.y, r * 4, r * 4}
		rl_texture_draw(g, .Objects_Celestial, dest_rect, rl.Vector2(r * 2), tint = tint)
	}

	rl_end_shader(g)

	rl_begin_shader(g, .Objects_Layer)

	for i in 0 ..< g.render_state.layers[.Objects].count {
		texture: Game_TextureType = .Objects_Celestial

		e := &g.entities[g.render_state.layers[.Objects].entities[i]]
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

	for i in 0 ..< g.render_state.layers[.Collectibles].count {
		e := &g.entities[g.render_state.layers[.Collectibles].entities[i]]

		rl_texture_draw(
			g,
			.Collectibles_Energy,
			rl.Rectangle{e.pos.current.x, e.pos.current.y, e.radius * 4, e.radius * 4},
			rl.Vector2(e.radius * 2),
			tint = rl.BLUE, // TODO: Change to some collectible energy color
		)
	}

	rl_end_shader(g)

	for i in 0 ..< g.render_state.layers[.OrbitPoints].count {
		e := &g.entities[g.render_state.layers[.OrbitPoints].entities[i]]

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

	for i in 0 ..< g.render_state.layers[.Effects].count {
		id := g.render_state.layers[.Effects].entities[i]
		e := &g.entities[id]

		if .Shockwave in e.sig {
			t := e.life.remaining.curr
			dur := e.life.remaining.interval
			fade := dur > 0 ? (1.0 - (t / dur)) : 1.0
			fade = math.clamp(fade, 0.0, 1.0)
			alpha := u8(fade * 255.0)
			col := rl.Color{0, 200, 255, alpha}

			rl.DrawCircleLines(i32(e.pos.current.x), i32(e.pos.current.y), e.radius, col)
			if e.radius > 1 {
				rl.DrawCircleLines(i32(e.pos.current.x), i32(e.pos.current.y), e.radius - 1, col)
			}
			if e.radius > 2 {
				rl.DrawCircleLines(i32(e.pos.current.x), i32(e.pos.current.y), e.radius - 2, col)
			}
		}

		if .ParticleBurst in e.sig {
			t := e.life.remaining.curr
			dur := e.life.remaining.interval
			fade := dur > 0 ? (1.0 - (t / dur)) : 1.0
			fade = math.clamp(fade, 0.0, 1.0)

			for j in 0 ..< e.particle_burst.active_count {
				p := &e.particle_burst.particles[j]
				col := p.color
				col.a = u8(f32(p.color.a) * fade)

				rl.DrawCircle(i32(p.pos.x), i32(p.pos.y), p.size, col)
			}
		}
	}
}

sys_render_bg :: proc(g: ^Game) {
	rl_begin_shader(g, .Bg_Vignette)
	rl.ClearBackground(rl.BLACK)
	rl_texture_draw(g, .Blank, {0, 0, RENDER_WIDTH, RENDER_HEIGHT}, tint = g.theme.color_bg)
	rl_end_shader(g)

	for i in 0 ..< BG_STAR_COUNT {
		star := g.bg_stars[i]

		factor: f32 = 0.06 + 0.1 * f32(star.layer)
		base_alpha: f32 = 0.1 + 0.1 * f32(star.layer)

		shift_x := -g.camera.target.x * factor * g.camera.zoom
		shift_y := -g.camera.target.y * factor * g.camera.zoom

		draw_x := math.mod(star.pos.x + shift_x, RENDER_WIDTH)
		if draw_x < 0 do draw_x += RENDER_WIDTH

		draw_y := math.mod(star.pos.y + shift_y, RENDER_HEIGHT)
		if draw_y < 0 do draw_y += RENDER_HEIGHT

		blink := 0.4 + 0.4 * math.sin(g.elapsed * star.blink_speed + star.blink_phase)

		color := star.color
		color.a = u8(base_alpha * blink * 255.0)

		rl.DrawRectangleV(rl.Vector2{draw_x, draw_y}, rl.Vector2{star.size, star.size}, color)
	}

	rl_begin_shader(g, .BgGrid_Shader)

	shader := g.assets.shaders[g.shaders[.BgGrid_Shader].shader]
	loc := rl.GetShaderLocation(shader, "seconds")
	rl.SetShaderValue(shader, loc, &g.elapsed, .FLOAT)

	rl.DrawTexturePro(
		g.bg_texture.texture,
		rl.Rectangle{0, 0, f32(g.bg_texture.texture.width), -f32(g.bg_texture.texture.height)},
		rl.Rectangle{0, 0, RENDER_WIDTH, RENDER_HEIGHT},
		rl.Vector2{0, 0},
		0,
		rl.WHITE,
	)

	rl_end_shader(g)
}
