package main

import rl "vendor:raylib"

// TODO: This just draws a bunch of tiled images.
// Needs to be overhauled fully
assets_load_bg :: proc(g: ^Game) {
	bg := rl.LoadTexture("./assets/textures/bg.png")
	nebula := rl.LoadTexture("./assets/textures/nebula.png")
	bg_texture := rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT)

	rl.BeginTextureMode(bg_texture)
	rl.ClearBackground(rl.BLACK)

	tile_size: f32 = 512
	half_tile: f32 = tile_size / 2

	for y: f32 = 0; y < 1080; y += 512 {
		for x: f32 = 0; x < 1920; x += 512 {
			rotation := f32(rl.GetRandomValue(0, 3)) * 90.0

			source_rect := rl.Rectangle{0, 0, tile_size, tile_size}
			dest_rect := rl.Rectangle{x + half_tile, y + half_tile, tile_size, tile_size}
			origin := rl.Vector2{half_tile, half_tile}

			rl.DrawTexturePro(
				nebula,
				source_rect,
				dest_rect,
				origin,
				0.0,
				rl.Color{255, 255, 255, 60},
			)

			rl.DrawTexturePro(
				bg,
				source_rect,
				dest_rect,
				origin,
				rotation,
				rl.Color{255, 255, 255, 60},
			)
		}
	}
	rl.EndTextureMode()

	g.textures.bg = bg_texture
}

assets_free_bg :: proc(g: ^Game) {
	rl.UnloadRenderTexture(g.textures.bg)
	rl.UnloadTexture(g.textures.bg.texture)
}

assets_load_shaders :: proc(g: ^Game) {
	// TODO: Add shaders
}

assets_free_shaders :: proc(g: ^Game) {
}

assets_load_textures :: proc(g: ^Game) {
	blank_image := rl.GenImageColor(1, 1, rl.WHITE)
	defer rl.UnloadImage(blank_image)
	g.textures.blank = rl.LoadTextureFromImage(blank_image)

	g.textures.star = rl.LoadTexture("./assets/textures/star.png")
	g.textures.star_rect = rl.Rectangle{0, 0, 192, 192} // TODO: Move to a more robust system
}

assets_free_textures :: proc(g: ^Game) {
	rl.UnloadTexture(g.textures.blank)
	rl.UnloadTexture(g.textures.star)
}
