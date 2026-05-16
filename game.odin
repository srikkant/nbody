package main

import rl "vendor:raylib"

Game_InitParams :: struct {
	w: i32,
	h: i32,
}

game_init :: proc(params: Game_InitParams) -> ^Game {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_RESIZABLE})
	rl.InitWindow(params.w, params.h, "n-body forge")
	rl.SetTargetFPS(60)

	g := new(Game)

	assets_load_textures(g)
	assets_load_bg(g)
	assets_load_shaders(g)

	sys_render_init(g)
	sys_camera_init(g)
	sys_lifecycle_init(g)

	g.params.g = 1

	g.params.densities[.Star] = 50
	g.params.radii[.Star] = 40

	g.params.densities[.SuperJupiter] = 5
	g.params.radii[.SuperJupiter] = 18
	g.params.densities[.GiantPlanet] = 4
	g.params.radii[.GiantPlanet] = 15
	g.params.densities[.SuperNeptune] = 3.5
	g.params.radii[.SuperNeptune] = 13
	g.params.densities[.SubNeptune] = 3
	g.params.radii[.SubNeptune] = 11
	g.params.densities[.MiniNeptune] = 2.5
	g.params.radii[.MiniNeptune] = 9
	g.params.densities[.MegaEarth] = 2
	g.params.radii[.MegaEarth] = 7
	g.params.densities[.SuperEarth] = 1.5
	g.params.radii[.SuperEarth] = 5
	g.params.densities[.SubEarth] = 1.2
	g.params.radii[.SubEarth] = 3.5
	g.params.densities[.DwarfPlanet] = 1
	g.params.radii[.DwarfPlanet] = 2
	g.params.densities[.Moonlet] = 0.8
	g.params.radii[.Moonlet] = 1.5
	g.params.densities[.Asteroid] = 0.6
	g.params.radii[.Asteroid] = 1

	g.params.launch_costs[.DwarfPlanet] = 10
	g.params.launch_costs[.Moonlet] = 5
	g.params.launch_costs[.Asteroid] = 3

	g.params.slingshot_power = 1
	g.params.slingshot_preview_len = 5
	g.params.sim_rate = 10

	g.slingshot.output = Game_SlingshotOutput_Celestial {
		celestial = {.DwarfPlanet},
	}

	g.params.k_energy_gain = 0.01
	g.params.k_energy_loss = 0.01
	g.params.k_energy_source = 1
	g.params.k_energy_momentum = 1000
	g.params.k_mass_loss = 0.5
	g.params.k_collision_mass_scale = 3.0
	g.params.k_shatter_base = 50
	g.params.k_debris_mass_loss = 0.25
	g.params.k_out_of_bounds_refund = 0.1
	g.params.k_star_energy_scale = 0.05

	g.available_objects += {.DwarfPlanet}

	second_timer := Timer{0, 1}

	g.score_timer = second_timer
	push_event(
		g,
		Game_Event_ObjectSpawn {
			pos = rl.Vector2(0),
			celestial = {.Star},
			density = g.params.densities[.Star],
			radius = g.params.radii[.Star],
			energy_source = {output = 10, timer = second_timer},
		},
	)

	return g
}

game_free :: proc(g: ^Game) {
	rl.CloseWindow()

	sys_render_free(g)
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
	sys_render(g)
}
