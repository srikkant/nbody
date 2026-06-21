package game

import rl "vendor:raylib"

/*
 * Slingshot related parameters.
 */
Parameters_Slingshot :: struct {
	/*
     * Launch power multiplier applied to the slingshot's output velocity
     * @default 1.0
     */
	launch_power:     f32,
	/*
     * Duration of the slingshot's preview in seconds
     * @default 1.0
     */
	preview_duration: f32,
}

/*
 * Parameters that control the universal physics laws
 */
Parameters_Physics :: struct {
	/*
     * Universal Gravity constant `G` used in standard newtonian formulae
     * @default 1.0
     */
	gravity_constant:                   f32,
	/*
     * Multiplier applied to the mass when one celestial entity absorbs another
     * The source entity gains the mass of the entity multiplied by this factor.
     * @default 0.5
     */
	mass_absorb_factor:                 f32,
    /*
     * Multiplier applied to mass when collision occurs resulting in debris. This
     * will be multiplied by the relative velocity
     * @default 0.01
     */
	collision_mass_loss_factor: f32,
    /*
     * Multiplier applied to computation to decide whether a collision should be a shatter or a merge
     * @default 50
     */
	collision_shatter_threshold_factor:  f32,
    /*
     * Duration after spawn when celestials are invincible in seconds
     * @default 1
     */
	spawn_invincibility_duration_sec:   f32,
    /*
     * Cursor interaction distance
     * @default 50
     */
	cursor_distance:                    f32,
    /*
     * Square of the cursor interaction distance, precomputed
     * @default 50 * 50
     */
	cursor_distance_squared:            f32,
    /*
     * Radius of the world after which objects are considered out of bounds
     * @default 10000
     */
	world_radius:                       f32,
    /*
     * Square of the world radius, precomputed
     * @default 10000 * 10000
     */
	world_radius_squared:               f32,
	

	/*
     * Multiplier applied to energy gain computations
     * This is related to economy more than physics
     * @default 0.01
     */
	energy_gain_factor: f32,
    /*
     * Multiplier applied to the energy emitted by a source
     * @default 0.05
     */
	energy_source_gain_factor:             f32,
    /*
     * Multiplier applied when calculating how much energy is refunded when
     * object is destroyed, out of bounds etc.
     * @default 0.1
     */
	energy_refund_factor:            f32,
}

Parameters_Celestial :: struct {
	density:          f32,
	radius:           f32,
	launch_cost:      f32,
	color:            rl.Color,
	visual_class:     Celestial_Class,
	quad_multiplier:  f32, // Render quad size = radius * quad_multiplier
	trail_multiplier: f32, // Trail thickness scale (0 = no trail)
	glow_intensity:   f32, // Shader glow envelope strength (0.0–1.0)
}

/*
 * Parameters that control the flow of the game
 * These are typically modifiable through modifiers to change the game experience
 * Modifications can be new game modes, through upgrade trees etc.
 */
GameParameters :: struct {
	celestials: [Celestial_Type]Parameters_Celestial,
	physics:    Parameters_Physics,
	slingshot:  Parameters_Slingshot,
}

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

	p.physics.gravity_constant = 1.0
	p.physics.mass_absorb_factor = 0.5
	p.physics.spawn_invincibility_duration_sec = 1.0
	p.physics.cursor_distance = 50.0
	p.physics.cursor_distance_squared = p.physics.cursor_distance * p.physics.cursor_distance
	p.physics.world_radius = 10000.0
	p.physics.world_radius_squared = p.physics.world_radius * p.physics.world_radius

	p.physics.energy_gain_factor = 0.01
	p.physics.energy_source_gain_factor = 0.05
	p.physics.energy_refund_factor = 0.1

	p.physics.collision_mass_loss_factor = 0.01
	p.physics.collision_shatter_threshold_factor = 50.0

	// ==========================================
	// SLINGSHOT
	// ==========================================

	p.slingshot.launch_power = 1.0
	p.slingshot.preview_duration = 1.0
}

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
	t.ui_out_of_bounds_margin = 40.0
	t.bg_star_render_padding = 40.0
	t.camera_padding = 200.0
}

