package main

import rl "vendor:raylib"

params_init_defaults :: proc(p: ^Game_Parameters) {
	// ==========================================
	// PHYSICS & GAMEPLAY PARAMETERS
	// ==========================================
	p.physics.gravity_constant = 1.0

	p.physics.densities[.Star] = 50.0
	p.physics.radii[.Star] = 40.0

	p.physics.densities[.SuperJupiter] = 5.0
	p.physics.radii[.SuperJupiter] = 18.0
	p.physics.densities[.GiantPlanet] = 4.0
	p.physics.radii[.GiantPlanet] = 15.0
	p.physics.densities[.SuperNeptune] = 3.5
	p.physics.radii[.SuperNeptune] = 13.0
	p.physics.densities[.SubNeptune] = 3.0
	p.physics.radii[.SubNeptune] = 11.0
	p.physics.densities[.MiniNeptune] = 2.5
	p.physics.radii[.MiniNeptune] = 9.0
	p.physics.densities[.MegaEarth] = 2.0
	p.physics.radii[.MegaEarth] = 7.0
	p.physics.densities[.SuperEarth] = 1.5
	p.physics.radii[.SuperEarth] = 5.0
	p.physics.densities[.SubEarth] = 1.2
	p.physics.radii[.SubEarth] = 3.5
	p.physics.densities[.DwarfPlanet] = 1.0
	p.physics.radii[.DwarfPlanet] = 2.0
	p.physics.densities[.Moonlet] = 0.8
	p.physics.radii[.Moonlet] = 1.5
	p.physics.densities[.Asteroid] = 0.6
	p.physics.radii[.Asteroid] = 1.0

	p.physics.launch_costs[.DwarfPlanet] = 10.0
	p.physics.launch_costs[.Moonlet] = 5.0
	p.physics.launch_costs[.Asteroid] = 3.0

	p.physics.slingshot_launch_power = 1.0
	p.physics.slingshot_preview_length = 5
	p.physics.simulation_rate_multiplier = 10.0

	p.physics.energy_gain_coefficient = 0.01
	p.physics.energy_loss_coefficient = 0.01
	p.physics.energy_generation_coefficient = 1.0
	p.physics.energy_momentum_coefficient = 1000.0
	p.physics.mass_loss_rate = 0.5
	p.physics.collision_mass_scaling_factor = 3.0
	p.physics.shatter_base_energy = 50.0
	p.physics.debris_mass_loss_fraction = 0.25
	p.physics.out_of_bounds_refund_fraction = 0.1
	p.physics.star_energy_multiplier = 0.05
	p.physics.energy_collect_distance = 50.0
	p.physics.energy_collect_distance_squared = p.physics.energy_collect_distance * p.physics.energy_collect_distance

	p.physics.collision_debris_max_loss_fraction = 0.4
	p.physics.collision_debris_speed_coefficient = 0.01

	p.physics.spawn_invincibility_duration_sec = 1.0
	p.physics.world_radius = 1000.0
	p.physics.world_radius_squared = p.physics.world_radius * p.physics.world_radius
	p.physics.gravity_softening_factor = 2.0
	p.physics.max_delta_time_sec = 0.05

	// ==========================================
	// BACKGROUND & PARALLAX PARAMETERS
	// ==========================================
	p.background.grid_spacing = 60.0

	p.background.star_spawn_bounds_x = 2000.0
	p.background.star_spawn_bounds_y = 1500.0
	p.background.star_blink_speed_min = 1.0
	p.background.star_blink_speed_max = 3.5
	p.background.star_blink_phase_max = 6.28

	p.background.star_layer1_start_index = BG_STAR_COUNT * 55 / 100
	p.background.star_layer2_start_index = BG_STAR_COUNT * 80 / 100
	p.background.star_layer3_start_index = BG_STAR_COUNT * 95 / 100

	// Star size configurations: [layer][base, range]
	p.background.star_sizes[0] = {0.8, 0.6}
	p.background.star_sizes[1] = {1.3, 0.7}
	p.background.star_sizes[2] = {1.9, 0.9}
	p.background.star_sizes[3] = {2.6, 1.2}

	p.background.parallax_torus_width = 4000.0
	p.background.parallax_torus_height = 3000.0

	p.background.parallax_layer_depths = {12.0, 5.0, 2.0, 0.8}
	p.background.parallax_layer_zoom_multipliers = {0.05, 0.25, 0.6, 1.0}
	p.background.parallax_layer_size_zoom_multipliers = {0.0, 0.15, 0.4, 0.8}

	p.background.star_size_min = 0.4
	p.background.star_size_max = 6.0

	p.background.star_flare_threshold = 2.2
	p.background.star_flare_size_multiplier = 2.5
	p.background.star_flare_alpha_multiplier = 0.35

	// Star alpha clamp configs: [layer][zoom_div/multiplier/offset, min, max]
	p.background.star_layer_alpha_clamp_configs[0] = {1.5, 0.45, 0.8}
	p.background.star_layer_alpha_clamp_configs[1] = {1.0, 0.55, 0.9}
	p.background.star_layer_alpha_clamp_configs[2] = {5.0, 0.3, 0.9}
	p.background.star_layer_alpha_clamp_configs[3] = {0.15, 0.2, 0.9}

	// --- Nebulae ---
	p.background.nebula_spawn_bounds_x = 600.0
	p.background.nebula_spawn_bounds_y = 400.0
	p.background.nebula_layer_depth = 10.0
	p.background.nebula_zoom_multiplier = 0.08
	p.background.nebula_pulsation_base = 0.9
	p.background.nebula_pulsation_amplitude = 0.1
	p.background.nebula_zoom_radius_multiplier = 0.05
	p.background.nebula_alpha_zoom_numerator = 1.2
	p.background.nebula_alpha_zoom_min = 0.3
	p.background.nebula_alpha_zoom_max = 1.0

	// Radius ranges: [index][min, max]
	p.background.nebula_radius_ranges[0] = {850.0, 1200.0}
	p.background.nebula_radius_ranges[1] = {800.0, 1100.0}
	p.background.nebula_radius_ranges[2] = {850.0, 1200.0}
	p.background.nebula_radius_ranges[3] = {700.0, 1000.0}

	// Drift speed ranges: [index][min, max]
	p.background.nebula_drift_speed_ranges[0] = {0.3, 0.8}
	p.background.nebula_drift_speed_ranges[1] = {0.4, 0.9}
	p.background.nebula_drift_speed_ranges[2] = {0.2, 0.6}
	p.background.nebula_drift_speed_ranges[3] = {0.5, 1.0}

	// ==========================================
	// UI PARAMETERS
	// ==========================================
	p.ui.cursor_indicator_radius = 4.0
	p.ui.menu_border_rounding = 0.2
	p.ui.menu_segments = 1

	// ==========================================
	// CAMERA PARAMETERS
	// ==========================================
	p.camera.zoom_min = 0.01
	p.camera.zoom_max = 2.0
	p.camera.zoom_in_interpolation_decay = 0.6
	p.camera.zoom_out_interpolation_decay = 8.0

	// ==========================================
	// VFX PARAMETERS
	// ==========================================
	p.vfx.shockwave_radius_start = 1.0
	p.vfx.shockwave_duration_base_sec = 0.4
	p.vfx.shockwave_duration_ln_coefficient = 0.03
	p.vfx.shockwave_growth_base = 60.0
	p.vfx.shockwave_growth_sqrt_coefficient = 0.15

	p.vfx.particle_burst_duration_base_sec = 0.4
	p.vfx.particle_burst_duration_ln_coefficient = 0.03
	p.vfx.particle_burst_count_sqrt_coefficient = 0.6
	p.vfx.particle_burst_count_base = 25
	p.vfx.particle_burst_speed_base = 30.0
	p.vfx.particle_burst_speed_sqrt_coefficient = 0.15
	p.vfx.particle_burst_speed_variance_min = 50.0
	p.vfx.particle_burst_speed_variance_max = 150.0
	p.vfx.particle_burst_drag_coefficient = 2.5
	p.vfx.particle_burst_size_base = 0.5
	p.vfx.particle_burst_size_ln_coefficient = 0.03
	p.vfx.particle_burst_size_variance_min = 50.0
	p.vfx.particle_burst_size_variance_max = 150.0
	p.vfx.particle_burst_size_min = 0.4
	p.vfx.particle_burst_size_max = 1.2

	p.vfx.particle_burst_color_t1 = 0.3
	p.vfx.particle_burst_color_t2 = 0.7
	p.vfx.particle_burst_color_g1_base = 30.0
	p.vfx.particle_burst_color_g1_range = 90.0
	p.vfx.particle_burst_color_g2_base = 120.0
	p.vfx.particle_burst_color_g2_range = 90.0
	p.vfx.particle_burst_color_g3_base = 210.0
	p.vfx.particle_burst_color_g3_range = 45.0
	p.vfx.particle_burst_color_b3_range = 230.0

	// --- Fragment Vacuum & Drift ---
	p.vfx.fragments_count_min = 6
	p.vfx.fragments_count_base = 3
	p.vfx.fragments_count_speed_multiplier = 0.7
	p.vfx.fragments_count_mod = 4.0
	p.vfx.fragments_radius_mass_divisor = 100.0
	p.vfx.fragments_radius_mass_max = 5.0
	p.vfx.fragments_pull_distance_multiplier = 3.0
	p.vfx.fragments_pull_minimum_distance = 0.1
	p.vfx.fragments_pull_speed_base = 240.0
	p.vfx.fragments_drift_phase_multiplier = 0.73
	p.vfx.fragments_drift_frequency_x = 1.5
	p.vfx.fragments_drift_frequency_y = 1.8
	p.vfx.fragments_drift_amplitude_x = 0.15
	p.vfx.fragments_drift_amplitude_y = 0.15
	p.vfx.energy_fragment_size = 2.0
}

theme_init_default :: proc(t: ^Game_Theme) {
	t.name = "Cosmic Space"
	t.color_bg = rl.Color{12, 12, 24, 255}
	t.bg_grid_color = rl.Color{0, 183, 255, 60}

	t.bg_nebula_colors[0] = rl.Color{10, 150, 180, 20}
	t.bg_nebula_colors[1] = rl.Color{200, 30, 140, 16}
	t.bg_nebula_colors[2] = rl.Color{110, 30, 200, 16}
	t.bg_nebula_colors[3] = rl.Color{220, 120, 20, 12}

	t.star_colors[0] = rl.Color{255, 140, 80, 255}
	t.star_colors[1] = rl.Color{170, 220, 255, 255}
	t.star_colors[2] = rl.Color{230, 180, 255, 255}
	t.star_colors[3] = rl.Color{255, 230, 150, 255}
	t.star_colors[4] = rl.WHITE

	t.available_colors[0] = rl.Color{255, 179, 0, 255} // bright orange
	t.available_colors[1] = rl.Color{255, 94, 98, 255} // coral / warm red
	t.available_colors[2] = rl.Color{0, 183, 255, 255} // sky cyan
	t.available_colors[3] = rl.Color{102, 255, 178, 255} // teal / aqua
	t.available_colors[4] = rl.Color{177, 228, 255, 255}
	t.available_colors[5] = rl.Color{255, 198, 255, 255} // soft pink
	t.available_colors[6] = rl.Color{255, 235, 59, 255} // bright yellow
	t.available_colors[7] = rl.Color{0, 132, 255, 255} // vivid blue
	t.available_colors[8] = rl.Color{102, 255, 102, 255} // lime green
	t.available_colors[9] = rl.Color{255, 255, 255, 255} // white

	t.ui_collect_area_opacity = 64
	t.ui_slingshot_preview_color = rl.Color{255, 255, 255, 200}
	t.ui_slingshot_launch_ok_color = rl.GRAY
	t.ui_slingshot_launch_err_color = rl.RED
	t.ui_menu_bg_color = rl.Color{100, 100, 100, 128}
	t.ui_out_of_bounds_margin = 40.0
	t.bg_star_render_padding = 40.0
	t.camera_padding = 200.0
	t.bg_star_flare_layer = 3
	t.bg_star_blink_amp_base = 0.5
	t.bg_star_blink_amp_scale = 0.35
}
