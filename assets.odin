package main

import "core:math"
import rl "vendor:raylib"

assets_map_load :: proc(g: ^Game) {
	blank_image := rl.GenImageColor(1, 1, rl.WHITE)
	defer rl.UnloadImage(blank_image)

	g.assets.textures[.Blank] = rl.LoadTextureFromImage(blank_image)
	g.assets.textures[.Bg] = rl.LoadTexture("./assets/textures/bg.png")
	g.assets.textures[.Atlas] = rl.LoadTexture("./assets/textures/atlas.png")

	g.assets.shaders[.Celestial_Debris] = rl.LoadShader(
		nil,
		"./assets/shaders/celestial_debris.frag",
	)
	g.assets.shaders[.Vignette] = rl.LoadShader(nil, "./assets/shaders/vignette.frag")
	g.assets.shaders[.Celestial_Terrestrial] = rl.LoadShader(
		nil,
		"./assets/shaders/celestial_terrestrial.frag",
	)
	g.assets.shaders[.Celestial_GasGiant] = rl.LoadShader(
		nil,
		"./assets/shaders/celestial_gasgiant.frag",
	)
	g.assets.shaders[.Celestial_Star] = rl.LoadShader(nil, "./assets/shaders/celestial_star.frag")
	g.assets.shaders[.BgGrid_Shimmer] = rl.LoadShader(nil, "./assets/shaders/bg_grid_shimmer.frag")
	g.assets.shaders[.Energy_Shader] = rl.LoadShader(nil, "./assets/shaders/energy_glow.frag")

	g.assets.fonts[.Heading] = rl.LoadFontEx("./assets/fonts/heading.ttf", 18, nil, 0)
	g.assets.fonts[.Body] = rl.LoadFontEx("./assets/fonts/body.ttf", 14, nil, 0)

	/*
	Procedural Starfield Textures
	*/

	{
		width, height := i32(32), i32(32)
		img := rl.GenImageColor(width, height, rl.BLANK)
		pixels := ([^]rl.Color)(img.data)[:width * height]

		center_x := f32(width) / 2.0 - 0.5
		center_y := f32(height) / 2.0 - 0.5
		max_radius := f32(width) / 2.0

		// Higher values make the glow tighter around the core; lower values make it softer and wider.
		glow_falloff_rate := f32(3.5)

		for y in 0 ..< height {
			for x in 0 ..< width {
				dx := f32(x) - center_x
				dy := f32(y) - center_y
				dist := math.sqrt(dx * dx + dy * dy)
				r := dist / max_radius

				if r < 1.0 {
					glow := math.exp(-glow_falloff_rate * r * r)
					val := u8(255.0 * glow)
					pixels[y * width + x] = rl.Color{255, 255, 255, val}
				}
			}
		}
		g.assets.textures[.BgStarGlow] = rl.LoadTextureFromImage(img)
		rl.UnloadImage(img)
	}

	{
		width, height := i32(64), i32(64)
		img := rl.GenImageColor(width, height, rl.BLANK)
		pixels := ([^]rl.Color)(img.data)[:width * height]

		center_x := f32(width) / 2.0 - 0.5
		center_y := f32(height) / 2.0 - 0.5
		max_radius := f32(width) / 2.0

		core_falloff_rate := f32(6.0) // (higher = tighter central point)
		spike_thickness_factor := f32(0.25) // (higher = thinner spikes)
		spike_decay_rate := f32(0.08) // (lower = longer spikes)
		spike_intensity_weight := f32(0.65)

		for y in 0 ..< height {
			for x in 0 ..< width {
				dx := f32(x) - center_x
				dy := f32(y) - center_y
				dist := math.sqrt(dx * dx + dy * dy)
				r := dist / max_radius

				if r < 1.0 {
					glow := math.exp(-core_falloff_rate * r * r)

					spike_x :=
						math.exp(-spike_thickness_factor * dx * dx) *
						math.exp(-spike_decay_rate * math.abs(dy))

					spike_y :=
						math.exp(-spike_thickness_factor * dy * dy) *
						math.exp(-spike_decay_rate * math.abs(dx))

					intensity := glow + spike_intensity_weight * (spike_x + spike_y)
					intensity = math.clamp(intensity, 0.0, 1.0)

					val := u8(255.0 * intensity)
					pixels[y * width + x] = rl.Color{255, 255, 255, val}
				}
			}
		}
		g.assets.textures[.BgStarFlare] = rl.LoadTextureFromImage(img)
		rl.UnloadImage(img)
	}
}

assets_map_free :: proc(g: ^Game) {
	rl.UnloadFont(g.assets.fonts[.Heading])
	rl.UnloadFont(g.assets.fonts[.Body])
	rl.UnloadTexture(g.assets.textures[.Bg])
	rl.UnloadTexture(g.assets.textures[.Atlas])
	rl.UnloadTexture(g.assets.textures[.Blank])
	rl.UnloadShader(g.assets.shaders[.Celestial_Debris])
	rl.UnloadShader(g.assets.shaders[.Vignette])
	rl.UnloadShader(g.assets.shaders[.Celestial_Terrestrial])
	rl.UnloadShader(g.assets.shaders[.Celestial_GasGiant])
	rl.UnloadShader(g.assets.shaders[.Celestial_Star])
	rl.UnloadShader(g.assets.shaders[.BgGrid_Shimmer])
	rl.UnloadShader(g.assets.shaders[.Energy_Shader])

	rl.UnloadTexture(g.assets.textures[.BgStarGlow])
	rl.UnloadTexture(g.assets.textures[.BgStarFlare])
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
	g.textures[.Blank] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
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
	g.textures[.UI_Energy] = {
		texture = .Atlas,
		rect    = rl.Rectangle{0, 0, 96, 96},
	}
	g.textures[.UI_ObjectCount] = {
		texture = .Atlas,
		rect    = rl.Rectangle{96, 0, 96, 96},
	}
	g.textures[.UI_EnergyAverage] = {
		texture = .Atlas,
		rect    = rl.Rectangle{192, 0, 96, 96},
	}
	g.textures[.BgStarGlow] = {
		texture = .BgStarGlow,
		rect    = rl.Rectangle{0, 0, 32, 32},
	}
	g.textures[.BgStarFlare] = {
		texture = .BgStarFlare,
		rect    = rl.Rectangle{0, 0, 64, 64},
	}
}

assets_shaders_load :: proc(g: ^Game) {
	g.shaders[.Celestial_Debris_Layer] = {
		shader = .Celestial_Debris,
	}
	g.shaders[.Celestial_Terrestrial_Layer] = {
		shader = .Celestial_Terrestrial,
	}
	g.shaders[.Celestial_GasGiant_Layer] = {
		shader = .Celestial_GasGiant,
	}
	g.shaders[.Celestial_Star_Layer] = {
		shader = .Celestial_Star,
	}
	g.shaders[.Bg_Vignette] = {
		shader = .Vignette,
	}
	g.shaders[.BgGrid_Shader] = {
		shader = .BgGrid_Shimmer,
	}
	g.shaders[.Energy_Shader] = {
		shader = .Energy_Shader,
	}
}
