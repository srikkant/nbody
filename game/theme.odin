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
	t.ui_menu_bg_color = rl.Color{12, 16, 28, 220} // Sleek dark translucent panel background
	t.ui_menu_header_color = rl.Color{0, 200, 255, 220} // Cyan header text
	t.ui_menu_item_color = rl.Color{200, 210, 220, 200} // Cool gray text
	t.ui_menu_item_hover_color = rl.Color{0, 200, 255, 30} // Subtle cyan glow bg
	t.ui_menu_item_selected_color = rl.Color{0, 230, 255, 255} // Bright cyan accent
	t.ui_menu_item_locked_color = rl.Color{80, 80, 100, 100} // Dim grayed out
	t.ui_menu_accent_color = rl.Color{0, 200, 255, 80} // Thin accent lines
	t.ui_menu_divider_color = rl.Color{60, 70, 90, 120} // Subtle dividers
	t.bg_star_render_padding = 40.0
	t.camera_padding = 200.0
}

