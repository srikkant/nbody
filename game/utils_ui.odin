package game

import rl "vendor:raylib"

// Draws a button with the given text and rectangle.
// Returns true if the button is hovered and clicked.
ui_draw_button :: proc(g: ^Game, text: cstring, rect: rl.Rectangle) -> bool {
	mouse_pos := rl.GetMousePosition()
	hover := rl.CheckCollisionPointRec(mouse_pos, rect)

	bg_color := hover ? g.theme.ui_menu_item_hover_color : rl.Color{0, 0, 0, 0}
	border_color := hover ? g.theme.ui_menu_item_selected_color : g.theme.ui_menu_accent_color
	text_color := hover ? g.theme.ui_menu_item_selected_color : g.theme.ui_menu_item_color
	text_size := rl_text_measure(g, .Body, text)
	text_pos := rl.Vector2 {
		rect.x + (rect.width - text_size.x) / 2.0,
		rect.y + (rect.height - text_size.y) / 2.0,
	}

	rl.DrawRectangleRounded(rect, 0.2, 4, bg_color)
	rl.DrawRectangleRoundedLines(rect, 0.2, 4, border_color)
	rl_text_draw(g, .Body, text, text_pos, text_color)

	return hover && rl.IsMouseButtonPressed(.LEFT)
}

