package game
import rl "vendor:raylib"

theme_init :: proc(g: ^Game) {
	t := &g.theme
	t.name = "nbody: Default"

	t.color_bg = rl.Color{12, 12, 24, 255}
	t.cursor_size = 4

	t.bg_nebula_colors[0] = rl.Color{10, 150, 180, 20}
	t.bg_nebula_colors[1] = rl.Color{200, 30, 140, 16}
	t.bg_nebula_colors[2] = rl.Color{110, 30, 200, 16}
	t.bg_nebula_colors[3] = rl.Color{220, 120, 20, 12}

	t.star_colors[0] = rl.Color{255, 140, 80, 255}
	t.star_colors[1] = rl.Color{170, 220, 255, 255}
	t.star_colors[2] = rl.Color{230, 180, 255, 255}
	t.star_colors[3] = rl.Color{255, 230, 150, 255}
	t.star_colors[4] = rl.WHITE

	t.ui_collect_area_opacity = 64
	t.ui_slingshot_preview_color = rl.Color{255, 255, 255, 200}
	t.ui_slingshot_launch_ok_color = rl.GRAY
	t.ui_slingshot_launch_err_color = rl.RED
}

