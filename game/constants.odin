/*
This file should only contain compile-time constants.
Everything else should be defined in the game params/theme.
*/
package game

import "core:math"

/*
 * Max frame time (used to limit impact when debugging).
 */
MAX_DT :: 0.05
/*
 * The maximum number of entities in the game. Only matters during the initialization of the game.
 */
MAX_ENTITIES :: 4096
/*
 * The maximum number of modifiers that can be applied to the game.
 */
MAX_MODIFIERS :: 10
/*
 * Number of points to track for the orbit of each entity.
 */
MAX_ORBIT_LENGTH :: 100
/*
 * Minimum angle between orbit points to ensure orbits always close
 */
ORBIT_POINTS_MIN_ANGLE :: (2 * math.PI) / (MAX_ORBIT_LENGTH - 1) // do a -1 so the orbit always closes
/*
 * Size of the position trail behind celestials
 */
POSITION_TRAIL_LENGTH :: 5
/*
 * Subdivisions per trail segment for smoothing
 */
TRAIL_SUBDIVISIONS :: 4
/*
 * Number of ticks between for calculating averages.
 */
AVG_CALC_TICKS :: 10

// ==========================================
// Signatures used by different systems
// ==========================================

EMITTER_SIG: Entity_Signature : {.Emitter, .Position}
RENDER_SIG: Entity_Signature : {.Position, .Radius, .Renderable}
PHYSICS_SIG: Entity_Signature : {.Position, .Velocity, .Mass, .Radius, .Celestial}
ORBIT_SIG: Entity_Signature : {.Orbit}
KE_SCORE_SIG: Entity_Signature : {.Position, .Velocity, .Radius, .Mass, .Life}
ENERGY_SOURCE_SIG: Entity_Signature : {.EnergySource, .Radius}
SHOCKWAVE_SIG: Entity_Signature : {.Position, .Radius, .Life, .Shockwave}

// ==========================================
// UI
// ==========================================

CURSOR_POINTER_SIZE :: 4

// ==========================================
// BACKGROUND & PARALLAX CONSTANTS
// ==========================================

/*
 * Total number of background nebulae generated during initialization.
 */
BG_NEBULA_COUNT :: 4
/*
 * Total number of background stars generated.
 */
BG_STAR_COUNT :: 1600
/*
 * Total number of depth layers used for background rendering to create the 3D parallax field (deep space layers 0-2 and foreground layer 3).
 */
BG_NUM_LAYERS :: 4
/*
 * The half-width horizontal boundary (from -x to +x) defining the random placement zone for stars during initialization.
 */
BG_STAR_SPAWN_BOUNDS_X :: 2000.0
/*
 * The half-height vertical boundary (from -y to +y) defining the random placement zone for stars during initialization.
 */
BG_STAR_SPAWN_BOUNDS_Y :: 1500.0
/*
 * Minimum frequency multiplier for the time-based sinusoidal twinkling/pulsation cycle of background stars.
 */
BG_STAR_BLINK_SPEED_MIN :: 1.0
/*
 * Maximum frequency multiplier for the time-based sinusoidal twinkling/pulsation cycle of background stars.
 */
BG_STAR_BLINK_SPEED_MAX :: 3.5
/*
 * The maximum phase offset (in radians/units) to randomize star twinkle offsets so stars do not pulse in synchronization.
 */
BG_STAR_BLINK_PHASE_MAX :: 6
/*
 * Defines the cumulative star index boundaries in the global array to partition stars into their respective depth layers (e.g. 55% in layer 0, etc.).
 */
BG_STAR_LAYER_INDICES: [BG_NUM_LAYERS]f32 = {
	BG_STAR_COUNT * 55 / 100,
	BG_STAR_COUNT * 80 / 100,
	BG_STAR_COUNT * 90 / 100,
	BG_STAR_COUNT,
}
/*
 * Defines the [base_size, random_range] sizing configuration for stars on a per-layer basis during generation, creating layered star thickness.
 */
BG_STAR_SIZES: [BG_NUM_LAYERS][2]f32 = {{0.8, 0.6}, {1.3, 0.7}, {1.9, 0.9}, {2.6, 1.2}}
/*
 * Divisors used to scale down camera translation to create the parallax depth effect. Higher values (layer 0 = 12) move slower and appear further away.
 */
BG_PARALLAX_LAYER_DEPTHS: [BG_NUM_LAYERS]f32 = {12.0, 5.0, 2.0, 0.8}
/*
 * Scalers determining how much camera zoom affects coordinate offsets in each star layer (deeper layers expand outward slower under zoom).
 */
BG_PARALLAX_LAYER_ZOOM_MULTIPLIERS: [BG_NUM_LAYERS]f32 = {0.05, 0.25, 0.6, 1.0}
/*
 * Scalers determining how much camera zoom enlarges individual stars in each layer (farthest stars don't grow, nearest grow significantly).
 */
BG_PARALLAX_LAYER_SIZE_ZOOM_MULTIPLIERS: [BG_NUM_LAYERS]f32 = {0.0, 0.15, 0.4, 0.8}
/*
 * The specific background depth layer (layer 3) designated to render with the flare texture instead of the standard glow circle texture.
 */
BG_STAR_FLARE_LAYER :: 3
/*
 * The constant minimum brightness baseline (offset) applied to the star twinkling equation, ensuring stars don't fade to pitch black.
 */
BG_STAR_PULSATION_BASE :: 0.4
/*
 * The range of intensity oscillation for star twinkling. Dictates the amplitude of the sine wave modulation of a star's brightness.
 */
BG_STAR_PULSATION_AMPLITUDE :: 0.35
/*
 * Hard minimum floor for a star's rendered size on screen to prevent them from becoming sub-pixel or invisible under extreme zoom.
 */
BG_STAR_SIZE_MIN :: 0.4
/*
 * Hard maximum cap for a star's rendered size on screen to keep nearby/foreground stars from bloating too large under close zoom.
 */
BG_STAR_SIZE_MAX :: 6.0
/*
 * Sizing and opacity clamping bounds per layer used to calculate zoom-dependent fade values, mitigating screen clutter and aliasing.
 */
BG_STAR_LAYER_ALPHA_CLAMPS: [BG_NUM_LAYERS][3]f32 = {
	{1.5, 0.45, 0.7},
	{1.0, 0.55, 0.5},
	{5.0, 0.3, 0.5},
	{0.15, 0.2, 0.5},
}
/*
 * The half-width horizontal boundary defining the random placement zone for nebulae centers during generation.
 */
BG_NEBULA_SPAWN_BOUNDS_X :: 600.0
/*
 * The half-height vertical boundary defining the random placement zone for nebulae centers during generation.
 */
BG_NEBULA_SPAWN_BOUNDS_Y :: 400.0
/*
 * Divisor used to scale down camera translation for the nebulae layer, establishing its fixed position depth (depth = 10).
 */
BG_NEBULA_LAYER_DEPTH :: 10.0
/*
 * Scaler determining how much camera zoom affects coordinate offsets of nebulae (dampens offset expansion so nebulae feel deep).
 */
BG_NEBULA_ZOOM_MULTIPLIER :: 0.08
/*
 * The base scale offset for the slow nebulae expansion/contraction breathing effect over time.
 */
BG_NEBULA_PULSATION_BASE :: 0.9
/*
 * The amplitude of the sine wave modulation regulating nebulae size breathing, causing them to pulse gently.
 */
BG_NEBULA_PULSATION_AMPLITUDE :: 0.1
/*
 * Scaler determining how much camera zoom enlarges or shrinks the radius of the nebulae (keeps them looking broad and distant).
 */
BG_NEBULA_ZOOM_RADIUS_MULTIPLIER :: 0.05
/*
 * Hard lower limit on a nebula's zoom-dependent transparency scale so it never fully disappears when highly zoomed in.
 */
BG_NEBULA_ALPHA_ZOOM_MIN :: 0.3
/*
 * Defines the random [min_radius, max_radius] ranges for each of the background nebulae during random generation.
 */
BG_NEBULA_RADIUS_RANGES: [BG_NUM_LAYERS][2]f32 = {
	{850.0, 1200.0},
	{800.0, 1100.0},
	{850.0, 1200.0},
	{700.0, 1000.0},
}
/*
 * Defines the random [min_frequency, max_frequency] drift/pulsation speed ranges for each nebula during random generation.
 */
BG_NEBULA_DRIFT_SPEED_RANGES: [BG_NUM_LAYERS][2]f32 = {
	{0.3, 0.8},
	{0.4, 0.9},
	{0.2, 0.6},
	{0.5, 1.0},
}


// ==========================================
// VFX RELATED PARAMETERS
// ==========================================

/*
 * Start radius of the shockwave
 */
SHOCKWAVE_RADIUS_START :: 1.0
/*
 * Base minimum duration of the shockwave
 */
SHOCKWAVE_DURATION_BASE_SEC :: 0.5
/*
 * Multiplier applied to the growth rate with energy
 */
SHOCKWAVE_GROWTH_FACTOR :: 1
/*
 * Starting deceleration of shockwaves
 */
SHOCKWAVE_DECEL_START :: 2.2
/*
 * Decay in the growth of shockwaves
 */
SHOCKWAVE_DECEL_DECAY :: 1.95
/*
 * Minimum number of energy fragments
 */
ENERGY_FRAGMENTS_COUNT_BASE :: 3
/*
 * Multiplier applied for deciding number of energy fragments after a collision.
 */
ENERGY_FRAGMENTS_COUNT_SPEED_FACTOR :: 0.3
/*
 * Frequency drift in x
 */
ENERGY_FRAGMENTS_DRIFT_FREQUENCY_X :: 1.5
/*
 * Frequency drift in y
 */
ENERGY_FRAGMENTS_DRIFT_FREQUENCY_Y :: 1.8
/*
 * Amplitude of drift in x
 */
ENERGY_FRAGMENTS_DRIFT_AMPLITUDE_X :: 0.15
/*
 * Amplitude of drift in y
 */
ENERGY_FRAGMENTS_DRIFT_AMPLITUDE_Y :: 0.15
/*
 * Size of the energy fragments
 * @TODO Should this be dynamic?
 */
ENERGY_FRAGMENTS_SIZE :: 2.0


// ==========================================
// CAMERA PARAMETERS
// ==========================================

/*
 * Padding around entities when positioning them inside camera
 */
CAMERA_PADDING :: 200
/*
 * Hard cap for min zoom level
 */
CAMERA_ZOOM_MIN :: 0.01
/*
 * Hard cap for max zoom level
 */
CAMERA_ZOOM_MAX :: 2.0
/*
 * How fast camera zooms in?
 */
CAMERA_ZOOM_IN_INTERPOLATION_DECAY :: 0.6
/*
 * How fast camera zooms out?
 * We typically want zoom out to be way faster than zoom in
 */
CAMERA_ZOOM_OUT_INTERPOLATION_DECAY :: 8.0

