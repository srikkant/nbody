package game

import rl "vendor:raylib"

DEFAULT_GAME_INPUTS: [Input_Action]Input_Matcher = {
	.None               = {},
	.Game_Pause         = Input_Matcher_Keyboard{{.Pressed, .Playing}, .ESCAPE},
	.Game_Resume        = Input_Matcher_Keyboard{{.Pressed, .Paused}, .ESCAPE},
	.Slingshot_Activate = Input_Matcher_Mouse{{.Pressed, .Playing}, .LEFT},
	.Slingshot_Move     = Input_Matcher_Mouse{{.Down, .Playing}, .LEFT},
	.Slingshot_Release  = Input_Matcher_Mouse{{.Released, .Playing}, .LEFT},
	.Slingshot_Cancel   = Input_Matcher_Keyboard{{.Pressed, .Playing}, .C},
	.View_ToggleOrbit   = Input_Matcher_Keyboard{{.Pressed, .Playing}, .T},
	.Demolish_Object    = Input_Matcher_Mouse{{.Pressed, .Playing}, .RIGHT},
	.Game_Reset         = Input_Matcher_Keyboard{{.Pressed, .Playing}, .R},
}

input_init :: proc(g: ^Game) {
	g.input.controls = DEFAULT_GAME_INPUTS
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
	case .Slingshot_Activate:
		g.slingshot.status = .Active
		g.slingshot.start_pos = g.input.mouse_pos
		g.slingshot.end_pos = g.input.mouse_pos
	case .Slingshot_Move:
		g.slingshot.end_pos = g.input.mouse_pos
	case .Slingshot_Release:
		g.slingshot.status = .Released
		g.slingshot.end_pos = g.input.mouse_pos
	case .Slingshot_Cancel:
		g.slingshot.status = .Inactive
	case .View_ToggleOrbit:
		g.render.show_orbits = !g.render.show_orbits
	case .Demolish_Object:
		push_event(g, GameEvent_Object_Demolish{})
	case .Game_Reset:
		game_reset(g)
	}

	g.input.action = .None
}

input_process :: proc(g: ^Game) {
	if rl.WindowShouldClose() {
		g.status = .Exit
		return
	}

	g.input.action = .None
	g.input.mouse_pos_screen = rl.GetMousePosition()
	g.input.mouse_pos = input_mouse_pos(g)
	g.input.mouse_scroll_move = rl.GetMouseWheelMoveV()

	input_match_action(g)
	input_handle_action(g)

	g.input.ignore = false
}
