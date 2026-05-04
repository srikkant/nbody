package main

import "core:encoding/uuid/legacy"
import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

sys_render :: proc(g: ^Game) {
	g.elapsed += rl.GetFrameTime()
	tx := &g.render_texture

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

	rl.BeginTextureMode(g.render_texture)
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(g.camera)
	sys_render_entities(g)
	sys_render_slingshot(g)

	rl.EndMode2D()

	sys_render_score(g)

	if (g.draw_debug_panel) {
		sys_render_debug_panel(g)
	}

	rl.EndTextureMode()

	rl.BeginDrawing()
	rl.ClearBackground(rl.DARKGRAY)

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

	// Slingshot end
	rl.DrawCircle(i32(end.x), i32(end.y), g.slingshot.radius, rl.GRAY)
	// Slingshot trigger
	rl.DrawLineEx(g.slingshot.start_pos, end, 1, rl.GRAY)

	// Slingshot path: for now, we draw around 1 second worth of path (60 steps)
	pos := g.slingshot.start_pos
	vel := physics_get_slingshot_release_velocity(g.slingshot.start_pos, end)
	draw_radius := g.slingshot.radius
	end_radius := g.slingshot.radius * 0.25

	dt := rl.GetFrameTime() * SLINGSHOT_PREVIEW_DT_MULTIPLIER

	star := &g.entities[Entity(0)]
	frames := SLINGSHOT_PREVIEW_FRAME_COUNT

	for s in 0 ..= frames {
		rl.DrawCircle(i32(pos.x), i32(pos.y), draw_radius, rl.Color{255, 255, 255, 255})

		acc, collision := physics_get_graviational_acceleration(
			pos,
			g.slingshot.radius,
			star.pos,
			star.size.mass,
			star.size.radius,
		)

		if collision do break

		vel += acc * dt
		pos += vel * dt

		draw_radius = math.lerp(draw_radius, end_radius, dt)
	}

}

sys_render_entities :: proc(g: ^Game) {
	for id in 0 ..< g.entities_count {
		e := g.entities[id]

		// TODO: For now, all entities are just drawn as circles
		if RENDER_SIG <= e.sig {
			rl.DrawCircle(i32(e.pos.x), i32(e.pos.y), e.size.radius, e.renderable.color)
		}
	}
}

sys_render_score :: proc(g: ^Game) {
	base_x: i32 = 20
	score_y: i32 = 20

	str := fmt.tprintf("energy = %.1f", g.energy)
	rl.DrawText(strings.clone_to_cstring(str), base_x, score_y, 20, rl.WHITE)
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
