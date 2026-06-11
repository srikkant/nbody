package game

import "core:math"
import rl "vendor:raylib"

// TODO: This should be updated to only rely on the stars
physics_check_preview_collision :: proc(g: ^Game, pos: rl.Vector2, radius: f32) -> (bool, Entity) {
	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if !(PHYSICS_SIG <= e.sig) do continue

		diff := e.pos.current - pos
		dist_sq := diff.x * diff.x + diff.y * diff.y
		collision_radius := (radius + e.radius)
		if dist_sq < collision_radius * collision_radius {
			return true, Entity(i)
		}
	}
	return false, 0
}

sys_render_slingshot_trigger :: proc(g: ^Game) {
	star := &g.entities[Entity(0)]

	drag := g.mouse_pos - g.slingshot.start_pos
	pull_dist := vec2_length(drag)
	P0 := g.slingshot.start_pos
	P2 := g.mouse_pos
	mid := (P0 + P2) / 2.0

	// Curve towards central star
	to_star := star.pos.current - mid
	to_star_norm := rl.Vector2Normalize(to_star)
	grav_pull := to_star_norm * clamp(pull_dist * f32(0.12), f32(0.0), f32(50.0))

	// Side bow sag perpendicular to pull
	drag_dir := rl.Vector2Normalize(drag)
	perp := rl.Vector2{-drag_dir.y, drag_dir.x}
	bow_sag := perp * (pull_dist * f32(0.08))

	P1 := mid + grav_pull + bow_sag

	BEZIER_STEPS :: 20
	prev_point := P0
	for step in 1 ..= BEZIER_STEPS {
		t_val := f32(step) / f32(BEZIER_STEPS)
		one_minus_t := f32(1.0) - t_val
		curr_point :=
			one_minus_t * one_minus_t * P0 +
			f32(2.0) * one_minus_t * t_val * P1 +
			t_val * t_val * P2

		line_col :=
			g.slingshot.can_launch ? g.theme.ui_slingshot_launch_ok_color : g.theme.ui_slingshot_launch_err_color
		line_col.a = u8(math.lerp(f32(220.0), f32(90.0), t_val))

		rl.DrawLineEx(prev_point, curr_point, 1.2, line_col)
		prev_point = curr_point
	}
}

sys_render_slingshot_preview :: proc(g: ^Game) {
	star := &g.entities[Entity(0)]

	// No preview if the user cannot launch or has no preview level, to avoid confusion
	if g.slingshot.preview == 0 || !g.slingshot.can_launch do return

	pos := g.slingshot.start_pos
	vel := physics_get_slingshot_release_velocity(g, g.mouse_pos)

	frames := clamp(g.params.physics.slingshot_preview_length * i32(g.slingshot.preview), 1, 599)
	g.slingshot.preview_points[0] = pos
	g.slingshot.preview_times[0] = 0.0
	actual_frames: i32 = 0
	base_dt := g.dt * g.params.physics.simulation_rate_multiplier
	accumulated_t: f32 = 0.0

	// TODO: Update preview computation. This is vibe coded now
	for idx in 1 ..< frames {
		dist := rl.Vector2Distance(pos, star.pos.current)
		scale := clamp(dist / f32(380.0), f32(0.12), f32(3.5))
		step_dt := base_dt * scale * f32(2.8)

		// Check collision with any celestial
		collision, _ := physics_check_preview_collision(g, pos, g.slingshot.obj_radius)
		if collision {
			actual_frames = idx
			break
		}

		physics_rk4_step(g, &pos, &vel, step_dt, g.slingshot.obj_radius)
		accumulated_t += step_dt

		g.slingshot.preview_points[idx] = pos
		g.slingshot.preview_times[idx] = accumulated_t
		actual_frames = idx
	}

	// Draw base preview
	for i in 0 ..< actual_frames {
		pt := g.slingshot.preview_points[i]
		t_val := f32(i) / f32(actual_frames)
		dot_col := g.slingshot.obj_color
		dot_col.a = u8(math.lerp(f32(255.0), f32(0.0), t_val))

		rl.DrawCircleV(pt, g.slingshot.obj_radius, dot_col)
	}

	// Shimmer for the preview
	total_sim_time := g.slingshot.preview_times[actual_frames - 1]
	if total_sim_time > 0.0 {
		g.slingshot.shimmer_time = math.mod(
			g.slingshot.shimmer_time + g.dt * g.params.physics.simulation_rate_multiplier,
			total_sim_time,
		)

		if g.slingshot.shimmer_time < total_sim_time {
			shimmer_idx := 0
			best_diff := math.abs(g.slingshot.preview_times[0] - g.slingshot.shimmer_time)
			for i in 1 ..< actual_frames {
				diff := math.abs(g.slingshot.preview_times[i] - g.slingshot.shimmer_time)
				if diff < best_diff {
					best_diff = diff
					shimmer_idx = int(i)
				}
			}

			rl.BeginBlendMode(.ADDITIVE)

			TRAIL_LEN :: 10 // points to draw for the shimmer
			for k in 0 ..< TRAIL_LEN {
				idx := shimmer_idx - k
				if idx >= 0 && idx < int(actual_frames) {
					pt := g.slingshot.preview_points[idx]
					trail_t := f32(k) / f32(TRAIL_LEN)

					shimmer_glow_col := g.slingshot.obj_color
					shimmer_glow_col.a = u8(f32(255.0) * (f32(1.0) - trail_t))

					rl.DrawCircleV(pt, g.slingshot.obj_radius, shimmer_glow_col)
				}
			}

			rl.EndBlendMode()
		}
	}
}

sys_render_slingshot :: proc(g: ^Game) {
	if !g.slingshot.active do return

	sys_render_slingshot_trigger(g)
	sys_render_slingshot_preview(g)
}

