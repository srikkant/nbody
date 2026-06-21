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

/*
 * Manage the input state of the game
 * This is processed at the beginning of each frame and updated.
 */
Input :: struct {
	// Should the input be ignored in this frame?
	ignore:            bool,
	// Current mouse position. Calculated at the beginning of each frame.
	mouse_pos:         rl.Vector2,
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
	Slingshot_Activate,
	Slingshot_Move,
	Slingshot_Release,
	Slingshot_Cancel,
	View_ToggleOrbit,
	Demolish_Object,
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
	launch_menu: Render_LaunchMenu,
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

Render_LaunchMenu :: struct {
	opacity:        f32,
	inactive_timer: Timer,
	h_idx:          int, // horizontal selection is for object types
	v_idx:          int, // vertical selection is for subselections within objects.
}

/*
 * Theme used in the game.
 * Right now, this is not structured very well and it's just a random collection of properties.
 * @TODO Clean this up to a more structured token system
 */
Theme :: struct {
	name:                          string,
	camera_padding:                f32,
	color_bg:                      rl.Color,
	bg_grid_color:                 rl.Color,
	bg_nebula_colors:              [4]rl.Color,
	star_colors:                   [5]rl.Color,
	cursor_size:                   f32,
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

/*
 * Controls the state of the in game tutorials that show up based on the context.
 */
Tutorial :: struct {
	launch_done: bool,
}

/*
 * Modifiers applied to the game properties.
 * These will update the game parameters and the current state in some way.
 * TODO: Implement this system
 */
Modifier :: struct {
	active:     bool,
	started_at: f64,
	duration:   f64,
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
	snap:              Slingshot_Snap,
	ring_flashes:      [8]Slingshot_RingFlash,
	obj_color:         rl.Color,
	obj_radius:        f32,
}

Slingshot_Status :: enum {
	Inactive,
	Active,
	Released,
}

Slingshot_Output_Emitter :: struct {
	emitter: Component_Emitter,
}

Slingshot_Output_Celestial :: struct {
	celestial: Component_Celestial,
}

Slingshot_Output :: union {
	Slingshot_Output_Emitter,
	Slingshot_Output_Celestial,
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
 * Central data store that contains all the data required for the game to run.
 * A `Game` is created when the program runs and destroyed at the end.
 * This is passed around throughout for state management.
 */
Game :: struct {
	elapsed:             f32, // Time elapsed since the start of the game, in seconds. Updated every frame.
	dt:                  f32, // Last frame's delta time in seconds. Updated every frame.
	screenw:             f32,
	screenh:             f32,
	status:              Status, // Current game status, controls the active systems.
	theme:               Theme,
	params:              GameParameters,
	assets:              Assets,
	input:               Input,
	tutorial:            Tutorial,
	camera:              Camera,
	render:              Render,
	slingshot:           Slingshot,
	score:               Score,
	timers:              [Timer_BuiltIn]Timer, // These are updated every frame
	entities_count:      u64,
	entities:            #soa[MAX_ENTITIES]Entity,
	free_entities_count: u64,
	free_entities:       [MAX_ENTITIES]Entity_Id,
	events_count:        u64,
	events:              [MAX_ENTITIES]GameEvent,
	modifiers_count:     u64,
	modifiers:           [MAX_MODIFIERS]Modifier,
}

