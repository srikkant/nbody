package game

import rl "vendor:raylib"

params_init :: proc(g: ^Game) {
	p := &g.params

	// ==========================================
	// PER-CELESTIAL-TYPE PARAMETERS
	// ==========================================

	p.celestials[.Asteroid] = {
		density          = 0.6,
		radius           = 1.0,
		launch_cost      = 3.0,
		color            = rl.Color{140, 140, 140, 160}, // cold, low-alpha gray
		visual_class     = .Debris,
		quad_multiplier  = 2.0,
		trail_multiplier = 0.0, // no trail
		glow_intensity   = 0.0,
	}

	p.celestials[.Moonlet] = {
		density          = 0.8,
		radius           = 1.5,
		launch_cost      = 5.0,
		color            = rl.Color{220, 220, 230, 220}, // crisp white
		visual_class     = .Debris,
		quad_multiplier  = 2.0,
		trail_multiplier = 0.3, // razor-thin, low-opacity
		glow_intensity   = 0.0,
	}

	p.celestials[.DwarfPlanet] = {
		density          = 1.0,
		radius           = 2.0,
		launch_cost      = 10.0,
		color            = rl.Color{120, 170, 175, 255}, // pale muted teal/slate
		visual_class     = .Terrestrial,
		quad_multiplier  = 4.0,
		trail_multiplier = 1.0,
		glow_intensity   = 0.0, // zero glow, hard edge
	}

	p.celestials[.SubEarth] = {
		density          = 1.2,
		radius           = 3.5,
		launch_cost      = 0.0,
		color            = rl.Color{130, 165, 120, 255}, // muted desaturated green
		visual_class     = .Terrestrial,
		quad_multiplier  = 4.0,
		trail_multiplier = 1.0,
		glow_intensity   = 0.0,
	}

	p.celestials[.SuperEarth] = {
		density          = 1.5,
		radius           = 5.0,
		launch_cost      = 0.0,
		color            = rl.Color{0, 200, 120, 255}, // vibrant jade/emerald
		visual_class     = .Terrestrial,
		quad_multiplier  = 4.0,
		trail_multiplier = 1.0,
		glow_intensity   = 0.15, // thin atmospheric halo
	}

	p.celestials[.MegaEarth] = {
		density          = 2.0,
		radius           = 7.0,
		launch_cost      = 0.0,
		color            = rl.Color{85, 120, 50, 255}, // deep forest green/olivine
		visual_class     = .Terrestrial,
		quad_multiplier  = 4.0,
		trail_multiplier = 1.0,
		glow_intensity   = 0.05, // dense core shadow effect
	}

	p.celestials[.MiniNeptune] = {
		density          = 2.5,
		radius           = 9.0,
		launch_cost      = 0.0,
		color            = rl.Color{0, 230, 255, 255}, // electric cyan
		visual_class     = .GasGiant,
		quad_multiplier  = 5.0,
		trail_multiplier = 1.5,
		glow_intensity   = 0.4, // soft linear glow
	}

	p.celestials[.SubNeptune] = {
		density          = 3.0,
		radius           = 11.0,
		launch_cost      = 0.0,
		color            = rl.Color{0, 130, 210, 255}, // deep sky blue
		visual_class     = .GasGiant,
		quad_multiplier  = 5.5,
		trail_multiplier = 1.5,
		glow_intensity   = 0.5, // two-tone core + envelope
	}

	p.celestials[.SuperNeptune] = {
		density          = 3.5,
		radius           = 13.0,
		launch_cost      = 0.0,
		color            = rl.Color{100, 60, 220, 255}, // neon indigo
		visual_class     = .GasGiant,
		quad_multiplier  = 6.0,
		trail_multiplier = 2.0,
		glow_intensity   = 0.7, // extends well past collision radius
	}

	p.celestials[.GiantPlanet] = {
		density          = 4.0,
		radius           = 15.0,
		launch_cost      = 0.0,
		color            = rl.Color{220, 170, 60, 255}, // warm banded amber/ochre
		visual_class     = .GasGiant,
		quad_multiplier  = 6.0,
		trail_multiplier = 4.0, // thick majestic smear
		glow_intensity   = 0.5,
	}

	p.celestials[.SuperJupiter] = {
		density          = 5.0,
		radius           = 18.0,
		launch_cost      = 0.0,
		color            = rl.Color{255, 120, 20, 255}, // intense neon orange
		visual_class     = .GasGiant,
		quad_multiplier  = 6.0,
		trail_multiplier = 3.0,
		glow_intensity   = 0.6, // thermal pulsing
	}

	p.celestials[.Star] = {
		density          = 50.0,
		radius           = 40.0,
		launch_cost      = 0.0,
		color            = rl.Color{255, 240, 200, 255}, // solar gold / warm white
		visual_class     = .Anchor,
		quad_multiplier  = 8.0, // massive bloom
		trail_multiplier = 0.0, // no kinetic trail (shader handles flares)
		glow_intensity   = 1.0,
	}

	p.celestials[.None] = {
		density          = 0.0,
		radius           = 0.0,
		launch_cost      = 0.0,
		color            = rl.Color{255, 255, 255, 255},
		visual_class     = .Debris,
		quad_multiplier  = 4.0,
		trail_multiplier = 1.0,
		glow_intensity   = 0.0,
	}

	// ==========================================
	// PHYSICS
	// ==========================================

	p.physics.gravity_constant = 10
	p.physics.mass_absorb_factor = 0.5
	p.physics.spawn_invincibility_duration_sec = 1.0
	p.physics.cursor_distance = 50.0
	p.physics.cursor_distance_squared = p.physics.cursor_distance * p.physics.cursor_distance
	p.physics.world_radius = 10000.0
	p.physics.world_radius_squared = p.physics.world_radius * p.physics.world_radius

	p.physics.energy_gain_factor = 1
	p.physics.energy_source_gain_factor = 1
	p.physics.energy_refund_factor = 0.1

	p.physics.collision_mass_loss_factor = 0.01
	p.physics.collision_shatter_threshold_factor = 50.0

	// ==========================================
	// SLINGSHOT
	// ==========================================

	p.slingshot.launch_power = 5
	p.slingshot.preview_duration = 1.0

	// ==========================================
	// EMITTER PRESETS
	// ==========================================

	p.emitter_presets[.Burst] = {
		interval        = 0.25,
		duration        = 5.0,
		max_count       = 12,
		cost_multiplier = 1.2,
	}

	p.emitter_presets[.Steady] = {
		interval        = 1.0,
		duration        = 20.0,
		max_count       = 20,
		cost_multiplier = 1.0,
	}

	p.emitter_presets[.Sustained] = {
		interval        = 2.0,
		duration        = 60.0,
		max_count       = 30,
		cost_multiplier = 0.8,
	}

	p.emitter_presets[.Trickle] = {
		interval        = 4.0,
		duration        = 999.0,
		max_count       = 8,
		cost_multiplier = 0.6,
	}

	// ==========================================
	// MODIFIERS
	// ==========================================

	p.modifiers[.Gravity_Boost] = {
		magnitude = 1.5,
		duration  = 30.0,
	}

	p.modifiers[.Energy_Magnet] = {
		magnitude = 1.25,
		duration  = 0.0,
	}

	g.effective_params = g.params
}
