package game

import "core:math"
import rl "vendor:raylib"

physics_get_total_acceleration_at_pos :: proc(
	g: ^Game,
	target_pos: rl.Vector2,
	target_radius: f32,
) -> rl.Vector2 {
	total_accel := rl.Vector2(0)
	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if !(PHYSICS_SIG <= e.sig) do continue
		if e.mass <= 0.0 do continue

		acc, _ := physics_get_gravitational_acceleration(
			g,
			target_pos,
			target_radius,
			e.pos.current,
			e.mass,
			e.radius,
		)
		total_accel += acc
	}
	return total_accel
}

physics_check_preview_collision :: proc(g: ^Game, pos: rl.Vector2, radius: f32) -> (bool, Entity) {
	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if !(PHYSICS_SIG <= e.sig) do continue
		if e.mass <= 0.0 do continue

		diff := e.pos.current - pos
		dist_sq := diff.x * diff.x + diff.y * diff.y
		collision_radius := (radius + e.radius)
		if dist_sq < collision_radius * collision_radius {
			return true, Entity(i)
		}
	}
	return false, 0
}

rk4_step :: proc(g: ^Game, pos: ^rl.Vector2, vel: ^rl.Vector2, dt: f32, radius: f32) {
	// k1
	k1_pos := vel^
	k1_vel := physics_get_total_acceleration_at_pos(g, pos^, radius)

	// k2
	p2 := pos^ + k1_pos * (dt * 0.5)
	v2 := vel^ + k1_vel * (dt * 0.5)
	k2_pos := v2
	k2_vel := physics_get_total_acceleration_at_pos(g, p2, radius)

	// k3
	p3 := pos^ + k2_pos * (dt * 0.5)
	v3 := vel^ + k2_vel * (dt * 0.5)
	k3_pos := v3
	k3_vel := physics_get_total_acceleration_at_pos(g, p3, radius)

	// k4
	p4 := pos^ + k3_pos * dt
	v4 := vel^ + k3_vel * dt
	k4_pos := v4
	k4_vel := physics_get_total_acceleration_at_pos(g, p4, radius)

	// Update state
	pos^ += (k1_pos + k2_pos * 2.0 + k3_pos * 2.0 + k4_pos) * (dt / 6.0)
	vel^ += (k1_vel + k2_vel * 2.0 + k3_vel * 2.0 + k4_vel) * (dt / 6.0)
}

sys_render_slingshot :: proc(g: ^Game) {
	dt := g.dt

	// 1. Update and draw slingshot release snap animation
	if g.slingshot_snap.active {
		g.slingshot_snap.timer -= dt * 7.5 // snap over ~8 frames
		if g.slingshot_snap.timer <= 0.0 {
			g.slingshot_snap.active = false
		} else {
			t := 1.0 - g.slingshot_snap.timer
			drag := g.slingshot_snap.end_pos - g.slingshot_snap.start_pos

			// Elastic recoil: shoot backward through the anchor and collapse
			snap_start := g.slingshot_snap.start_pos - drag * t * f32(0.45)
			snap_end := g.slingshot_snap.start_pos + drag * (f32(1.0) - t * f32(1.3))

			snap_color := g.slingshot_snap.color
			snap_color.a = u8(g.slingshot_snap.timer * 220.0)

			rl.DrawLineEx(snap_start, snap_end, 1.5, snap_color)

			// Fade-out core pulse
			pulse_color := g.slingshot_snap.color
			pulse_color.a = u8(g.slingshot_snap.timer * 255.0)
			rl.DrawCircleV(g.slingshot_snap.start_pos, 5.0 * g.slingshot_snap.timer, pulse_color)
		}
	}

	// 2. Update and draw chromatic additive ring flashes
	for i in 0 ..< len(g.ring_flashes) {
		flash := &g.ring_flashes[i]
		if !flash.active do continue

		flash.life -= dt * 6.5 // rapid fade over ~10 frames
		if flash.life <= 0.0 {
			flash.active = false
		} else {
			t := f32(1.0) - flash.life
			// Rapid expansion with easing out
			ease_t := f32(1.0) - (f32(1.0) - t) * (f32(1.0) - t)
			curr_radius := math.lerp(flash.radius, flash.max_radius, ease_t)

			rl.BeginBlendMode(.ADDITIVE)

			// Chromatic Aberration: Red, Green, and Blue rings slightly offset in size
			r_col := rl.Color{flash.color.r, 0, 0, u8(flash.life * 180.0)}
			g_col := rl.Color{0, flash.color.g, 0, u8(flash.life * 180.0)}
			b_col := rl.Color{0, 0, flash.color.b, u8(flash.life * 180.0)}

			rl.DrawCircleLinesV(flash.pos, curr_radius - 2.0, r_col)
			rl.DrawCircleLinesV(flash.pos, curr_radius, g_col)
			rl.DrawCircleLinesV(flash.pos, curr_radius + 2.0, b_col)

			rl.EndBlendMode()
		}
	}

	// 3. Draw active slingshot drag indicators
	if !g.slingshot.active do return

	end := g.mouse_pos
	drag := end - g.slingshot.start_pos
	pull_dist := vec2_length(drag)

	launch_type: CelestialType
	switch out in g.slingshot.output {
	case Game_SlingshotOutput_Emitter:
		launch_type = out.emitter.emit_celestial.type
	case Game_SlingshotOutput_Celestial:
		launch_type = out.celestial.type
	}

	payload_color := get_celestial_color(g, launch_type)
	ss_obj_radius := g.params.celestials[launch_type].radius

	// Anchor Ring: concentric glowing neon rings with alpha reactive to tension
	tension := clamp(pull_dist / f32(320.0), f32(0.0), f32(1.0))
	alpha := u8(math.lerp(f32(60.0), f32(255.0), tension))

	// Outer atmospheric glow
	glow_col := payload_color
	glow_col.a = alpha / 4
	rl.DrawCircleLinesV(g.slingshot.start_pos, ss_obj_radius + 4.0, glow_col)

	// Mid glow ring
	mid_col := payload_color
	mid_col.a = alpha / 2
	rl.DrawCircleLinesV(g.slingshot.start_pos, ss_obj_radius + 2.0, mid_col)

	// Core ring
	core_col := payload_color
	core_col.a = alpha
	rl.DrawCircleLinesV(g.slingshot.start_pos, ss_obj_radius, core_col)

	// Vector String: elastic curved Bezier bending to central star
	P0 := g.slingshot.start_pos
	P2 := end
	mid := (P0 + P2) / 2.0

	// Curve towards central star
	star := &g.entities[Entity(0)]
	to_star := star.pos.current - mid
	to_star_norm := rl.Vector2Normalize(to_star)
	grav_pull := to_star_norm * clamp(pull_dist * f32(0.12), f32(0.0), f32(50.0))

	// Side bow sag perpendicular to pull
	drag_dir := rl.Vector2Normalize(drag)
	perp := rl.Vector2{-drag_dir.y, drag_dir.x}
	bow_sag := perp * (pull_dist * f32(0.08))

	P1 := mid + grav_pull + bow_sag

	// Draw curved targeting string
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

	// 4. Trajectory Preview: N-body RK4 with Adaptive Fat Steps
	if g.slingshot.preview == 0 || !g.slingshot.can_launch do return

	pos := g.slingshot.start_pos
	vel := physics_get_slingshot_release_velocity(g, end)

	frames := clamp(g.params.physics.slingshot_preview_length * i32(g.slingshot.preview), 1, 599)
	g.slingshot.preview_points[0] = pos
	g.slingshot.preview_times[0] = 0.0
	actual_frames: i32 = 0

	base_dt := g.dt * g.params.physics.simulation_rate_multiplier
	accumulated_t: f32 = 0.0

	for idx in 1 ..< frames {
		// Adaptive step scaling: step_dt gets smaller near massive bodies
		dist := rl.Vector2Distance(pos, star.pos.current)
		scale := clamp(dist / f32(380.0), f32(0.12), f32(3.5))
		step_dt := base_dt * scale * f32(2.8) // Fat step scaling

		// Check collision with any celestial
		collision, _ := physics_check_preview_collision(g, pos, ss_obj_radius)
		if collision {
			actual_frames = idx
			break
		}

		// High-precision RK4 step
		rk4_step(g, &pos, &vel, step_dt, ss_obj_radius)
		accumulated_t += step_dt

		g.slingshot.preview_points[idx] = pos
		g.slingshot.preview_times[idx] = accumulated_t
		actual_frames = idx
	}

	// Draw beautiful glowing fading preview ribbon (always fully visible!)
	for i in 0 ..< actual_frames {
		pt := g.slingshot.preview_points[i]
		t_val := f32(i) / f32(actual_frames)
		dot_alpha := u8(math.lerp(f32(230.0), f32(0.0), t_val))

		dot_col := payload_color
		dot_col.a = dot_alpha

		preview_glow_col := payload_color
		preview_glow_col.a = dot_alpha / 4

		rl.DrawCircleV(pt, 3.5, preview_glow_col)
		rl.DrawCircleV(pt, 1.8, dot_col)
	}

	// 5. Profound Shimmer Pulse traveling at exact physics speed
	if actual_frames > 1 {
		total_sim_time := g.slingshot.preview_times[actual_frames - 1]
		if total_sim_time > 0.0 {
			// Enforce a minimum real-world loop duration of 2.5 seconds to prevent rapid looping on short paths
			min_cycle_time_sim := f32(2.5) * g.params.physics.simulation_rate_multiplier
			total_cycle_time := math.max(total_sim_time, min_cycle_time_sim)

			// Advance shimmer time by simulated delta time
			g.slingshot_shimmer_time = math.mod(
				g.slingshot_shimmer_time + dt * g.params.physics.simulation_rate_multiplier,
				total_cycle_time,
			)

			// Only render the shimmer pulse if it is within the active simulated path time
			if g.slingshot_shimmer_time < total_sim_time {
				// Find closest preview point index in simulated time
				shimmer_idx := 0
				best_diff := math.abs(g.slingshot.preview_times[0] - g.slingshot_shimmer_time)
				for i in 1 ..< actual_frames {
					diff := math.abs(g.slingshot.preview_times[i] - g.slingshot_shimmer_time)
					if diff < best_diff {
						best_diff = diff
						shimmer_idx = int(i)
					}
				}

				// Render glowing energy comet trail in additive mode for intense brightness and 5% larger size
				rl.BeginBlendMode(.ADDITIVE)
				TRAIL_LEN :: 10
				for k in 0 ..< TRAIL_LEN {
					idx := shimmer_idx - k
					// Loop or clamp: clamping provides a cleaner start-to-end flow
					if idx >= 0 && idx < int(actual_frames) {
						pt := g.slingshot.preview_points[idx]
						trail_t := f32(k) / f32(TRAIL_LEN)

						// Intense white-hot core and vibrant payload-themed outer glow
						shimmer_alpha := u8(f32(255.0) * (f32(1.0) - trail_t))

						shimmer_core_col := rl.Color{255, 255, 255, shimmer_alpha}
						shimmer_glow_col := payload_color
						shimmer_glow_col.a = shimmer_alpha

						// Exactly 5% larger than usual (usual glow is 3.5, usual core is 1.8)
						glow_radius := f32(3.675) * (f32(1.0) - trail_t * f32(0.35))
						core_radius := f32(1.89) * (f32(1.0) - trail_t * f32(0.55))

						rl.DrawCircleV(pt, glow_radius, shimmer_glow_col)
						rl.DrawCircleV(pt, core_radius, shimmer_core_col)
					}
				}
				rl.EndBlendMode()
			}
		}
	}
}
