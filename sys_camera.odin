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

	if g.slingshot.active do return // Lock camera zoom while slingshot is active to prevent input breaking

	max_x: f32 = 0
	max_y: f32 = 0

	for id in 0 ..< g.entities_count {
		e := &g.entities[id]
		if !(CAMERA_SIG <= e.sig) do continue

		if ORBIT_SIG <= e.sig && e.orbit.max_distance_sq > 0 {
			r := math.sqrt(e.orbit.max_distance_sq)
			max_x = math.max(max_x, r)
			max_y = math.max(max_y, r)
		} else {
			max_x = math.max(max_x, math.abs(e.pos.current.x))
			max_y = math.max(max_y, math.abs(e.pos.current.y))
		}
	}

	padding := g.theme.camera_padding
	total_w := max_x * 2 + padding
	total_h := max_y * 2 + padding

	zoom_x := ww / total_w
	zoom_y := wh / total_h
	target_zoom := min(zoom_x, zoom_y)
	target_zoom = clamp(target_zoom, g.params.camera.zoom_min, g.params.camera.zoom_max)

	dt := frame_time(g)
	decay := g.params.camera.zoom_in_interpolation_decay // zoom in
	if target_zoom < g.camera.zoom do decay = g.params.camera.zoom_out_interpolation_decay // zoom out

	t := 1.0 - math.exp(-decay * dt)
	g.camera.zoom = math.lerp(g.camera.zoom, target_zoom, t)
}
