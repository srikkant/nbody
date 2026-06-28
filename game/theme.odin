package game
import rl "vendor:raylib"

theme_init :: proc(g: ^Game) {
	t := &g.theme
	t.name = "nbody: Default"

	t.color_bg = rl.Color{12, 12, 24, 255}
	t.color_error = rl.RED

	t.spacing_s = 16 * g.scale
	t.spacing_m = 32 * g.scale
	t.spacing_l = 48 * g.scale

	t.colors_bg_nebula[0] = rl.Color{10, 150, 180, 40}
	t.colors_bg_nebula[1] = rl.Color{200, 30, 140, 32}
	t.colors_bg_nebula[2] = rl.Color{110, 30, 200, 32}
	t.colors_bg_nebula[3] = rl.Color{220, 120, 20, 24}

	t.colors_bg_star[0] = rl.Color{255, 140, 80, 255}
	t.colors_bg_star[1] = rl.Color{170, 220, 255, 255}
	t.colors_bg_star[2] = rl.Color{230, 180, 255, 255}
	t.colors_bg_star[3] = rl.Color{255, 230, 150, 255}
	t.colors_bg_star[4] = rl.WHITE

	t.color_cursor_collector = rl.Color{255, 255, 255, 64}
	t.color_slingshot_trail = rl.GRAY
	t.color_slingshot_trail_error = t.color_error

	t.margin_top_bar = t.spacing_m

	t.font_title = .Title
}
