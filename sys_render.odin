package main

import "core:math"
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

	rl.DrawFPS(10, 10)
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
