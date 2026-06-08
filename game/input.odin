package game

import rl "vendor:raylib"

input_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	return rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera.rl_cam)
}

input_process :: proc(g: ^Game) {
}

