package game

import "core:c"
import rl "vendor:raylib"

rl_text_measure :: proc(g: ^Game, type: Game_FontType, text: cstring) -> rl.Vector2 {
	return rl.MeasureTextEx(
		assets_get_font(g, type),
		text,
		assets_get_font_size(g, type),
		assets_get_font_spacing(g, type),
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
		assets_get_font(g, type),
		text,
		pos,
		origin,
		rotation,
		assets_get_font_size(g, type),
		assets_get_font_spacing(g, type),
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
		assets_get_texture(g, type),
		assets_get_texture_rect(g, type),
		dest,
		origin,
		rotation,
		tint,
	)
}

rl_begin_shader :: proc(g: ^Game, type: Game_ShaderType) {
	rl.BeginShaderMode(assets_get_shader(g, type))
}

rl_end_shader :: proc(g: ^Game) {
	rl.EndShaderMode()
}

rl_is_key_pressed :: proc(g: ^Game, key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressed(key)
}

rl_is_key_down :: proc(g: ^Game, key: rl.KeyboardKey) -> bool {
	return rl.IsKeyDown(key)
}

rl_is_key_released :: proc(g: ^Game, key: rl.KeyboardKey) -> bool {
	return rl.IsKeyReleased(key)
}

rl_is_mouse_button_pressed :: proc(g: ^Game, button: rl.MouseButton) -> bool {
	return rl.IsMouseButtonPressed(button)
}

rl_is_mouse_button_down :: proc(g: ^Game, button: rl.MouseButton) -> bool {
	return rl.IsMouseButtonDown(button)
}

rl_is_mouse_button_released :: proc(g: ^Game, button: rl.MouseButton) -> bool {
	return rl.IsMouseButtonReleased(button)
}

color_to_int :: proc(col: rl.Color) -> c.int {
	return c.int(col.r) << 24 | c.int(col.g) << 16 | c.int(col.b) << 8 | c.int(col.a)
}

