package main

import "core:math"

// TODO: Make these configurable
RENDER_WIDTH :: 1920
RENDER_HEIGHT :: 1080

BG_STAR_COUNT :: 300

MAX_ENTITIES :: 4096
MAX_MODIFIERS :: 10
MAX_ORBIT_LENGTH :: 100
MAX_PARTICLE_BURST_COUNT :: 120

POSITION_TRAIL_LENGTH :: 5
RATE_CALC_TICKS :: 10
SPAWN_INVINCIBLE_DURATION :: 1 // seconds

ENERGY_FRAGMENT_SIZE :: 4
ORBIT_POINTS_MIN_ANGLE :: (2 * math.PI) / (MAX_ORBIT_LENGTH - 1) // do a -1 so the orbit always closes

// Game physics and system constants
WORLD_RADIUS_SQ :: 1000 * 1000
SOFTENING :: 2.0
MAX_DT :: 0.05

// Signatures used by different systems
EMITTER_SIG: Signature : {.Emitter, .Position}
RENDER_SIG: Signature : {.Position, .Radius, .Renderable}
PHYSICS_SIG: Signature : {.Position, .Velocity, .Mass, .Radius, .Celestial}
ORBIT_SIG: Signature : {.Orbit}
KE_SCORE_SIG: Signature : {.Position, .Velocity, .Radius, .Mass, .Life}
ENERGY_SOURCE_SIG: Signature : {.EnergySource, .Radius}
SHOCKWAVE_SIG: Signature : {.Position, .Radius, .Life, .Shockwave}
PARTICLE_BURST_SIG: Signature : {.Position, .Life, .ParticleBurst}
