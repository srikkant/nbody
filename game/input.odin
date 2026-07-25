package game

import "core:math"
import rl "vendor:raylib"

DEFAULT_GAME_INPUTS: [Input_Action]Input_Matcher = {
	.None              = {},
	.Game_Pause        = Input_Matcher_Keyboard{{.Pressed, .Playing}, .ESCAPE},
	.Game_Resume       = Input_Matcher_Keyboard{{.Pressed, .Paused}, .ESCAPE},
	.View_ToggleOrbit  = Input_Matcher_Keyboard{{.Pressed, .Playing}, .T},
	.Game_Reset        = Input_Matcher_Keyboard{{.Pressed, .Playing}, .R},
	.Upgrades_Recenter = Input_Matcher_Keyboard{{.Pressed, .Paused}, .HOME},
}

input_init :: proc(g: ^Game) {
	g.input.controls = DEFAULT_GAME_INPUTS
	g.slingshot.preview = 1
	g.slingshot.status = .Inactive
	g.slingshot.snap.active = false
	g.slingshot.output = Slingshot_Output_Celestial {
		celestial = {type = .Asteroid},
	}
}

input_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	return rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera.rl_cam)
}

input_action_match_mouse :: proc(
	g: ^Game,
	action: Input_Action,
	matcher: ^Input_Matcher_Mouse,
) -> bool {
	if matcher.status != g.status do return false
	switch matcher.interaction {
	case .Down:
		return rl_is_mouse_button_down(g, matcher.key)
	case .Released:
		return rl_is_mouse_button_released(g, matcher.key)
	case .Pressed:
		return rl_is_mouse_button_pressed(g, matcher.key)
	}
	return false
}

input_action_match_keyboard :: proc(
	g: ^Game,
	action: Input_Action,
	matcher: ^Input_Matcher_Keyboard,
) -> bool {
	if matcher.status != g.status do return false
	switch matcher.interaction {
	case .Down:
		return rl_is_key_down(g, matcher.key)
	case .Released:
		return rl_is_key_released(g, matcher.key)
	case .Pressed:
		return rl_is_key_pressed(g, matcher.key)
	}

	return false
}

input_match_action :: proc(g: ^Game) {
	if g.input.ignore do return

	for action in Input_Action {
		matched: bool

		switch &matcher in g.input.controls[action] {
		case Input_Matcher_Mouse:
			matched = input_action_match_mouse(g, action, &matcher)
		case Input_Matcher_Keyboard:
			matched = input_action_match_keyboard(g, action, &matcher)
		}

		if matched {
			g.input.action = action
			break
		}
	}
}

input_handle_action :: proc(g: ^Game) {
	switch g.input.action {
	case .None:
	case .Game_Pause:
		if g.help.launch_done {
			g.status = .Paused
		}
	case .Game_Resume:
		g.status = .Playing
	case .View_ToggleOrbit:
		g.render.show_orbits = !g.render.show_orbits
	case .Game_Reset:
		game_reset(g)
	case .Upgrades_Recenter:
		if g.status == .Paused {
			g.upgrade_menu.framed = false
		}
	}

	g.input.action = .None
}

input_slingshot_compute_preview :: proc(g: ^Game) {
	g.slingshot.preview_count = 0

	star := &g.entities[Entity_Id(0)]

	if g.slingshot.preview == 0 || !g.slingshot.can_launch do return

	pos := g.slingshot.start_pos
	vel := physics_get_slingshot_release_velocity(g)

	g.slingshot.preview_points[0] = pos
	g.slingshot.preview_times[0] = 0.0
	g.slingshot.preview_count = 1

	base_dt: f32 = (1.0 / 30.0)
	accumulated_t: f32 = 0.0

	for idx in 1 ..< 600 {
		if accumulated_t >= g.effective_params.slingshot.preview_duration do break

		dist := rl.Vector2Distance(pos, star.pos.current)
		scale := clamp(dist / f32(380.0), f32(0.12), f32(3.5))
		step_dt := base_dt * scale * f32(2.8)

		entity := physics_check_collision(g, pos, g.slingshot.obj_radius, PHYSICS_SIG)
		if entity != nil {
			break
		}

		physics_rk4_step(g, &pos, &vel, step_dt, g.slingshot.obj_radius)
		accumulated_t += step_dt

		g.slingshot.preview_points[idx] = pos
		g.slingshot.preview_times[idx] = accumulated_t
		g.slingshot.preview_count = idx + 1
	}
}

input_slingshot_activate :: proc(g: ^Game) {
	g.slingshot.status = .Active
	g.slingshot.start_pos = g.input.mouse_pos
	g.slingshot.end_pos = g.input.mouse_pos
	input_slingshot_update(g)
}

input_slingshot_prepare_launch :: proc(
	g: ^Game,
	vel: rl.Vector2,
) -> (
	cost: f64,
	event: GameEvent_ObjectSpawn,
) {
	event.pos = g.slingshot.start_pos

	switch out in g.slingshot.output {
	case Slingshot_Output_Emitter:
		color := get_celestial_color(g, out.emitter.emit_celestial.type)
		event.radius = g.effective_params.celestials[out.emitter.emit_celestial.type].radius
		event.emitter = out.emitter
		event.emitter.emit_vel = vel
		event.emitter.emit_density =
			g.effective_params.celestials[out.emitter.emit_celestial.type].density
		event.emitter.emit_radius =
			g.effective_params.celestials[out.emitter.emit_celestial.type].radius
		event.emitter.emit_color = color
		cost = f64(
			event.emitter.emit_density *
			event.emitter.emit_radius *
			event.emitter.emit_radius *
			math_vec2_length_sq(vel),
		)
		g.slingshot.obj_radius = event.radius
		g.slingshot.obj_color = color
	case Slingshot_Output_Celestial:
		color := get_celestial_color(g, out.celestial.type)
		event.celestial = out.celestial
		event.density = g.effective_params.celestials[out.celestial.type].density
		event.radius = g.effective_params.celestials[out.celestial.type].radius
		event.velocity = vel
		event.show_orbit = true
		event.renderable = Component_Renderable{color}
		cost = f64(
			g.effective_params.celestials[out.celestial.type].launch_cost +
			(event.density * event.radius * event.radius * math_vec2_length_sq(vel)),
		)
		g.slingshot.obj_radius = event.radius
		g.slingshot.obj_color = color
	case Slingshot_Output_Hardware:
		cost = 0.0
	}

	return
}

input_slingshot_update :: proc(g: ^Game) {
	if g.slingshot.status != .Active do return

	g.slingshot.end_pos = g.input.mouse_pos
	vel := physics_get_slingshot_release_velocity(g)
	cost, _ := input_slingshot_prepare_launch(g, vel)

	g.slingshot.can_launch = g.score.energy >= cost

	if g.input.mouse_pos != g.input.prev_mouse_pos || g.slingshot.preview_count == 0 {
		input_slingshot_compute_preview(g)
	}
}

input_slingshot_release :: proc(g: ^Game) {
	if g.slingshot.status != .Active do return

	g.slingshot.status = .Inactive
	g.slingshot.end_pos = g.input.mouse_pos
	vel := physics_get_slingshot_release_velocity(g)
	cost, event := input_slingshot_prepare_launch(g, vel)

	g.slingshot.can_launch = g.score.energy >= cost

	if g.slingshot.can_launch {
		g.help.launch_done = true

		if economy_try_spend(g, cost) {
			push_event(g, event)
		}

		payload_mass := event.density * (event.radius * event.radius)
		g.camera.shake_intensity = clamp(math.sqrt(payload_mass) * 0.45, 0.0, 25.0)

		push_event(
			g,
			GameEvent_Shockwave {
				pos = g.slingshot.start_pos,
				energy = f64(payload_mass * 2.0),
				color = g.slingshot.obj_color,
			},
		)
	}

	g.slingshot.preview_count = 0
}

input_slingshot_cancel :: proc(g: ^Game) {
	g.slingshot.status = .Inactive
	g.slingshot.preview_count = 0
}

input_handle_mouse :: proc(g: ^Game) {
	if g.input.ignore do return

	switch g.status {
	case .Playing:
		if rl_is_mouse_button_pressed(g, .LEFT) {
			if ui_control_menu_handle_click(g) do return
			input_slingshot_activate(g)
		} else if rl_is_mouse_button_released(g, .LEFT) {
			if g.slingshot.status == .Active {
				input_slingshot_release(g)
			}
		} else if rl_is_mouse_button_down(g, .LEFT) {
			if g.slingshot.status == .Active {
				input_slingshot_update(g)
			}
		} else if g.slingshot.status == .Active {
			input_slingshot_update(g)
		}

		if rl_is_mouse_button_pressed(g, .RIGHT) {
			if g.slingshot.status == .Active {
				input_slingshot_cancel(g)
			} else if g.help.launch_done &&
			   rl.CheckCollisionPointRec(g.input.mouse_pos_screen, g.control_menu.rect) {
				// Clicked inside control menu; consume right click without demolishing.
				// This is a noop.
			} else {
				push_event(g, GameEvent_Object_Demolish{})
			}
		}
	case .Paused:
		ui_upgrade_menu_handle_mouse(g)
	case .Exit:
	}
}

input_process :: proc(g: ^Game) {
	if rl.WindowShouldClose() {
		g.status = .Exit
		return
	}

	g.input.action = .None
	g.input.mouse_pos_screen = rl.GetMousePosition()
	g.input.prev_mouse_pos = g.input.mouse_pos
	g.input.mouse_pos = input_mouse_pos(g)
	g.input.mouse_scroll_move = rl.GetMouseWheelMoveV()

	input_match_action(g)
	input_handle_action(g)
	input_handle_mouse(g)

	if g.status == .Playing && !g.input.ignore {
		if rl_is_key_pressed(g, .G) {
			modifier_add(g, .Gravity_Boost)
		}
		if rl_is_key_pressed(g, .H) {
			modifier_add(g, .Energy_Magnet)
		}
	}

	g.input.ignore = false
}
