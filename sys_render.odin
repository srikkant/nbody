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
	g.elapsed += rl.GetFrameTime()
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

	// Slingshot trigger
	rl.DrawLineEx(g.slingshot.start_pos, end, 1, rl.GRAY)

	if g.slingshot.preview == 0 do return

	// Slingshot path: for now, we draw around 1 second worth of path (60 steps)
	pos := g.slingshot.start_pos
	vel := physics_get_slingshot_release_velocity(g, end)
	draw_radius := g.slingshot.radius

	dt := rl.GetFrameTime() * g.params.sim_rate

	star := &g.entities[Entity(0)]
	frames := g.params.slingshot_preview_len * i32(g.slingshot.preview)
	preview_points := make([^]rl.Vector2, frames + 1)
	preview_points[0] = g.slingshot.start_pos
	preview_points_count: i32 = 1

	rl.DrawCircle(i32(pos.x), i32(pos.y), draw_radius, rl.Color{255, 255, 255, 255})

	for _ in 0 ..= frames {
		acc, dist := physics_get_graviational_acceleration(
			g,
			pos,
			g.slingshot.radius,
			star.pos.current,
			star.size.mass,
			star.size.radius,
		)

		collision :=
			dist <
			(g.slingshot.radius + star.size.radius) * (g.slingshot.radius + star.size.radius)
		if collision do break

		vel += acc * dt
		pos += vel * dt

		preview_points[preview_points_count] = pos
		preview_points_count += 1
	}

	rl.DrawLineStrip(preview_points, preview_points_count, rl.Color{255, 255, 255, 200})
}

sys_render_entities :: proc(g: ^Game) {
	rl.BeginShaderMode(g.shaders.glow)
	for id in 0 ..< g.entities_count {
		e := g.entities[id]

		// TODO: For now, all entities are just drawn as circles
		if RENDER_SIG <= e.sig {
			r := e.size.radius
			dest_rect := rl.Rectangle{e.pos.current.x, e.pos.current.y, r * 2, r * 2}
			origin := rl.Vector2{r, r}

			hit_pos, hit := geometry_get_rectangle_intersection_point(
				rl.Rectangle{-g.camera.offset.x, -g.camera.offset.y, RENDER_WIDTH, RENDER_HEIGHT},
				e.pos.current,
				40.0,
			)

			if (hit) {
				dest_rect.x = hit_pos.x
				dest_rect.y = hit_pos.y
			}

			rl.DrawTexturePro(
				g.textures.star,
				g.textures.star_rect,
				dest_rect,
				origin,
				0,
				rl.WHITE,
			)
		}

	}
	rl.EndShaderMode()
}

sys_render_score_panel :: proc(g: ^Game) {
	x: i32 = 20
	y: i32 = 20

	str := fmt.tprintf("energy = %.1f", g.energy)
	rl.DrawText(strings.clone_to_cstring(str), x, y, 20, rl.WHITE)

	y += 20
	str = fmt.tprintf("objects = %d", g.total_objects)
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
