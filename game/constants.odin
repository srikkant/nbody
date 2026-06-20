/*
This file should only contain compile-time constants.
Everything else should be defined in the game params/theme.
*/
package game

import "core:math"

// Number of nebula in the background.
BG_NEBULA_COUNT :: 4
// Number of stars in the background layer.
BG_STAR_COUNT :: 1600
// The maximum number of entities in the game. Only matters during the initialization of the game.
MAX_ENTITIES :: 4096
// The maximum number of modifiers that can be applied to the game.
MAX_MODIFIERS :: 10
// Number of points to track for the orbit of each entity.
MAX_ORBIT_LENGTH :: 100
// Max particles during bursts (explosions etc.)
MAX_PARTICLE_BURST_COUNT :: 120
// Size of the position trail behind celestials
POSITION_TRAIL_LENGTH :: 5
// Number of ticks between for calculating averages.
AVG_CALC_TICKS :: 10
// Minimum angle between orbit points to ensure orbits always close
ORBIT_POINTS_MIN_ANGLE :: (2 * math.PI) / (MAX_ORBIT_LENGTH - 1) // do a -1 so the orbit always closes
// Subdivisions per trail segment for smoothing
TRAIL_SUBDIVISIONS :: 4
MAX_GRID_WELLS :: 16


/*
Signatures used by different systems
*/

EMITTER_SIG: Entity_Signature : {.Emitter, .Position}
RENDER_SIG: Entity_Signature : {.Position, .Radius, .Renderable}
PHYSICS_SIG: Entity_Signature : {.Position, .Velocity, .Mass, .Radius, .Celestial}
ORBIT_SIG: Entity_Signature : {.Orbit}
KE_SCORE_SIG: Entity_Signature : {.Position, .Velocity, .Radius, .Mass, .Life}
ENERGY_SOURCE_SIG: Entity_Signature : {.EnergySource, .Radius}
SHOCKWAVE_SIG: Entity_Signature : {.Position, .Radius, .Life, .Shockwave}
PARTICLE_BURST_SIG: Entity_Signature : {.Position, .Life, .ParticleBurst}

/*
 * Max frame time (used to limit impact when debugging).
 */
MAX_DT :: 0.05


// ==========================================
// BACKGROUND & PARALLAX CONSTANTS
// ==========================================

/*
 * Number of layers in the star field.
 */
BG_NUM_LAYERS :: 4
/*
 * Range for star position along x axis
 */
BG_STAR_SPAWN_BOUNDS_X :: 2000.0
/*
 * Range for star position along y axis
 */
BG_STAR_SPAWN_BOUNDS_Y :: 1500.0
/*
 * Min blink speed of generated stars
 */
BG_STAR_BLINK_SPEED_MIN :: 1.0
/*
 * Max blink speed of generated stars
 */
BG_STAR_BLINK_SPEED_MAX :: 3.5
/*
 * Max blink phase  
 */
BG_STAR_BLINK_PHASE_MAX :: 6
/*
 * Index of stars for each layer in the star field.
 */
BG_STAR_LAYER_INDICES: [BG_NUM_LAYERS]f32 = {
	BG_STAR_COUNT * 55 / 100,
	BG_STAR_COUNT * 80 / 100,
	BG_STAR_COUNT * 90 / 100,
	BG_STAR_COUNT,
}
/*
 * Background star size configurations [layer][base, range]
 */
BG_STAR_SIZES: [BG_NUM_LAYERS][2]f32 = {{0.8, 0.6}, {1.3, 0.7}, {1.9, 0.9}, {2.6, 1.2}}
/*
 * Width of the torus used for parallax
 */
BG_PARALLAX_TORUS_WIDTH :: 4000.0
/*
 * Height of the torus used for parallax
 */
BG_PARALLAX_TORUS_HEIGHT :: 3000.0
/*
 * Depths of each parallax layer in the starfield
 */
BG_PARALLAX_LAYER_DEPTHS: [BG_NUM_LAYERS]f32 = {12.0, 5.0, 2.0, 0.8}
/*
 *
 */
BG_PARALLAX_LAYER_ZOOM_MULTIPLIERS: [BG_NUM_LAYERS]f32 = {0.05, 0.25, 0.6, 1.0}
/*
 *
 */
BG_PARALLAX_LAYER_SIZE_ZOOM_MULTIPLIERS: [BG_NUM_LAYERS]f32 = {0.0, 0.15, 0.4, 0.8}
/*
 * Layer at which flares show up
 */
BG_STAR_FLARE_LAYER :: 3
/*
 *
 */
BG_STAR_PULSATION_BASE :: 0.4
/*
 *
 */
BG_STAR_PULSATION_AMPLITUDE :: 0.35
/*
 *
 */
BG_STAR_SIZE_MIN :: 0.4
/*
 *
 */
BG_STAR_SIZE_MAX :: 6.0
/*
 *
 */
BG_STAR_FLARE_THRESHOLD :: 2.2
/*
 *
 */
BG_STAR_FLARE_SIZE_MULTIPLIER :: 2.5
/*
 *
 */
BG_STAR_FLARE_ALPHA_MULTIPLIER :: 0.35
/*
 *
 */
BG_STAR_LAYER_ALPHA_CLAMPS: [BG_NUM_LAYERS][3]f32 = {
	{1.5, 0.45, 0.7},
	{1.0, 0.55, 0.5},
	{5.0, 0.3, 0.5},
	{0.15, 0.2, 0.5},
}
/*
 * Range for star position along x axis
 */
BG_NEBULA_SPAWN_BOUNDS_X :: 600.0
/*
 * Range for star position along y axis
 */
BG_NEBULA_SPAWN_BOUNDS_Y :: 400.0
/*
 * 
 */
BG_NEBULA_LAYER_DEPTH :: 10.0
/*
 *
 */
BG_NEBULA_ZOOM_MULTIPLIER :: 0.08
/*
 *
 */
BG_NEBULA_PULSATION_BASE :: 0.9
/*
 *
 */
BG_NEBULA_PULSATION_AMPLITUDE :: 0.1
/*
 *
 */
BG_NEBULA_ZOOM_RADIUS_MULTIPLIER :: 0.05
/*
 *
 */
BG_NEBULA_ALPHA_ZOOM_NUMERATOR :: 1.2
/*
 *
 */
BG_NEBULA_ALPHA_ZOOM_MIN :: 0.3
/*
 *
 */
BG_NEBULA_ALPHA_ZOOM_MAX :: 1.0
/*
 * Range of the radii of the nebulae generated
 */
BG_NEBULA_RADIUS_RANGES: [BG_NUM_LAYERS][2]f32 = {
	{850.0, 1200.0},
	{800.0, 1100.0},
	{850.0, 1200.0},
	{700.0, 1000.0},
}
/*
 * Range of the drift speed of the nebulae generated
 */
BG_NEBULA_DRIFT_SPEED_RANGES: [BG_NUM_LAYERS][2]f32 = {
	{0.3, 0.8},
	{0.4, 0.9},
	{0.2, 0.6},
	{0.5, 1.0},
}

