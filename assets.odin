package main

import rl "vendor:raylib"

assets_map_load :: proc(g: ^Game) {
	blank_image := rl.GenImageColor(1, 1, rl.WHITE)
	defer rl.UnloadImage(blank_image)

	g.assets.textures[.Blank] = rl.LoadTextureFromImage(blank_image)
	g.assets.textures[.Bg] = rl.LoadTexture("./assets/textures/bg.png")
	g.assets.textures[.Atlas] = rl.LoadTexture("./assets/textures/atlas.png")

	g.assets.shaders[.Objects_Base] = rl.LoadShader(nil, "./assets/shaders/objects_base.frag")

	g.assets.fonts[.Heading] = rl.LoadFontEx("./assets/fonts/heading.ttf", 18, nil, 0)
	g.assets.fonts[.Body] = rl.LoadFontEx("./assets/fonts/body.ttf", 14, nil, 0)
}

assets_map_free :: proc(g: ^Game) {
	rl.UnloadFont(g.assets.fonts[.Heading])
	rl.UnloadFont(g.assets.fonts[.Body])
	rl.UnloadTexture(g.assets.textures[.Bg])
	rl.UnloadTexture(g.assets.textures[.Atlas])
	rl.UnloadTexture(g.assets.textures[.Blank])
	rl.UnloadShader(g.assets.shaders[.Objects_Base])
}

assets_fonts_load :: proc(g: ^Game) {
	g.fonts[.Heading] = {
		font = .Heading,
		size = 18,
	}

	g.fonts[.Body] = {
		font = .Body,
		size = 14,
	}
}

assets_textures_load :: proc(g: ^Game) {
	g.textures[.Objects_Celestial] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
	g.textures[.Markers_OutOfBounds] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
	g.textures[.Objects_Emitter] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
	g.textures[.Collectibles_Energy] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
}

assets_shaders_load :: proc(g: ^Game) {
	g.shaders[.Objects_Layer] = {
		shader = .Objects_Base,
	}
}
