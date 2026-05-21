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
	points: [MAX_ORBIT_LENGTH]rl.Vector2,
	head:   int,
	angle:  f32,
	count:  int,
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

Game_Parameters :: struct {
	g:                      f32,
	densities:              [CelestialType]f32,
	radii:                  [CelestialType]f32,
	launch_costs:           [CelestialType]f32,
	slingshot_power:        f32,
	slingshot_preview_len:  i32,
	sim_rate:               f32,
	k_energy_gain:          f32,
	k_energy_loss:          f32,
	k_energy_source:        f32,
	k_energy_momentum:      f32,
	k_mass_loss:            f32,
	k_collision_mass_scale: f32,
	k_shatter_base:         f32,
	k_debris_mass_loss:     f32,
	k_out_of_bounds_refund: f32,
	k_star_energy_scale:    f32,
	k_collect_dist:         f32,
	k_collect_dist_sq:      f32,
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
	color_bg: rl.Color,
}

Game_TimerType :: enum {
	Score,
	Trail,
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
	view:                rl.Rectangle,
	view_scale:          f32,
	camera:              rl.Camera2D,
	render_state:        Game_RenderState,
	bg_stars:            [BG_STAR_COUNT]Game_BgStar,

	// Assets
	assets:              Assets_Map,
	textures:            [Game_TextureType]Game_Texture,
	shaders:             [Game_ShaderType]Game_Shader,
	fonts:               [Game_FontType]Game_Font,

	// Special render textures
	render_target:       rl.RenderTexture2D,
	bg_texture:          rl.RenderTexture2D,

	// View options
	available_colors:    [10]rl.Color,
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
	energy_gains:        [RATE_CALC_TICKS]f64,
	energy_losses:       [RATE_CALC_TICKS]f64,
	total_objects:       int,

	// debug
	draw_debug_panel:    bool,
}
