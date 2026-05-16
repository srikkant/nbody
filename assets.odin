package main

import rl "vendor:raylib"

assets_map_load :: proc(g: ^Game) {
	g.assets.fonts[.Heading] = rl.LoadFontEx("./assets/fonts/heading.ttf", 18, nil, 0)
	g.assets.fonts[.Body] = rl.LoadFontEx("./assets/fonts/body.ttf", 14, nil, 0)

	g.assets.textures[.Bg] = rl.LoadTexture("./assets/textures/bg.png")
	g.assets.textures[.Atlas] = rl.LoadTexture("./assets/textures/atlas.png")
}

assets_map_free :: proc(g: ^Game) {
	rl.UnloadFont(g.assets.fonts[.Heading])
	rl.UnloadFont(g.assets.fonts[.Body])
	rl.UnloadTexture(g.assets.textures[.Bg])
	rl.UnloadTexture(g.assets.textures[.Atlas])
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
	g.textures[.Objects_Star] = {
		texture = .Atlas,
		rect    = rl.Rectangle{0, 0, 96, 96},
	}
	g.textures[.Markers_OutOfBounds] = {
		texture = .Atlas,
		rect    = rl.Rectangle{96, 0, 96, 96},
	}
	g.textures[.Objects_Emitter] = {
		texture = .Atlas,
		rect    = rl.Rectangle{192, 0, 96, 96},
	}
	g.textures[.Collectibles_Energy] = {
		texture = .Atlas,
		rect    = rl.Rectangle{192, 0, 96, 96},
	}
}
