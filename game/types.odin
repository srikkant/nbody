package game

import rl "vendor:raylib"

Entity :: distinct u64

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
	Celestial_Debris,
	Celestial_Terrestrial,
	Celestial_GasGiant,
	Celestial_Star,
	BgGrid_Gravity,
	Energy_Shader,
	Vfx_Effects,
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
	Bg_StarGlow,
	Bg_StarFlare,
}

Game_FontType :: enum {
	Heading,
	Body,
	Menu_Label,
	Title,
}

Game_ShaderType :: enum {
	Bg_Vignette,
	Celestial_Debris_Layer,
	Celestial_Terrestrial_Layer,
	Celestial_GasGiant_Layer,
	Celestial_Star_Layer,
	BgGrid_Shader,
	Energy_Shader,
	Vfx_Shader,
}

Timer :: struct {
	curr:     f32,
	interval: f32,
	done:     bool,
}

ComponentType :: enum {
	Celestial,
	Emitter,
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

Game_VisualClass :: enum {
	Debris,
	Terrestrial,
	GasGiant,
	Anchor,
}

Game_CelestialParams :: struct {
	density:          f32,
	radius:           f32,
	launch_cost:      f32,
	color:            rl.Color,
	visual_class:     Game_VisualClass,
	quad_multiplier:  f32, // Render quad size = radius * quad_multiplier
	trail_multiplier: f32, // Trail thickness scale (0 = no trail)
	glow_intensity:   f32, // Shader glow envelope strength (0.0–1.0)
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

Game_SlingshotSnap :: struct {
	active:    bool,
	start_pos: rl.Vector2,
	end_pos:   rl.Vector2,
	color:     rl.Color,
	timer:     f32,
}

Game_SlingshotRingFlash :: struct {
	active:     bool,
	pos:        rl.Vector2,
	color:      rl.Color,
	radius:     f32,
	max_radius: f32,
	life:       f32, // 1.0 down to 0.0
}

Game_SlingshotState :: struct {
	available_objects: bit_set[CelestialType],
	output:            Game_SlingshotOutput,
	active:            bool,
	can_launch:        bool,
	start_pos:         rl.Vector2,
	shimmer_time:      f32,
	launch_power:      f32,
	preview:           f32,
	preview_points:    [600]rl.Vector2,
	preview_times:     [600]f32,
	snap:              Game_SlingshotSnap,
	ring_flashes:      [8]Game_SlingshotRingFlash,
	obj_color:         rl.Color,
	obj_radius:        f32,
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

Game_Event_ObjectSpawn_Preview :: struct {
	using _: Game_Event_ObjectSpawn,
}

Game_Event_ObjectOutOfBounds :: struct {
	id: Entity,
}

Game_Event_ObjectDestroyed :: struct {
	id: Entity,
}

Game_Event_ApplyModifier :: struct {
	modifier: Game_Modifier,
}

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

Game_Status :: enum {
	Menu,
	Playing,
	Paused,
	Exit,
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
	gravity_constant:                   f32,
	slingshot_launch_power:             f32,
	slingshot_preview_length:           i32,
	simulation_rate_multiplier:         f32,
	energy_gain_coefficient:            f32,
	energy_loss_coefficient:            f32,
	energy_generation_coefficient:      f32,
	energy_momentum_coefficient:        f32,
	mass_loss_rate:                     f32,
	collision_mass_scaling_factor:      f32,
	shatter_base_energy:                f32,
	debris_mass_loss_fraction:          f32,
	out_of_bounds_refund_fraction:      f32,
	star_energy_multiplier:             f32,
	energy_collect_distance:            f32,
	energy_collect_distance_squared:    f32,
	collision_debris_max_loss_fraction: f32,
	collision_debris_speed_coefficient: f32,
	spawn_invincibility_duration_sec:   f32,
	world_radius:                       f32,
	world_radius_squared:               f32,
	gravity_softening_factor:           f32,
	max_delta_time_sec:                 f32,
}

Game_Parameters_Bg :: struct {
	grid_spacing:                         f32,
	grid_line_width:                      f32,
	grid_warp_strength:                   f32,
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
	nebula_spawn_bounds_x:                f32,
	nebula_spawn_bounds_y:                f32,
	nebula_layer_depth:                   f32,
	nebula_zoom_multiplier:               f32,
	nebula_pulsation_base:                f32,
	nebula_pulsation_amplitude:           f32,
	nebula_zoom_radius_multiplier:        f32,
	nebula_alpha_zoom_numerator:          f32,
	nebula_alpha_zoom_min:                f32,
	nebula_alpha_zoom_max:                f32,
	nebula_radius_ranges:                 [4][2]f32, // [index][min, max]
	nebula_drift_speed_ranges:            [4][2]f32, // [index][min, max]
	star_layer1_start_index:              i32,
	star_layer2_start_index:              i32,
	star_layer3_start_index:              i32,
}

Game_Parameters_UI :: struct {
	cursor_indicator_radius: f32,
	menu_border_rounding:    f32,
	menu_segments:           i32,
	menu_width:              f32,
	menu_item_height:        f32,
	menu_section_gap:        f32,
	menu_inner_padding:      f32,
}

Game_Parameters_Camera :: struct {
	zoom_min:                     f32,
	zoom_max:                     f32,
	zoom_in_interpolation_decay:  f32,
	zoom_out_interpolation_decay: f32,
}

Game_Parameters_VFX :: struct {
	shockwave_radius_start:                 f32,
	shockwave_duration_base_sec:            f32,
	shockwave_duration_ln_coefficient:      f32,
	shockwave_growth_base:                  f32,
	shockwave_growth_sqrt_coefficient:      f32,
	shockwave_decel_start:                  f32,
	shockwave_decel_decay:                  f32,
	shockwave_quad_multiplier:              f32,
	particle_quad_multiplier:               f32,
	energy_quad_multiplier:                 f32,
	particle_burst_duration_base_sec:       f32,
	particle_burst_duration_ln_coefficient: f32,
	particle_burst_count_sqrt_coefficient:  f32,
	particle_burst_count_base:              i32,
	particle_burst_speed_base:              f32,
	particle_burst_speed_sqrt_coefficient:  f32,
	particle_burst_speed_variance_min:      f32,
	particle_burst_speed_variance_max:      f32,
	particle_burst_drag_coefficient:        f32,
	particle_burst_size_base:               f32,
	particle_burst_size_ln_coefficient:     f32,
	particle_burst_size_variance_min:       f32,
	particle_burst_size_variance_max:       f32,
	particle_burst_size_min:                f32,
	particle_burst_size_max:                f32,
	particle_burst_color_t1:                f32,
	particle_burst_color_t2:                f32,
	particle_burst_color_g1_base:           f32,
	particle_burst_color_g1_range:          f32,
	particle_burst_color_g2_base:           f32,
	particle_burst_color_g2_range:          f32,
	particle_burst_color_g3_base:           f32,
	particle_burst_color_g3_range:          f32,
	particle_burst_color_b3_range:          f32,
	fragments_count_min:                    i32,
	fragments_count_base:                   i32,
	fragments_count_speed_multiplier:       f32,
	fragments_count_mod:                    f32,
	fragments_radius_mass_divisor:          f32,
	fragments_radius_mass_max:              f32,
	fragments_pull_distance_multiplier:     f32,
	fragments_pull_minimum_distance:        f32,
	fragments_pull_speed_base:              f32,
	fragments_drift_phase_multiplier:       f32,
	fragments_drift_frequency_x:            f32,
	fragments_drift_frequency_y:            f32,
	fragments_drift_amplitude_x:            f32,
	fragments_drift_amplitude_y:            f32,
	energy_fragment_size:                   f32,
}

Game_Parameters :: struct {
	physics:    Game_Parameters_Physics,
	background: Game_Parameters_Bg,
	ui:         Game_Parameters_UI,
	camera:     Game_Parameters_Camera,
	vfx:        Game_Parameters_VFX,
	celestials: [CelestialType]Game_CelestialParams,
}

Game_RenderLayerType :: enum {
	Debris,
	Terrestrial,
	GasGiant,
	Stars,
	EmitterStations,
	OrbitPoints,
	Collectibles,
	Effects,
}

Game_RenderLayer :: struct {
	entities: [MAX_ENTITIES]Entity,
	count:    int,
}

Game_SlingshotMode :: enum {
	Normal,
	Emitter,
}

Game_RenderState :: struct {
	rect:                rl.Rectangle,
	scale:               f32,
	layers:              [Game_RenderLayerType]Game_RenderLayer,
	show_orbits:         bool,
	score_rect:          rl.Rectangle,
	score_energy:        [128]byte,
	score_objects_count: [128]byte,
	score_avg_energy:    [128]byte,
}

Game_Theme :: struct {
	name:                          string,
	camera_padding:                f32,
	color_bg:                      rl.Color,
	bg_grid_color:                 rl.Color,
	bg_nebula_colors:              [4]rl.Color,
	star_colors:                   [5]rl.Color,
	ui_collect_area_opacity:       u8,
	ui_slingshot_preview_color:    rl.Color,
	ui_slingshot_launch_ok_color:  rl.Color,
	ui_slingshot_launch_err_color: rl.Color,
	ui_menu_bg_color:              rl.Color,
	ui_menu_header_color:          rl.Color, // section header text
	ui_menu_item_color:            rl.Color, // normal item text
	ui_menu_item_hover_color:      rl.Color, // hovered item bg
	ui_menu_item_selected_color:   rl.Color, // selected item accent
	ui_menu_item_locked_color:     rl.Color, // locked/grayed out
	ui_menu_accent_color:          rl.Color, // accent glow line
	ui_menu_divider_color:         rl.Color, // section divider line
	ui_out_of_bounds_margin:       f32,
	bg_star_render_padding:        f32,
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

Game_Debug_Section :: enum {
	LaunchControls,
	Diagnostics,
	Physics,
	Slingshot,
	Energy,
	Collision,
	Celestials,
	Celestial_Asteroid,
	Celestial_Moonlet,
	Celestial_DwarfPlanet,
	Celestial_SubEarth,
	Celestial_SuperEarth,
	Celestial_MegaEarth,
	Celestial_MiniNeptune,
	Celestial_SubNeptune,
	Celestial_SuperNeptune,
	Celestial_GiantPlanet,
	Celestial_SuperJupiter,
	Star,
	Camera,
	VfxShockwaves,
	VfxParticles,
	VfxFragments,
	Background,
	Actions,
	Telemetry,
}

Game_Assets :: struct {
	assets_map: Assets_Map,
	textures:   [Game_TextureType]Game_Texture,
	shaders:    [Game_ShaderType]Game_Shader,
	fonts:      [Game_FontType]Game_Font,
}

Game_DebugState :: struct {
	initialized:                  bool,
	draw_panel:                   bool,
	input_blocked:                bool,
	hover_mode:                   int, // -1 = none, 0 = Normal, 1 = Emitter
	hover_celestial:              int, // -1 = none, or index into rendered list
	sections_open:                bit_set[Game_Debug_Section],
	scroll_offset:                rl.Vector2,
	scroll_bounds:                rl.Rectangle,
	selected_slingshot_mode:      Game_SlingshotMode,
	selected_slingshot_celestial: CelestialType,
}

Game_CameraState :: struct {
	rl_cam:          rl.Camera2D,
	shake_dir:       rl.Vector2,
	shake_intensity: f32,
}

Game_BgState :: struct {
	stars:   [BG_STAR_COUNT]Game_BgStar,
	nebulae: [BG_NEBULA_COUNT]Game_BgNebula,
}

Game_Score :: struct {
	energy:             f64,
	energy_rate_ticker: int,
	total_objects:      int,
	energy_gains:       [AVG_CALC_TICKS]f64,
	energy_losses:      [AVG_CALC_TICKS]f64,
}

Game :: struct {
	elapsed:             f32, // Time elapsed since the start of the game, in seconds. Updated every frame.
	dt:                  f32, // Last frame's delta time in seconds. Updated every frame.
	mouse_pos:           rl.Vector2, // Current mouse position. Calculated at the beginning of each frame.
	screenw:             f32,
	screenh:             f32,
	status:              Game_Status, // Current game status, controls the active systems.
	theme:               Game_Theme,
	params:              Game_Parameters,
	assets:              Game_Assets,
	debug:               Game_DebugState,
	camera:              Game_CameraState,
	render:              Game_RenderState,
	bg:                  Game_BgState,
	slingshot:           Game_SlingshotState,
	score:               Game_Score,
	timers:              [Game_TimerType]Timer, // These are updated every frame
	entities:            #soa[MAX_ENTITIES]Game_Entity,
	free_entities:       [MAX_ENTITIES]Entity,
	events:              [MAX_ENTITIES]Game_Event,
	modifiers:           [MAX_MODIFIERS]Game_Modifier,
	events_count:        u64,
	entities_count:      u64,
	free_entities_count: u64,
}

