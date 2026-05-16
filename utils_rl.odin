package main

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
) {
	rl.DrawTexturePro(
		g.assets.textures[g.textures[type].texture],
		g.textures[type].rect,
		dest,
		origin,
		rotation,
		rl.WHITE,
	)
}
