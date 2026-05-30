package game

import "core:c"
import rl "vendor:raylib"

rl_text_measure :: proc(g: ^Game, type: Game_FontType, text: cstring) -> rl.Vector2 {
	return rl.MeasureTextEx(
		g.assets.fonts[g.fonts[type].font],
		text,
		g.fonts[type].size,
		g.fonts[type].spacing,
	)
}

rl_text_draw :: proc(
	g: ^Game,
	type: Game_FontType,
	text: cstring,
	pos: rl.Vector2,
	color: rl.Color = rl.WHITE,
	origin: rl.Vector2 = rl.Vector2(0),
	rotation: f32 = 0,
) {
	rl.DrawTextPro(
		g.assets.fonts[g.fonts[type].font],
		text,
		pos,
		origin,
		rotation,
		g.fonts[type].size,
		g.fonts[type].spacing,
		color,
	)
}

rl_texture_draw :: proc(
	g: ^Game,
	type: Game_TextureType,
	dest: rl.Rectangle,
	origin: rl.Vector2 = rl.Vector2(0),
	rotation: f32 = 0,
	tint: rl.Color = rl.WHITE,
) {
	rl.DrawTexturePro(
		g.assets.textures[g.textures[type].texture],
		g.textures[type].rect,
		dest,
		origin,
		rotation,
		tint,
	)
}

rl_begin_shader :: proc(g: ^Game, type: Game_ShaderType) {
	rl.BeginShaderMode(g.assets.shaders[g.shaders[type].shader])
}

rl_end_shader :: proc(g: ^Game) {
	rl.EndShaderMode()
}

rl_is_key_pressed :: proc(g: ^Game, key: rl.KeyboardKey) -> bool {
	if g.input_blocked do return false
	return rl.IsKeyPressed(key)
}

rl_is_key_down :: proc(g: ^Game, key: rl.KeyboardKey) -> bool {
	if g.input_blocked do return false
	return rl.IsKeyDown(key)
}

rl_is_key_released :: proc(g: ^Game, key: rl.KeyboardKey) -> bool {
	if g.input_blocked do return false
	return rl.IsKeyReleased(key)
}

rl_is_mouse_button_pressed :: proc(g: ^Game, button: rl.MouseButton) -> bool {
	if g.input_blocked do return false
	return rl.IsMouseButtonPressed(button)
}

rl_is_mouse_button_down :: proc(g: ^Game, button: rl.MouseButton) -> bool {
	if g.input_blocked do return false
	return rl.IsMouseButtonDown(button)
}

rl_is_mouse_button_released :: proc(g: ^Game, button: rl.MouseButton) -> bool {
	if g.input_blocked do return false
	return rl.IsMouseButtonReleased(button)
}

color_to_int :: proc(col: rl.Color) -> c.int {
	return c.int(col.r) << 24 | c.int(col.g) << 16 | c.int(col.b) << 8 | c.int(col.a)
}
