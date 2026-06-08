package game

import "core:math"
import rl "vendor:raylib"

assets_map_load :: proc(g: ^Game) {
	blank_image := rl.GenImageColor(1, 1, rl.WHITE)
	defer rl.UnloadImage(blank_image)

	g.assets.assets_map.textures[.Blank] = rl.LoadTextureFromImage(blank_image)
	g.assets.assets_map.textures[.Bg] = rl.LoadTexture("./assets/textures/bg.png")
	g.assets.assets_map.textures[.Atlas] = rl.LoadTexture("./assets/textures/atlas.png")

	g.assets.assets_map.shaders[.Celestial_Debris] = rl.LoadShader(
		nil,
		"./assets/shaders/celestial_debris.frag",
	)
	g.assets.assets_map.shaders[.Vignette] = rl.LoadShader(nil, "./assets/shaders/vignette.frag")
	g.assets.assets_map.shaders[.Celestial_Terrestrial] = rl.LoadShader(
		nil,
		"./assets/shaders/celestial_terrestrial.frag",
	)
	g.assets.assets_map.shaders[.Celestial_GasGiant] = rl.LoadShader(
		nil,
		"./assets/shaders/celestial_gasgiant.frag",
	)
	g.assets.assets_map.shaders[.Celestial_Star] = rl.LoadShader(
		nil,
		"./assets/shaders/celestial_star.frag",
	)
	g.assets.assets_map.shaders[.BgGrid_Gravity] = rl.LoadShader(
		nil,
		"./assets/shaders/bg_grid_gravity.frag",
	)
	g.assets.assets_map.shaders[.Energy_Shader] = rl.LoadShader(
		nil,
		"./assets/shaders/energy_glow.frag",
	)
	g.assets.assets_map.shaders[.Vfx_Effects] = rl.LoadShader(
		nil,
		"./assets/shaders/vfx_effects.frag",
	)

	g.assets.assets_map.fonts[.Heading] = rl.LoadFontEx("./assets/fonts/heading.ttf", 18, nil, 0)
	g.assets.assets_map.fonts[.Body] = rl.LoadFontEx("./assets/fonts/body.ttf", 14, nil, 0)

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
		g.assets.assets_map.textures[.BgStarGlow] = rl.LoadTextureFromImage(img)
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
		g.assets.assets_map.textures[.BgStarFlare] = rl.LoadTextureFromImage(img)
		rl.UnloadImage(img)
	}
}

assets_map_free :: proc(g: ^Game) {
	rl.UnloadFont(g.assets.assets_map.fonts[.Heading])
	rl.UnloadFont(g.assets.assets_map.fonts[.Body])
	rl.UnloadTexture(g.assets.assets_map.textures[.Bg])
	rl.UnloadTexture(g.assets.assets_map.textures[.Atlas])
	rl.UnloadTexture(g.assets.assets_map.textures[.Blank])
	rl.UnloadTexture(g.assets.assets_map.textures[.BgStarGlow])
	rl.UnloadTexture(g.assets.assets_map.textures[.BgStarFlare])
	rl.UnloadShader(g.assets.assets_map.shaders[.Celestial_Debris])
	rl.UnloadShader(g.assets.assets_map.shaders[.Vignette])
	rl.UnloadShader(g.assets.assets_map.shaders[.Celestial_Terrestrial])
	rl.UnloadShader(g.assets.assets_map.shaders[.Celestial_GasGiant])
	rl.UnloadShader(g.assets.assets_map.shaders[.Celestial_Star])
	rl.UnloadShader(g.assets.assets_map.shaders[.BgGrid_Gravity])
	rl.UnloadShader(g.assets.assets_map.shaders[.Energy_Shader])
	rl.UnloadShader(g.assets.assets_map.shaders[.Vfx_Effects])
}

assets_fonts_load :: proc(g: ^Game) {
	g.assets.fonts[.Heading] = {
		font = .Heading,
		size = 18,
	}

	g.assets.fonts[.Body] = {
		font = .Body,
		size = 14,
	}

	g.assets.fonts[.Menu_Label] = {
		font = .Body,
		size = 11,
	}

	g.assets.fonts[.Title] = {
		font = .Heading,
		size = 36,
	}
}

assets_textures_load :: proc(g: ^Game) {
	g.assets.textures[.Blank] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
	g.assets.textures[.Objects_Celestial] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
	g.assets.textures[.Markers_OutOfBounds] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
	g.assets.textures[.Objects_Emitter] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
	g.assets.textures[.Collectibles_Energy] = {
		texture = .Blank,
		rect    = rl.Rectangle{0, 0, 1, 1},
	}
	g.assets.textures[.UI_Energy] = {
		texture = .Atlas,
		rect    = rl.Rectangle{0, 0, 96, 96},
	}
	g.assets.textures[.UI_ObjectCount] = {
		texture = .Atlas,
		rect    = rl.Rectangle{96, 0, 96, 96},
	}
	g.assets.textures[.UI_EnergyAverage] = {
		texture = .Atlas,
		rect    = rl.Rectangle{192, 0, 96, 96},
	}
	g.assets.textures[.Bg_StarGlow] = {
		texture = .BgStarGlow,
		rect    = rl.Rectangle{0, 0, 32, 32},
	}
	g.assets.textures[.Bg_StarFlare] = {
		texture = .BgStarFlare,
		rect    = rl.Rectangle{0, 0, 64, 64},
	}
}

assets_shaders_load :: proc(g: ^Game) {
	g.assets.shaders[.Celestial_Debris_Layer] = {
		shader = .Celestial_Debris,
	}
	g.assets.shaders[.Celestial_Terrestrial_Layer] = {
		shader = .Celestial_Terrestrial,
	}
	g.assets.shaders[.Celestial_GasGiant_Layer] = {
		shader = .Celestial_GasGiant,
	}
	g.assets.shaders[.Celestial_Star_Layer] = {
		shader = .Celestial_Star,
	}
	g.assets.shaders[.Bg_Vignette] = {
		shader = .Vignette,
	}
	g.assets.shaders[.BgGrid_Shader] = {
		shader = .BgGrid_Gravity,
	}
	g.assets.shaders[.Energy_Shader] = {
		shader = .Energy_Shader,
	}
	g.assets.shaders[.Vfx_Shader] = {
		shader = .Vfx_Effects,
	}
}

