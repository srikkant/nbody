package game

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

background_generate_stars :: proc(g: ^Game) {
	layer := 0

	for i in 0 ..< BG_STAR_COUNT {
		if i >= int(BG_STAR_LAYER_INDICES[layer]) {
			layer = layer + 1
		}

		g.render.bg.stars[i] = Render_Background_Star {
			layer       = layer,
			color       = rand.choice(g.theme.colors_bg_star[:]),
			size        = BG_STAR_SIZES[layer][0] + BG_STAR_SIZES[layer][1] * rand.float32(),
			blink_speed = rand.float32_range(BG_STAR_BLINK_SPEED_MIN, BG_STAR_BLINK_SPEED_MAX),
			blink_phase = rand.float32_range(0.0, BG_STAR_BLINK_PHASE_MAX),
			pos         = rl.Vector2 {
				rand.float32_range(-BG_STAR_SPAWN_BOUNDS_X, BG_STAR_SPAWN_BOUNDS_X),
				rand.float32_range(-BG_STAR_SPAWN_BOUNDS_Y, BG_STAR_SPAWN_BOUNDS_Y),
			},
		}
	}

}

background_generate_nebulae :: proc(g: ^Game) {
	for i in 0 ..< BG_NEBULA_COUNT {
		g.render.bg.nebulae[i] = {
			color       = g.theme.colors_bg_nebula[i],
			pos         = rl.Vector2 {
				rand.float32_range(-BG_NEBULA_SPAWN_BOUNDS_X, BG_NEBULA_SPAWN_BOUNDS_X),
				rand.float32_range(-BG_NEBULA_SPAWN_BOUNDS_Y, BG_NEBULA_SPAWN_BOUNDS_Y),
			},
			radius      = rand.float32_range(
				BG_NEBULA_RADIUS_RANGES[i][0],
				BG_NEBULA_RADIUS_RANGES[i][1],
			),
			drift_speed = rand.float32_range(
				BG_NEBULA_DRIFT_SPEED_RANGES[i][0],
				BG_NEBULA_DRIFT_SPEED_RANGES[i][1],
			),
			drift_phase = rand.float32_range(0.0, BG_STAR_BLINK_PHASE_MAX),
		}
	}
}

background_init :: proc(g: ^Game) {
	background_generate_nebulae(g)
	background_generate_stars(g)
}

background_draw :: proc(g: ^Game) {
	cx := g.screenw / 2.0
	cy := g.screenh / 2.0

	rl_begin_shader(g, .Bg_Vignette)
	rl.ClearBackground(rl.BLACK)
	rl_texture_draw(g, .Blank, {0, 0, g.screenw, g.screenh}, tint = g.theme.color_bg)
	rl_end_shader(g)

	for i in 0 ..< BG_NEBULA_COUNT {
		neb := g.render.bg.nebulae[i]

		dx := neb.pos.x - g.camera.rl_cam.target.x / BG_NEBULA_LAYER_DEPTH
		dy := neb.pos.y - g.camera.rl_cam.target.y / BG_NEBULA_LAYER_DEPTH

		draw_x := cx + dx * (1.0 + (g.camera.rl_cam.zoom - 1.0) * BG_NEBULA_ZOOM_MULTIPLIER)
		draw_y := cy + dy * (1.0 + (g.camera.rl_cam.zoom - 1.0) * BG_NEBULA_ZOOM_MULTIPLIER)

		breath :=
			BG_NEBULA_PULSATION_BASE +
			BG_NEBULA_PULSATION_AMPLITUDE * math.sin(g.elapsed * neb.drift_speed + neb.drift_phase)

		draw_radius :=
			neb.radius *
			breath *
			(1.0 + (g.camera.rl_cam.zoom - 1.0) * BG_NEBULA_ZOOM_RADIUS_MULTIPLIER)

		alpha_scale := clamp(1 / g.camera.rl_cam.zoom, BG_NEBULA_ALPHA_ZOOM_MIN, 1)

		color_inner := neb.color
		color_inner.a = u8(f32(neb.color.a) * alpha_scale)
		color_outer := neb.color
		color_outer.a = 0

		rl.DrawCircleGradient(i32(draw_x), i32(draw_y), draw_radius, color_inner, color_outer)
	}

	// Render the Starfield
	for i in 0 ..< BG_STAR_COUNT {
		star := g.render.bg.stars[i]

		dx := star.pos.x - g.camera.rl_cam.target.x / BG_PARALLAX_LAYER_DEPTHS[star.layer]
		dy := star.pos.y - g.camera.rl_cam.target.y / BG_PARALLAX_LAYER_DEPTHS[star.layer]

		draw_x :=
			cx +
			dx *
				(1.0 +
						(g.camera.rl_cam.zoom - 1.0) *
							BG_PARALLAX_LAYER_ZOOM_MULTIPLIERS[star.layer])
		draw_y :=
			cy +
			dy *
				(1.0 +
						(g.camera.rl_cam.zoom - 1.0) *
							BG_PARALLAX_LAYER_ZOOM_MULTIPLIERS[star.layer])

		if draw_x < 0 || draw_x > g.screenw || draw_y < 0 || draw_y > g.screenh {
			continue
		}

		draw_size :=
			star.size *
			(1.0 +
					(g.camera.rl_cam.zoom - 1.0) *
						BG_PARALLAX_LAYER_SIZE_ZOOM_MULTIPLIERS[star.layer])

		draw_size = clamp(draw_size, BG_STAR_SIZE_MIN, BG_STAR_SIZE_MAX)

		blink :=
			BG_STAR_PULSATION_BASE +
			BG_STAR_PULSATION_AMPLITUDE * math.sin(g.elapsed * star.blink_speed + star.blink_phase)

		alpha_scale := clamp(
			(g.camera.rl_cam.zoom - BG_STAR_LAYER_ALPHA_CLAMPS[star.layer][0]) /
			BG_STAR_LAYER_ALPHA_CLAMPS[star.layer][0],
			BG_STAR_LAYER_ALPHA_CLAMPS[star.layer][1],
			BG_STAR_LAYER_ALPHA_CLAMPS[star.layer][2],
		)

		color := star.color
		color.a = u8(f32(color.a) * blink * alpha_scale)

		if color.a == 0 do continue

		tex_type: Assets_TextureType = star.layer == 3 ? .Bg_StarFlare : .Bg_StarGlow

		radius := draw_size
		dest_rect := rl.Rectangle{draw_x, draw_y, radius * 2.0, radius * 2.0}
		origin := rl.Vector2{radius, radius}

		rotation := f32(0.0)
		if star.layer == 3 {
			rotation = star.blink_phase * 25.0
		}

		rl_texture_draw(g, tex_type, dest_rect, origin, rotation, color)

		if star.layer >= 2 {
			core_radius := radius * 0.28
			if core_radius >= 0.5 {
				core_col := rl.WHITE
				core_col.a = u8(f32(color.a) * 0.92)
				core_rect := rl.Rectangle{draw_x, draw_y, core_radius * 2.0, core_radius * 2.0}
				core_origin := rl.Vector2{core_radius, core_radius}
				rl_texture_draw(g, .Bg_StarGlow, core_rect, core_origin, 0.0, core_col)
			}
		}
	}
}

