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
	rl.HideCursor()

	g := new(Game)

	assets_map_load(g)
	assets_textures_load(g)
	assets_fonts_load(g)

	sys_render_init(g)
	sys_camera_init(g)
	sys_lifecycle_init(g)

	g.theme.color_bg = rl.Color{11, 12, 24, 255}

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
	g.params.k_collect_dist = 50
	g.params.k_collect_dist_sq = g.params.k_collect_dist * g.params.k_collect_dist

	g.available_objects += {.DwarfPlanet}

	g.available_colors[0] = rl.Color{255, 179, 0, 255} // bright orange
	g.available_colors[1] = rl.Color{255, 94, 98, 255} // coral / warm red
	g.available_colors[2] = rl.Color{0, 183, 255, 255} // sky cyan
	g.available_colors[3] = rl.Color{102, 255, 178, 255} // teal / aqua
	g.available_colors[4] = rl.Color{177, 228, 255, 255}
	g.available_colors[5] = rl.Color{255, 198, 255, 255} // soft pink
	g.available_colors[6] = rl.Color{255, 235, 59, 255} // bright yellow
	g.available_colors[7] = rl.Color{0, 132, 255, 255} // vivid blue
	g.available_colors[8] = rl.Color{102, 255, 102, 255} // lime green
	g.available_colors[9] = rl.Color{255, 255, 255, 255} // white

	g.timers[.Score] = Timer {
		interval = 1,
	}
	g.timers[.Trail] = Timer {
		interval = 0.05,
	}

	push_event(
		g,
		Game_Event_ObjectSpawn {
			pos = rl.Vector2(0),
			celestial = {.Star},
			density = g.params.densities[.Star],
			radius = g.params.radii[.Star],
			energy_source = {output = 10, timer = {interval = 1}},
			renderable = {rl.WHITE},
		},
	)

	return g
}

game_free :: proc(g: ^Game) {
	rl.CloseWindow()

	sys_render_free(g)
	assets_map_free(g)
	free(g)
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
