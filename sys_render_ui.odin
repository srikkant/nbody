package main

import "core:fmt"
import rl "vendor:raylib"

UI_PADDING: f32 = 10

sys_render_ui :: proc(g: ^Game) {
	sx, sy: f32 = 20, 20

	score_width := sys_render_ui_score(g, sx, sy)
	sys_render_ui_menu(g, rl.Rectangle{sx, sy, score_width, RENDER_HEIGHT - (2 * sy)})
}

sys_render_ui_score :: proc(g: ^Game, sx: f32, sy: f32) -> f32 {
	x, icon_y, icon_size: f32 = sx + UI_PADDING * 2, sy + UI_PADDING * 2, 24
	text_y := icon_y + (icon_size - g.fonts[.Body].size) / 2

	cstr: cstring
	text_size: rl.Vector2
	avg_energy: f64
	for i in 0 ..< RATE_CALC_TICKS {
		avg_energy += g.energy_gains[i] / RATE_CALC_TICKS
	}

	rl_texture_draw(g, .UI_Energy, {x, icon_y, icon_size, icon_size})
	str := fmt.bprintf(g.render_state.score_energy[:], "%.2f", g.energy)
	cstr = cstring(raw_data(str))

	x += icon_size + UI_PADDING
	text_size = rl_text_measure(g, .Body, cstr)
	rl_text_draw(g, .Body, cstr, {x, text_y})

	x += text_size.x + UI_PADDING * 2
	rl_texture_draw(g, .UI_EnergyAverage, {x, icon_y, icon_size, icon_size})
	str = fmt.bprintf(g.render_state.score_avg_energy[:], "%.2f/sec", avg_energy)
	cstr = cstring(raw_data(str))

	x += icon_size + UI_PADDING
	text_size = rl_text_measure(g, .Body, cstr)
	rl_text_draw(g, .Body, cstr, {x, text_y})

	x += text_size.x + UI_PADDING * 2
	rl_texture_draw(g, .UI_ObjectCount, {x, icon_y, icon_size, icon_size})
	str = fmt.bprintf(g.render_state.score_objects_count[:], "%d", g.total_objects)
	cstr = cstring(raw_data(str))

	x += icon_size + UI_PADDING
	text_size = rl_text_measure(g, .Body, cstr)
	rl_text_draw(g, .Body, cstr, {x, text_y})

	total_width := x + text_size.x + UI_PADDING
	return total_width
}

sys_render_ui_menu :: proc(g: ^Game, rect: rl.Rectangle) {
	if !g.render_state.show_upgrade_menu do return

	rl.DrawRectangleRounded(rect, 0.2, 1, rl.Color{100, 100, 100, 128})
}
