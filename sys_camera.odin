package main

import "core:math"
import rl "vendor:raylib"

CAMERA_SIG: Signature : {.Position}

sys_camera_init :: proc(g: ^Game) {
	g.camera.zoom = 1
	g.camera.offset = rl.Vector2{f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight()) / 2}
	g.camera.target = rl.Vector2(0)
}

sys_camera :: proc(g: ^Game) {
	ww := f32(rl.GetScreenWidth())
	wh := f32(rl.GetScreenHeight())

	g.camera.offset = rl.Vector2{ww / 2, wh / 2}

	max_x: f32 = 0
	max_y: f32 = 0

	for id in 0 ..< g.entities_count {
		e := &g.entities[id]
		if !(CAMERA_SIG <= e.sig) do continue

		max_x = math.max(max_x, math.abs(e.pos.current.x))
		max_y = math.max(max_y, math.abs(e.pos.current.y))
	}

	padding :: 200.0
	total_w := max_x * 2 + padding
	total_h := max_y * 2 + padding

	zoom_x := ww / total_w
	zoom_y := wh / total_h
	target_zoom := min(zoom_x, zoom_y)
	target_zoom = clamp(target_zoom, 0.01, 2)

	g.camera.zoom = math.lerp(g.camera.zoom, target_zoom, f32(0.8))
}
