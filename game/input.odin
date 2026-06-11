package game

import rl "vendor:raylib"

input_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	return rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera.rl_cam)
}

// TODO: Add a keyboard control system
input_process_keyboard :: proc(g: ^Game) {
	if rl_is_key_pressed(g, .ESCAPE) {
		if g.status == .Paused do g.status = .Playing
		else if g.status == .Playing do g.status = .Paused
	}
}

input_process :: proc(g: ^Game) {
	g.mouse_pos = input_mouse_pos(g)

	input_process_keyboard(g)
}

