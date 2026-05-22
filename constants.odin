/*
This file should only contain compile-time constants.
Everything else should be defined in the game params/theme.
*/
package main

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

/*
Signatures used by different systems
*/

EMITTER_SIG: Signature : {.Emitter, .Position}
RENDER_SIG: Signature : {.Position, .Radius, .Renderable}
PHYSICS_SIG: Signature : {.Position, .Velocity, .Mass, .Radius, .Celestial}
ORBIT_SIG: Signature : {.Orbit}
KE_SCORE_SIG: Signature : {.Position, .Velocity, .Radius, .Mass, .Life}
ENERGY_SOURCE_SIG: Signature : {.EnergySource, .Radius}
SHOCKWAVE_SIG: Signature : {.Position, .Radius, .Life, .Shockwave}
PARTICLE_BURST_SIG: Signature : {.Position, .Life, .ParticleBurst}
