package main

import rl "vendor:raylib"

Game_InitParams :: struct {
	w: i32,
	h: i32,
}

game_init :: proc(params: Game_InitParams) -> ^Game {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_HIGHDPI})
	rl.InitWindow(params.w, params.h, "cellular automata")
	rl.SetTargetFPS(60)

	g := new(Game)

	assets_load_textures(g)
	assets_load_bg(g)
	assets_load_shaders(g)

	sys_render_init(g)
	sys_camera_init(g)
	sys_lifecycle_init(g)

	// TODO: Add Menus and whatnot
	// For now, just add set some params, add a star directly and start the game!
	g.params.g = 1
	g.params.densities[.Star] = 50
	g.params.radii[.Star] = 40
	g.params.densities[.DwarfPlanet] = 1
	g.params.radii[.DwarfPlanet] = 2
	g.params.launch_costs[.DwarfPlanet] = 10

	g.params.slingshot_power = 1
	g.params.slingshot_preview_len = 5
	g.params.sim_rate = 10 // TODO: This needs to be studied more and set appropriately

	// Default slingshot output to dwarf planet
	g.slingshot.output = Game_SlingshotOutput_Celestial {
		celestial = {.DwarfPlanet},
	}

	// Coefficient for economy
	g.params.k_energy_gain = 0.01
	g.params.k_energy_loss = 0.01
	g.params.k_energy_source = 1
	g.params.k_energy_momentum = 1000

	second_timer := Timer{0, 1}

	g.score_timer = second_timer
	g.events[0] = Game_Event_ObjectSpawn {
		pos = rl.Vector2(0),
		celestial = {.Star},
		density = g.params.densities[.Star],
		radius = g.params.radii[.Star],
		energy_source = {output = 10, timer = second_timer},
	}

	return g
}

game_free :: proc(g: ^Game) {
	rl.CloseWindow()

	// Free systems before asset
	sys_render_free(g)
	// Free assets
	assets_free_shaders(g)
	assets_free_bg(g)
	assets_free_textures(g)

}

game_run :: proc(g: ^Game) {
	sys_input(g)
	sys_modifier(g)
	sys_emitters(g)
	sys_physics(g)
	sys_score(g)
	sys_lifecycle(g)
	// sys_camera(g)
	sys_render(g)
}
