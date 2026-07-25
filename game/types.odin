package game

import rl "vendor:raylib"

/*
 * Status of the game at the present
 * This decides what systems to run and what to show on the UI.
 */
Status :: enum {
	Playing,
	Paused,
	Exit,
}

/*
 * Type of objects in the game
 * This is not directly used in the ecs.
 * Used only in the slingshot system
 */
ObjectType :: enum {
	Celestial,
	Emitter,
}

/*
 * General timer object to be used for all interval/timeout operations in the game.
 * Use `utils_match_update_timer` to update this timer each frame.
 */
Timer :: struct {
	curr:     f32,
	interval: f32,
	done:     bool,
}

/*
 * Built in timers as a part of the game object.
 * These are updated at the beginning of each frame.
 */
Timer_BuiltIn :: enum {
	Score,
	Trail,
	Autosave,
}

/*
 * Assets used by the game
 */
Assets :: struct {
	assets_map: Assets_Map,
	textures:   [Assets_TextureType]Assets_Texture,
	shaders:    [Assets_ShaderType]Assets_Shader,
	fonts:      [Assets_FontType]Assets_Font,
}

Assets_RawFont :: enum {
	SyncopateBold,
	SyncopateRegular,
}

Assets_RawTexture :: enum {
	Blank,
	Bg,
	Atlas,
	BgStarGlow,
	BgStarFlare,
}

Assets_RawShader :: enum {
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
	fonts:    [Assets_RawFont]rl.Font,
	textures: [Assets_RawTexture]rl.Texture2D,
	shaders:  [Assets_RawShader]rl.Shader,
}

Assets_TextureType :: enum {
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

Assets_FontType :: enum {
	Title,
	Subtitle,
	Body,
	BodyBold,
}

Assets_ShaderType :: enum {
	Bg_Vignette,
	Celestial_Debris_Layer,
	Celestial_Terrestrial_Layer,
	Celestial_GasGiant_Layer,
	Celestial_Star_Layer,
	BgGrid_Shader,
	Energy_Shader,
	Vfx_Shader,
}

Assets_Texture :: struct {
	texture: Assets_RawTexture,
	rect:    rl.Rectangle,
}

Assets_Font :: struct {
	font:    rl.Font,
	size:    f32,
	spacing: f32,
}

Assets_Shader :: struct {
	shader: Assets_RawShader,
}

/*
 * Entity used in the ecs
 * Since the number of entities in game is only in the thousands,
 * preallocate everything
 */
Entity :: struct {
	sig:                Entity_Signature,
	life:               Component_Life,
	pos:                Component_Position,
	orbit:              Component_Orbit,
	velocity:           Component_Velocity,
	mass:               Component_Mass,
	radius:             Component_Radius,
	energy_source:      Component_EnergySource,
	emitter:            Component_Emitter,
	celestial:          Component_Celestial,
	renderable:         Component_Renderable,
	collectible_energy: Component_CollectibleEnergy,
	shockwave:          Component_Shockwave,
}

/*
 * Entity ID: 0 to max entities count
 */
Entity_Id :: distinct u64

/*
 * Bitwise component signature
 */
Entity_Signature :: bit_set[Component_Type]

/*
 * Component types of our ECS
 */
Component_Type :: enum {
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
}

//
// Various components used in the ecs.
// These are a part of the entity always.
//

Component_Position :: struct {
	current:    rl.Vector2,
	trail:      [POSITION_TRAIL_LENGTH]rl.Vector2,
	trail_head: int,
}

Component_Orbit :: struct {
	points:          [MAX_ORBIT_LENGTH]rl.Vector2,
	head:            int,
	angle:           f32,
	count:           int,
	max_distance_sq: f32,
}

Component_Velocity :: struct {
	current:      rl.Vector2,
	acceleration: rl.Vector2,
}

Component_Mass :: f32

Component_Radius :: f32

Component_Life :: struct {
	created_at: f32,
	remaining:  Timer,
}

Component_EnergySource :: struct {
	output: f32,
	timer:  Timer,
}

Component_Emitter :: struct {
	emit_density:   f32,
	emit_radius:    f32,
	emit_vel:       rl.Vector2,
	emit_celestial: Component_Celestial,
	emit_color:     rl.Color,
	max_count:      int,
	current_count:  int,
	timer:          Timer,
	destroy_timer:  Timer,
	base_cost:      f64,
}

Component_Celestial :: struct {
	type: Celestial_Type,
}

Component_Renderable :: struct {
	color: rl.Color,
}

Component_CollectibleEnergy :: struct {
	energy: f64,
}

Component_Shockwave :: struct {
	growth_rate: f32,
	color:       rl.Color,
}

Celestial_Type :: enum {
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

Celestial_Class :: enum {
	Debris,
	Terrestrial,
	GasGiant,
	Anchor,
}

/*
 * Various events pushed to the game queue
 * These are added through the frame and processed in the lifecycle system
 */
GameEvent :: union {
	GameEvent_ObjectSpawn,
	GameEvent_Collision,
	GameEvent_Object_OutOfBounds,
	GameEvent_Object_Destroyed,
	GameEvent_Object_Demolish,
	GameEvent_Shockwave,
}

GameEvent_ObjectSpawn :: struct {
	pos:           rl.Vector2,
	density:       f32,
	radius:        f32,
	velocity:      rl.Vector2,
	show_orbit:    bool,
	renderable:    Component_Renderable,
	energy_source: Component_EnergySource,
	emitter:       Component_Emitter,
	celestial:     Component_Celestial,
}

GameEvent_Object_OutOfBounds :: struct {
	id: Entity_Id,
}

GameEvent_Object_Destroyed :: struct {
	id: Entity_Id,
}

GameEvent_Object_Demolish :: struct {}

GameEvent_Collision :: struct {
	id1: Entity_Id,
	id2: Entity_Id,
}

GameEvent_Shockwave :: struct {
	pos:    rl.Vector2,
	energy: f64,
	color:  rl.Color,
}

/*
 * Manage the input state of the game
 * This is processed at the beginning of each frame and updated.
 */
Input :: struct {
	// Should the input be ignored in this frame?
	ignore:            bool,
	// Current mouse position in screen space.
	mouse_pos_screen:  rl.Vector2,
	// Current mouse position. Calculated at the beginning of each frame.
	mouse_pos:         rl.Vector2,
	// Previous mouse position in world space.
	prev_mouse_pos:    rl.Vector2,
	// Current mouse scroll
	mouse_scroll_move: rl.Vector2,
	// Current queued action
	action:            Input_Action,
	// Control scheme of the game
	controls:          [Input_Action]Input_Matcher,
}

Input_InteractionType :: enum {
	Down,
	Pressed,
	Released,
}

Input_Matcher_Base :: struct {
	interaction: Input_InteractionType,
	status:      Status,
}

Input_Matcher_Mouse :: struct {
	using base: Input_Matcher_Base,
	key:        rl.MouseButton,
}

Input_Matcher_Keyboard :: struct {
	using base: Input_Matcher_Base,
	key:        rl.KeyboardKey,
}

Input_Matcher :: union {
	Input_Matcher_Mouse,
	Input_Matcher_Keyboard,
}

Input_Action :: enum {
	None,
	Game_Pause,
	Game_Resume,
	View_ToggleOrbit,
	Game_Reset,
}

/*
 * Data for rendering the actual game on screen.
 * Contains elements like the background, render properties
 * as well as any per frame state computed.
 */
Render :: struct {
	rect:        rl.Rectangle,
	scale:       f32,
	show_orbits: bool,
	layers:      [Render_LayerType]Render_Layer,
	bg:          Render_Background,
}

Render_LayerType :: enum {
	Debris,
	Terrestrial,
	GasGiant,
	Stars,
	EmitterStations,
	OrbitPoints,
	Collectibles,
	Effects,
}

Render_Layer :: struct {
	entities: [MAX_ENTITIES]Entity_Id,
	count:    int,
}

Render_Background_Nebula :: struct {
	pos:         rl.Vector2,
	color:       rl.Color,
	radius:      f32,
	drift_speed: f32,
	drift_phase: f32,
}

Render_Background_Star :: struct {
	pos:         rl.Vector2,
	layer:       int,
	size:        f32,
	blink_speed: f32,
	blink_phase: f32,
	color:       rl.Color,
}

Render_Background :: struct {
	stars:   [BG_STAR_COUNT]Render_Background_Star,
	nebulae: [BG_NEBULA_COUNT]Render_Background_Nebula,
}

Drag_Intent :: enum {
	Velocity,
	Radius,
}

Emitter_Preset :: enum {
	Burst,
	Steady,
	Sustained,
	Trickle,
}

Parameters_Emitter_Preset :: struct {
	interval:        f32,
	duration:        f32,
	max_count:       int,
	cost_multiplier: f64,
}

Control_Menu_Tab :: enum {
	Direct,
	Emitter,
	Hardware,
}

Control_Menu :: struct {
	active_tab:         Control_Menu_Tab,
	selected_celestial: Celestial_Type,
	selected_preset:    Emitter_Preset,
	opacity:            f32,
	rect:               rl.Rectangle,
	tab_rects:          [Control_Menu_Tab]rl.Rectangle,
	celestial_rects:    [Celestial_Type]rl.Rectangle,
	preset_rects:       [Emitter_Preset]rl.Rectangle,
}

/*
 * Theme used in the game.
 * Right now, this is not structured very well and it's just a random collection of properties.
 * @TODO Clean this up to a more structured token system
 */
Theme :: struct {
	name:                        string,
	color_bg:                    rl.Color,
	color_error:                 rl.Color,
	colors_bg_nebula:            [4]rl.Color,
	colors_bg_star:              [5]rl.Color,
	spacing_s:                   f32,
	spacing_m:                   f32,
	spacing_l:                   f32,
	color_cursor_collector:      rl.Color,
	color_slingshot_trail:       rl.Color,
	color_slingshot_trail_error: rl.Color,
	margin_top_bar:              f32,
	font_title:                  Assets_FontType,
}

/*
 * Controls the state of the in game help messages that show up based on the context.
 */
Help :: struct {
	launch_done: bool,
}

Modifier_Kind :: enum {
	Gravity_Boost,
	Energy_Magnet,
}

/*
 * Modifiers applied to the game properties.
 * These will update the game parameters and the current state in some way.
 */
Modifier :: struct {
	kind:      Modifier_Kind,
	permanent: bool,
	timer:     Timer,
}

Parameters_Modifier :: struct {
	magnitude: f32, // multiplier applied to the kind's target field
	duration:  f32, // seconds; temp kinds only (0.0 for permanent)
}

/*
 * The slingshot is the primary interactive mechanic for the player.
 * Slingshots launch or output various objects like celestials, emitters etc.
 */
Slingshot :: struct {
	available_objects: bit_set[Celestial_Type],
	output:            Slingshot_Output,
	status:            Slingshot_Status,
	can_launch:        bool,
	start_pos:         rl.Vector2,
	end_pos:           rl.Vector2,
	shimmer_time:      f32,
	launch_power:      f32,
	preview:           f32,
	preview_points:    [600]rl.Vector2,
	preview_times:     [600]f32,
	preview_count:     int,
	snap:              Slingshot_Snap,
	ring_flashes:      [8]Slingshot_RingFlash,
	obj_color:         rl.Color,
	obj_radius:        f32,
}

Slingshot_Status :: enum {
	Inactive,
	Active,
}

Slingshot_Output_Emitter :: struct {
	emitter: Component_Emitter,
}

Slingshot_Output_Celestial :: struct {
	celestial: Component_Celestial,
}

Slingshot_Output_Hardware :: struct {}

Slingshot_Output :: union {
	Slingshot_Output_Emitter,
	Slingshot_Output_Celestial,
	Slingshot_Output_Hardware,
}

Slingshot_Snap :: struct {
	active:    bool,
	start_pos: rl.Vector2,
	end_pos:   rl.Vector2,
	color:     rl.Color,
	timer:     f32,
}

Slingshot_RingFlash :: struct {
	active:     bool,
	pos:        rl.Vector2,
	color:      rl.Color,
	radius:     f32,
	max_radius: f32,
	life:       f32, // 1.0 down to 0.0
}

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
	collision_mass_loss_factor:         f32,
	/*
     * Multiplier applied to computation to decide whether a collision should be a shatter or a merge
     * @default 50
     */
	collision_shatter_threshold_factor: f32,
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
	energy_gain_factor:                 f32,
	/*
     * Multiplier applied to the energy emitted by a source
     * @default 0.05
     */
	energy_source_gain_factor:          f32,
	/*
     * Multiplier applied when calculating how much energy is refunded when
     * object is destroyed, out of bounds etc.
     * @default 0.1
     */
	energy_refund_factor:               f32,
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
Parameters :: struct {
	celestials:      [Celestial_Type]Parameters_Celestial,
	emitter_presets: [Emitter_Preset]Parameters_Emitter_Preset,
	physics:         Parameters_Physics,
	slingshot:       Parameters_Slingshot,
	modifiers:       [Modifier_Kind]Parameters_Modifier,
}

/*
 * Central data store that contains all the data required for the game to run.
 * A `Game` is created when the program runs and destroyed at the end.
 * This is passed around throughout for state management.
 */
Game :: struct {
	elapsed:             f32, // Time elapsed since the start of the game, in seconds. Updated every frame.
	dt:                  f32, // Last frame's delta time in seconds. Updated every frame.
	screenw:             f32,
	screenh:             f32,
	scale:               f32,
	status:              Status, // Current game status, controls the active systems.
	theme:               Theme,
	params:              Parameters,
	effective_params:    Parameters,
	assets:              Assets,
	input:               Input,
	help:                Help,
	camera:              Camera,
	render:              Render,
	slingshot:           Slingshot,
	control_menu:        Control_Menu,
	score:               Score,
	timers:              [Timer_BuiltIn]Timer, // These are updated every frame
	entities_count:      u64,
	entities:            #soa[MAX_ENTITIES]Entity,
	free_entities_count: u64,
	free_entities:       [MAX_ENTITIES]Entity_Id,
	events_count:        u64,
	events:              [MAX_ENTITIES]GameEvent,
	delete_entities:     [MAX_ENTITIES]bool, // Scratch buffer used by sys_lifecycle
	mass_delta:          [MAX_ENTITIES]f32, // Scratch buffer used by sys_lifecycle
	modifiers_count:     u64,
	modifiers:           [MAX_MODIFIERS]Modifier,
}
