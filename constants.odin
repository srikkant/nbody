package main

import "core:math"
// TODO: Make these configurable
RENDER_WIDTH :: 1920
RENDER_HEIGHT :: 1080

MAX_ENTITIES :: 8192
MAX_COMPONENTS :: 10
MAX_MODIFIERS :: 10
MAX_TRAIL_LENGTH :: 100

RATE_CALC_TICKS :: 10
SPAWN_INVINCIBLE_DURATION :: 1 // seconds

TRAIL_MIN_ANGLE :: (2 * math.PI) / (MAX_TRAIL_LENGTH - 1) // do a -1 so the orbit always closes

// Game physics and system constants
WORLD_RADIUS_SQ :: 1000 * 1000
SOFTENING :: 2.0
MAX_DT :: 0.05

// Signatures used by different systems
EMITTER_SIG: Signature : {.Emitter, .Position}
RENDER_SIG: Signature : {.Position, .Radius, .Renderable}
PHYSICS_SIG: Signature : {.Position, .Velocity, .Mass, .Radius, .Celestial}
TRAIL_SIG: Signature : {.PositionTrail}
KE_SCORE_SIG: Signature : {.Position, .Velocity, .Radius, .Mass, .Life}
ENERGY_SOURCE_SIG: Signature : {.EnergySource, .Radius}
