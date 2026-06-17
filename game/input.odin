package game

import rl "vendor:raylib"

DEFAULT_GAME_INPUTS: [Game_InputAction]Game_InputMatcher = {
	.None               = {},
	.Game_Pause         = Game_InputMatcherKeyboard{{.Pressed, .Playing}, .ESCAPE},
	.Game_Resume        = Game_InputMatcherKeyboard{{.Pressed, .Paused}, .ESCAPE},
	.Slingshot_Activate = Game_InputMatcherMouse{{.Pressed, .Playing}, .LEFT},
	.Slingshot_Move     = Game_InputMatcherMouse{{.Down, .Playing}, .LEFT},
	.Slingshot_Release  = Game_InputMatcherMouse{{.Released, .Playing}, .LEFT},
	.Slingshot_Cancel   = Game_InputMatcherKeyboard{{.Pressed, .Playing}, .C},
	.View_ToggleOrbit   = Game_InputMatcherKeyboard{{.Pressed, .Playing}, .T},
}

input_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	return rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera.rl_cam)
}

input_action_match_mouse :: proc(
	g: ^Game,
	action: Game_InputAction,
	matcher: ^Game_InputMatcherMouse,
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
	action: Game_InputAction,
	matcher: ^Game_InputMatcherKeyboard,
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

	for action in Game_InputAction {
		matched: bool

		switch &matcher in DEFAULT_GAME_INPUTS[action] {
		case Game_InputMatcherMouse:
			matched = input_action_match_mouse(g, action, &matcher)
		case Game_InputMatcherKeyboard:
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
		g.status = .Paused
	case .Game_Resume:
		g.status = .Playing
	case .Slingshot_Activate:
		g.slingshot.status = .Active
		g.slingshot.start_pos = g.input.mouse_pos
	case .Slingshot_Move:
		g.slingshot.end_pos = g.input.mouse_pos
	case .Slingshot_Release:
		g.slingshot.status = .Released
		g.slingshot.end_pos = g.input.mouse_pos
	case .Slingshot_Cancel:
		g.slingshot.status = .Inactive
	case .View_ToggleOrbit:
		g.render.show_orbits = !g.render.show_orbits
	}

	g.input.action = .None
}

input_process :: proc(g: ^Game) {
	g.input.action = .None
	g.input.mouse_pos = input_mouse_pos(g)

	input_match_action(g)
	input_handle_action(g)

	g.input.ignore = false
}

