package main

import rl "vendor:raylib"

Entity :: distinct u64

Timer :: struct {
	curr:     f32,
	interval: f32,
	done:     bool,
}

ComponentType :: enum {
	// Tag components
	Celestial,
	Emitter,
	// General components
	Position,
	Orbit,
	Velocity,
	Life,
	Mass,
	Radius,
	EnergySource,
	Renderable,
	CollectibleEnergy,
	Shockwave,
	ParticleBurst,
}

Signature :: bit_set[ComponentType]

PositionComponent :: struct {
	current:    rl.Vector2,
	trail:      [POSITION_TRAIL_LENGTH]rl.Vector2,
	trail_head: int,
}

OrbitComponent :: struct {
	points:          [MAX_ORBIT_LENGTH]rl.Vector2,
	head:            int,
	angle:           f32,
	count:           int,
	max_distance_sq: f32,
}

VelocityComponent :: struct {
	current:      rl.Vector2,
	acceleration: rl.Vector2,
}

MassComponent :: f32

RadiusComponent :: f32

LifeComponent :: struct {
	created_at: f32,
	remaining:  Timer,
}

EnergySourceComponent :: struct {
	output: f32,
	timer:  Timer,
}

EmitterComponent :: struct {
	emit_density:   f32,
	emit_radius:    f32,
	emit_vel:       rl.Vector2,
	emit_celestial: CelestialComponent,
	emit_color:     rl.Color,
	max_count:      int,
	current_count:  int,
	timer:          Timer,
	destroy_timer:  Timer,
	base_cost:      f64,
}

CelestialType :: enum {
	None,
	Asteroid,
	Moonlet,
	DwarfPlanet,
	SubEarth,
	SuperEarth,
	MegaEarth,
	MiniNeptune,
	SubNeptune,
	SuperNeptune,
	GiantPlanet,
	SuperJupiter,
	Star,
}

CelestialComponent :: struct {
	type: CelestialType,
}

RenderableComponent :: struct {
	color: rl.Color,
}

CollectibleEnergyComponent :: struct {
	energy: f64,
}

ShockwaveComponent :: struct {
	growth_rate: f32,
}

ParticleBurst_Particle :: struct {
	pos:          rl.Vector2,
	size:         f32,
	color:        rl.Color,
	velocity:     rl.Vector2,
	accelaration: rl.Vector2,
}

ParticleBurstComponent :: struct {
	active_count: int,
	particles:    #soa[MAX_PARTICLE_BURST_COUNT]ParticleBurst_Particle,
}

Game_SlingshotOutput_Emitter :: struct {
	emitter: EmitterComponent,
}

Game_SlingshotOutput_Celestial :: struct {
	celestial: CelestialComponent,
}

Game_SlingshotOutput :: union {
	Game_SlingshotOutput_Emitter,
	Game_SlingshotOutput_Celestial,
}

Game_Slingshot :: struct {
	output:         Game_SlingshotOutput,
	active:         bool,
	can_launch:     bool,
	start_pos:      rl.Vector2,
	launch_power:   f32,
	preview:        f32,
	preview_points: [100]rl.Vector2,
}

Game_Event_ObjectSpawn :: struct {
	pos:           rl.Vector2,
	density:       f32,
	radius:        f32,
	velocity:      rl.Vector2,
	show_orbit:    bool,
	renderable:    RenderableComponent,
	energy_source: EnergySourceComponent,
	emitter:       EmitterComponent,
	celestial:     CelestialComponent,
}

Game_Event_ObjectOutOfBounds :: struct {
	id: Entity,
}

Game_Event_ObjectDestroyed :: struct {
	id: Entity,
}

Game_Event_ApplyModifier :: Game_Modifier

Game_Event_Collision :: struct {
	id1: Entity,
	id2: Entity,
}

Game_Event :: union {
	Game_Event_ObjectSpawn,
	Game_Event_Collision,
	Game_Event_ObjectOutOfBounds,
	Game_Event_ObjectDestroyed,
}

Game_Entity :: struct {
	sig:                Signature,
	life:               LifeComponent,
	pos:                PositionComponent,
	orbit:              OrbitComponent,
	velocity:           VelocityComponent,
	mass:               MassComponent,
	radius:             RadiusComponent,
	energy_source:      EnergySourceComponent,
	emitter:            EmitterComponent,
	celestial:          CelestialComponent,
	renderable:         RenderableComponent,
	collectible_energy: CollectibleEnergyComponent,
	shockwave:          ShockwaveComponent,
	particle_burst:     ParticleBurstComponent,
}

Assets_Font :: enum {
	Heading,
	Body,
}

Assets_Texture :: enum {
	Blank,
	Bg,
	Atlas,
	BgStarGlow,
	BgStarFlare,
}

Assets_Shader :: enum {
	Vignette,
	Objects_Glow,
	Objects_Base,
	BgGrid_Shimmer,
	Energy_Shader,
}

Assets_Map :: struct {
	fonts:    [Assets_Font]rl.Font,
	textures: [Assets_Texture]rl.Texture2D,
	shaders:  [Assets_Shader]rl.Shader,
}

Game_TextureType :: enum {
	Blank,
	Objects_Celestial,
	Objects_Emitter,
	Markers_OutOfBounds,
	Collectibles_Energy,
	UI_Energy,
	UI_EnergyAverage,
	UI_ObjectCount,
	BgStarGlow,
	BgStarFlare,
}

Game_FontType :: enum {
	Heading,
	Body,
}

Game_ShaderType :: enum {
	Bg_Vignette,
	Stars_Layer,
	Objects_Layer,
	BgGrid_Shader,
	Energy_Shader,
}

Game_Texture :: struct {
	texture: Assets_Texture,
	rect:    rl.Rectangle,
}

Game_Font :: struct {
	font:    Assets_Font,
	size:    f32,
	spacing: f32,
}

Game_Shader :: struct {
	shader: Assets_Shader,
}

Game_Modifier :: struct {
	active:             bool,
	started_at:         f64,
	duration:           f64,
	slingshot_power:    f32,
	slingshot_preview:  f32,
	density_deltas:     [CelestialType]f32,
	radii_deltas:       [CelestialType]f32,
	launch_cost_deltas: [CelestialType]f32,
}

Game_Parameters_Physics :: struct {
	gravity_constant:               f32,
	densities:                      [CelestialType]f32,
	radii:                          [CelestialType]f32,
	launch_costs:                   [CelestialType]f32,
	slingshot_launch_power:         f32,
	slingshot_preview_length:       i32,
	simulation_rate_multiplier:     f32,
	energy_gain_coefficient:        f32,
	energy_loss_coefficient:        f32,
	energy_generation_coefficient:  f32,
	energy_momentum_coefficient:    f32,
	mass_loss_rate:                 f32,
	collision_mass_scaling_factor:  f32,
	shatter_base_energy:            f32,
	debris_mass_loss_fraction:      f32,
	out_of_bounds_refund_fraction:  f32,
	star_energy_multiplier:         f32,
	energy_collect_distance:        f32,
	energy_collect_distance_squared:f32,
	collision_debris_max_loss_fraction: f32,
	collision_debris_speed_coefficient: f32,
	spawn_invincibility_duration_sec:   f32,
	world_radius:                   f32,
	world_radius_squared:           f32,
	gravity_softening_factor:       f32,
	max_delta_time_sec:             f32,
}

Game_Parameters_Background :: struct {
	grid_spacing:                         f32,
	star_spawn_bounds_x:                  f32,
	star_spawn_bounds_y:                  f32,
	star_blink_speed_min:                 f32,
	star_blink_speed_max:                 f32,
	star_blink_phase_max:                 f32,
	star_sizes:                           [4][2]f32, // [layer][base, range]
	parallax_torus_width:                 f32,
	parallax_torus_height:                f32,
	parallax_layer_depths:                [4]f32,
	parallax_layer_zoom_multipliers:      [4]f32,
	parallax_layer_size_zoom_multipliers: [4]f32,
	star_size_min:                        f32,
	star_size_max:                        f32,
	star_flare_threshold:                 f32,
	star_flare_size_multiplier:           f32,
	star_flare_alpha_multiplier:          f32,
	star_layer_alpha_clamp_configs:       [4][3]f32, // [layer][zoom_div, min, max]

	// --- Nebulae ---
	nebula_spawn_bounds_x:        f32,
	nebula_spawn_bounds_y:        f32,
	nebula_layer_depth:           f32,
	nebula_zoom_multiplier:       f32,
	nebula_pulsation_base:        f32,
	nebula_pulsation_amplitude:   f32,
	nebula_zoom_radius_multiplier:f32,
	nebula_alpha_zoom_numerator:  f32,
	nebula_alpha_zoom_min:        f32,
	nebula_alpha_zoom_max:        f32,
	nebula_radius_ranges:         [4][2]f32, // [index][min, max]
	nebula_drift_speed_ranges:    [4][2]f32, // [index][min, max]
	star_layer1_start_index:      i32,
	star_layer2_start_index:      i32,
	star_layer3_start_index:      i32,
}

Game_Parameters_UI :: struct {
	cursor_indicator_radius: f32,
	menu_border_rounding:    f32,
	menu_segments:           i32,
}

Game_Parameters_Camera :: struct {
	zoom_min:                    f32,
	zoom_max:                    f32,
	zoom_in_interpolation_decay: f32,
	zoom_out_interpolation_decay:f32,
}

Game_Parameters_VFX :: struct {
	// --- Shockwaves & Particle Bursts ---
	shockwave_radius_start:              f32,
	shockwave_duration_base_sec:         f32,
	shockwave_duration_ln_coefficient:   f32,
	shockwave_growth_base:               f32,
	shockwave_growth_sqrt_coefficient:   f32,
	particle_burst_duration_base_sec:    f32,
	particle_burst_duration_ln_coefficient: f32,
	particle_burst_count_sqrt_coefficient: f32,
	particle_burst_count_base:           i32,
	particle_burst_speed_base:           f32,
	particle_burst_speed_sqrt_coefficient: f32,
	particle_burst_speed_variance_min:    f32,
	particle_burst_speed_variance_max:    f32,
	particle_burst_drag_coefficient:     f32,
	particle_burst_size_base:            f32,
	particle_burst_size_ln_coefficient:  f32,
	particle_burst_size_variance_min:     f32,
	particle_burst_size_variance_max:     f32,
	particle_burst_size_min:             f32,
	particle_burst_size_max:             f32,
	particle_burst_color_t1:             f32,
	particle_burst_color_t2:             f32,
	particle_burst_color_g1_base:        f32,
	particle_burst_color_g1_range:       f32,
	particle_burst_color_g2_base:        f32,
	particle_burst_color_g2_range:       f32,
	particle_burst_color_g3_base:        f32,
	particle_burst_color_g3_range:       f32,
	particle_burst_color_b3_range:       f32,

	// --- Fragment Vacuum & Drift ---
	fragments_count_min:                 i32,
	fragments_count_base:                i32,
	fragments_count_speed_multiplier:    f32,
	fragments_count_mod:                 f32,
	fragments_radius_mass_divisor:       f32,
	fragments_radius_mass_max:           f32,
	fragments_pull_distance_multiplier:  f32,
	fragments_pull_minimum_distance:     f32,
	fragments_pull_speed_base:           f32,
	fragments_drift_phase_multiplier:    f32,
	fragments_drift_frequency_x:         f32,
	fragments_drift_frequency_y:         f32,
	fragments_drift_amplitude_x:          f32,
	fragments_drift_amplitude_y:          f32,
	energy_fragment_size:                f32,
}

Game_Parameters :: struct {
	physics:    Game_Parameters_Physics,
	background: Game_Parameters_Background,
	ui:         Game_Parameters_UI,
	camera:     Game_Parameters_Camera,
	vfx:        Game_Parameters_VFX,
}


Game_RenderLayerType :: enum {
	Stars,
	OrbitPoints,
	Objects,
	Collectibles,
	Effects,
}

Game_RenderLayer :: struct {
	entities: [MAX_ENTITIES]Entity,
	count:    int,
}

Game_RenderState :: struct {
	rect:                rl.Rectangle,
	scale:               f32,

	// Entity layers
	layers:              [Game_RenderLayerType]Game_RenderLayer,

	// Buffers for all text
	score_energy:        [128]byte,
	score_objects_count: [128]byte,
	score_avg_energy:    [128]byte,

	// Menus & overlays
	show_upgrade_menu:   bool,
	upgrade_menu_rect:   rl.Rectangle,
	score_rect:          rl.Rectangle,
}

Game_Theme :: struct {
	name:                          string,
	color_bg:                      rl.Color,
	bg_grid_color:                 rl.Color,
	bg_nebula_colors:              [4]rl.Color,
	star_colors:                   [5]rl.Color,
	available_colors:              [10]rl.Color,
	ui_collect_area_opacity:       u8,
	ui_slingshot_preview_color:    rl.Color,
	ui_slingshot_launch_ok_color:  rl.Color,
	ui_slingshot_launch_err_color: rl.Color,
	ui_menu_bg_color:              rl.Color,
	ui_out_of_bounds_margin:       f32,
	bg_star_render_padding:        f32,
	camera_padding:                f32,
	bg_star_flare_layer:           int,
	bg_star_blink_amp_base:        f32,
	bg_star_blink_amp_scale:       f32,
}

Game_TimerType :: enum {
	Score,
	Trail,
}

Game_BgNebula :: struct {
	pos:         rl.Vector2,
	color:       rl.Color,
	radius:      f32,
	drift_speed: f32,
	drift_phase: f32,
}

Game_BgStar :: struct {
	pos:         rl.Vector2,
	layer:       int,
	size:        f32,
	blink_speed: f32,
	blink_phase: f32,
	color:       rl.Color,
}

Game :: struct {
	elapsed:             f32,
	params:              Game_Parameters,
	mouse_pos:           rl.Vector2,

	// Event queue
	events:              [MAX_ENTITIES]Game_Event,
	events_count:        u64,

	// Modifiers / Upgrades
	modifiers:           [MAX_MODIFIERS]Game_Modifier,

	// Render
	theme:               Game_Theme,
	camera:              rl.Camera2D,
	render:              Game_RenderState,
	bg_stars:            [BG_STAR_COUNT]Game_BgStar,
	bg_nebulae:          [BG_NEBULA_COUNT]Game_BgNebula,

	// Assets
	assets:              Assets_Map,
	textures:            [Game_TextureType]Game_Texture,
	shaders:             [Game_ShaderType]Game_Shader,
	fonts:               [Game_FontType]Game_Font,

	// Special render textures
	bg_texture:          rl.RenderTexture2D,

	// View options
	show_orbits:         bool,

	// Entities
	entities:            #soa[MAX_ENTITIES]Game_Entity,
	entities_count:      u64,
	free_entities:       [MAX_ENTITIES]Entity,
	free_entities_count: u64,

	// Input -> Slingshot
	slingshot:           Game_Slingshot,
	available_objects:   bit_set[CelestialType],

	// Timers
	// These are updated every frame
	timers:              [Game_TimerType]Timer,

	// Score
	energy:              f64,
	energy_rate_ticker:  int,
	energy_gains:        [AVG_CALC_TICKS]f64,
	energy_losses:       [AVG_CALC_TICKS]f64,
	total_objects:       int,

	// debug
	draw_debug_panel:    bool,
}
