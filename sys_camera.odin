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

	dt := frame_time(g)
	if g.camera_shake_intensity > 0.05 {
		g.camera_shake_intensity *= math.exp(-12.0 * dt)
		angle := f32(rl.GetRandomValue(0, 360)) * (math.PI / 180.0)
		shake_offset := rl.Vector2{math.cos(angle), math.sin(angle)} * g.camera_shake_intensity
		g.camera.offset += shake_offset
	} else {
		g.camera_shake_intensity = 0.0
	}

	// If slingshot is active, add some vibration and exit.
	if g.slingshot.active {
		drag := g.mouse_pos - g.slingshot.start_pos
		pull_dist := rl.Vector2Length(drag)

		// Scale vibration with pull distance
		vibration := clamp(pull_dist * f32(0.012), f32(0.0), f32(3.5))
		if vibration > 0.05 {
			angle := f32(rl.GetRandomValue(0, 360)) * (math.PI / 180.0)
			vib_offset := rl.Vector2{math.cos(angle), math.sin(angle)} * vibration
			g.camera.offset += vib_offset
		}

		return
	}

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

	decay :=
		target_zoom > g.camera.zoom ? g.params.camera.zoom_in_interpolation_decay : g.params.camera.zoom_out_interpolation_decay

	t := f32(1.0) - math.exp_f32(-decay * dt)
	g.camera.zoom = math.lerp(g.camera.zoom, target_zoom, t)
}
