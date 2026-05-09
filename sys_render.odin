package main

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

sys_render_init :: proc(g: ^Game) {
	g.textures.render = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)
}

sys_render_free :: proc(g: ^Game) {
	rl.UnloadRenderTexture(g.textures.render)
}

sys_render :: proc(g: ^Game) {
	tx := &g.textures.render

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

	rl.BeginTextureMode(g.textures.render)
	rl.ClearBackground(rl.BLACK)
	rl.DrawTexturePro(
		g.textures.bg.texture,
		rl.Rectangle{0, 0, f32(g.textures.bg.texture.width), f32(-g.textures.bg.texture.height)},
		rl.Rectangle{0, 0, RENDER_WIDTH, RENDER_HEIGHT},
		rl.Vector2(0),
		0,
		rl.WHITE,
	)

	rl.BeginMode2D(g.camera)
	sys_render_slingshot(g)
	sys_render_entities(g)

	rl.EndMode2D()

	sys_render_score_panel(g)

	if (g.draw_debug_panel) {
		sys_render_debug_panel(g)
	}

	rl.EndTextureMode()

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.DrawTexturePro(
		tx.texture,
		rl.Rectangle{0, 0, f32(tx.texture.width), f32(-tx.texture.height)},
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

sys_render_slingshot :: proc(g: ^Game) {
	if !g.slingshot.active do return
	end := input_mouse_pos(g)

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
	preview_points := make([^]rl.Vector2, frames + 1)
	preview_points[0] = g.slingshot.start_pos
	preview_points_count: i32 = 1

	for _ in 0 ..= frames {
		acc, dist := physics_get_graviational_acceleration(
			g,
			pos,
			ss_obj_radius,
			star.pos.current,
			star.mass,
			star.radius,
		)

		collision := dist < (ss_obj_radius + star.radius) * (ss_obj_radius + star.radius)
		if collision do break

		vel += acc * dt
		pos += vel * dt

		preview_points[preview_points_count] = pos
		preview_points_count += 1
	}

	rl.DrawLineStrip(preview_points, preview_points_count, rl.Color{255, 255, 255, 200})
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

			texture_rect := g.textures.star_rect
			if (out_of_bounds) {
				dest_rect.x = hit_pos.x
				dest_rect.y = hit_pos.y
				texture_rect = g.textures.marker_rect
			}

			if .Emitter in e.sig {
				texture_rect = g.textures.emitter_rect
			}

			rl.DrawTexturePro(g.textures.atlas, texture_rect, dest_rect, origin, 0, rl.WHITE)

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
					rl.Fade(rl.WHITE, 0.5),
				)
			}
		}

	}
}

sys_render_score_panel :: proc(g: ^Game) {
	x: i32 = 20
	y: i32 = 20

	str := fmt.tprintf("energy = %f", g.energy)
	rl.DrawText(strings.clone_to_cstring(str), x, y, 20, rl.WHITE)

	y += 20
	str = fmt.tprintf("energy gain per s = %f", g.energy_gain_rate)
	rl.DrawText(strings.clone_to_cstring(str), x, y, 20, rl.WHITE)

	y += 20
	str = fmt.tprintf("objects = %d", g.total_objects)
	rl.DrawText(strings.clone_to_cstring(str), x, y, 20, rl.WHITE)

	// Star stats are only for debugging for now

	y += 20
	str = fmt.tprintf("star mass = %f", g.entities[0].mass)
	rl.DrawText(strings.clone_to_cstring(str), x, y, 20, rl.WHITE)

	y += 20
	str = fmt.tprintf("star radius = %f", g.entities[0].radius)
	rl.DrawText(strings.clone_to_cstring(str), x, y, 20, rl.WHITE)
}

sys_render_debug_panel :: proc(g: ^Game) {
	// Draw score over time as a graph
	graph_y: i32 = RENDER_HEIGHT - 20
	steps := int(math.floor(g.elapsed))

	for s in 0 ..< steps - 1 {
		x1: i32 = i32(s)
		x2: i32 = x1 + 1
		// TODO: scale this graph to larger steps as energy grows
		y1: i32 = graph_y - i32(g.energy_over_time[s] / 100)
		y2: i32 = graph_y - i32(g.energy_over_time[s + 1] / 100)
		rl.DrawLine(x1, y1, x2, y2, rl.WHITE)
	}
}
