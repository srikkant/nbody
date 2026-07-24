package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_control_menu_init_defaults :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	testing.expect(t, g.control_menu.active_tab == .Direct, "default tab should be Direct")
	testing.expect(
		t,
		g.control_menu.selected_celestial == .DwarfPlanet,
		"default celestial should be DwarfPlanet",
	)
	testing.expect(t, g.control_menu.selected_preset == .Steady, "default preset should be Steady")

	out, ok := g.slingshot.output.(game.Slingshot_Output_Celestial)
	testing.expect(t, ok, "slingshot output should be celestial")
	testing.expect(t, out.celestial.type == .DwarfPlanet)
}

@(test)
test_control_menu_update_output_direct :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	g.control_menu.active_tab = .Direct
	g.control_menu.selected_celestial = .Asteroid
	game.ui_control_menu_update_output(g)

	out, ok := g.slingshot.output.(game.Slingshot_Output_Celestial)
	testing.expect(t, ok, "slingshot output should be celestial")
	testing.expect(t, out.celestial.type == .Asteroid)
}

@(test)
test_control_menu_update_output_emitter :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	g.control_menu.active_tab = .Emitter
	g.control_menu.selected_celestial = .Asteroid
	g.control_menu.selected_preset = .Burst
	game.ui_control_menu_update_output(g)

	out, ok := g.slingshot.output.(game.Slingshot_Output_Emitter)
	testing.expect(t, ok, "slingshot output should be emitter")
	testing.expect(t, out.emitter.emit_celestial.type == .Asteroid)
	testing.expect(t, out.emitter.max_count == 12)
	testing.expect(t, out.emitter.timer.interval == 0.25)
	testing.expect(t, out.emitter.destroy_timer.interval == 5.0)

	// cost: max(asteroid.launch_cost(1) * 1.2, 1.0) = 1.2
	expect_f64_approx(t, out.emitter.base_cost, 1.2)
}

@(test)
test_control_menu_click_tab_change :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Set up menu rects
	g.control_menu.rect = rl.Rectangle{0, 500, 800, 100}
	g.control_menu.tab_rects[.Direct] = rl.Rectangle{10, 500, 100, 30}
	g.control_menu.tab_rects[.Emitter] = rl.Rectangle{120, 500, 100, 30}

	// Click Emitter tab
	g.input.mouse_pos_screen = rl.Vector2{150, 515}
	consumed := game.ui_control_menu_handle_click(g)

	testing.expect(t, consumed, "click should be consumed")
	testing.expect(t, g.control_menu.active_tab == .Emitter, "tab should change to Emitter")
	_, ok := g.slingshot.output.(game.Slingshot_Output_Emitter)
	testing.expect(t, ok, "output should change to emitter variant")
}

@(test)
test_control_menu_click_celestial_change :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	// Unlock Asteroid
	g.slingshot.available_objects = {.DwarfPlanet, .Asteroid}

	g.control_menu.rect = rl.Rectangle{0, 500, 800, 100}
	g.control_menu.celestial_rects[.Asteroid] = rl.Rectangle{10, 540, 80, 25}

	g.input.mouse_pos_screen = rl.Vector2{50, 550}
	consumed := game.ui_control_menu_handle_click(g)

	testing.expect(t, consumed, "click should be consumed")
	testing.expect(
		t,
		g.control_menu.selected_celestial == .Asteroid,
		"selected celestial should be Asteroid",
	)
	out, ok := g.slingshot.output.(game.Slingshot_Output_Celestial)
	testing.expect(t, ok)
	testing.expect(t, out.celestial.type == .Asteroid)
}

@(test)
test_control_menu_click_preset_change :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	g.control_menu.active_tab = .Emitter
	g.control_menu.rect = rl.Rectangle{0, 500, 800, 100}
	g.control_menu.preset_rects[.Sustained] = rl.Rectangle{500, 540, 80, 25}

	g.input.mouse_pos_screen = rl.Vector2{540, 550}
	consumed := game.ui_control_menu_handle_click(g)

	testing.expect(t, consumed, "click should be consumed")
	testing.expect(
		t,
		g.control_menu.selected_preset == .Sustained,
		"selected preset should be Sustained",
	)
	out, ok := g.slingshot.output.(game.Slingshot_Output_Emitter)
	testing.expect(t, ok)
	testing.expect(t, out.emitter.max_count == 30)
}

@(test)
test_control_menu_click_intercept_blank :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)

	g.control_menu.rect = rl.Rectangle{0, 500, 800, 100}

	// Click in blank area of the menu
	g.input.mouse_pos_screen = rl.Vector2{400, 550}
	consumed := game.ui_control_menu_handle_click(g)

	testing.expect(t, consumed, "click in menu container should still be consumed")
}
