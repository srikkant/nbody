package game

import "core:math"
import rl "vendor:raylib"

CAMERA_SIG: Signature : {.Position}

sys_camera_init :: proc(g: ^Game) {
	g.camera.rl_cam.zoom = 1
	g.camera.rl_cam.offset = rl.Vector2{g.screenw / 2, g.screenh / 2}
	g.camera.rl_cam.target = rl.Vector2(0)
}

sys_camera :: proc(g: ^Game) {
	g.camera.rl_cam.offset = rl.Vector2{g.screenw / 2, g.screenh / 2}

	dt := g.dt
	if g.camera.shake_intensity > 0.05 {
		g.camera.shake_intensity *= math.exp(-12.0 * dt)
		angle := f32(rl.GetRandomValue(0, 360)) * (math.PI / 180.0)
		shake_offset := rl.Vector2{math.cos(angle), math.sin(angle)} * g.camera.shake_intensity
		g.camera.rl_cam.offset += shake_offset
	} else {
		g.camera.shake_intensity = 0.0
	}

	// If slingshot is active, add some vibration and exit.
	if g.slingshot.status == .Active {
		drag := g.slingshot.end_pos - g.slingshot.start_pos
		pull_dist := vec2_length(drag)

		// Scale vibration with pull distance
		vibration := clamp(pull_dist * f32(0.012), f32(0.0), f32(3.5))
		if vibration > 0.05 {
			angle := f32(rl.GetRandomValue(0, 360)) * (math.PI / 180.0)
			vib_offset := rl.Vector2{math.cos(angle), math.sin(angle)} * vibration
			g.camera.rl_cam.offset += vib_offset
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

	zoom_x := g.screenw / total_w
	zoom_y := g.screenh / total_h
	target_zoom := min(zoom_x, zoom_y)
	target_zoom = clamp(target_zoom, g.params.camera.zoom_min, g.params.camera.zoom_max)

	decay :=
		target_zoom > g.camera.rl_cam.zoom ? g.params.camera.zoom_in_interpolation_decay : g.params.camera.zoom_out_interpolation_decay

	t := f32(1.0) - math.exp_f32(-decay * dt)
	g.camera.rl_cam.zoom = math.lerp(g.camera.rl_cam.zoom, target_zoom, t)
}

