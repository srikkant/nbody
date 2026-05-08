package main

import "core:math"
// TODO: Make these configurable
RENDER_WIDTH :: 1920
RENDER_HEIGHT :: 1080

MAX_ENTITIES :: 4096
MAX_COMPONENTS :: 10
MAX_MODIFIERS :: 10
MAX_TRAIL_LENGTH :: 20

TRAIL_MIN_ANGLE :: (2 * math.PI) / (MAX_TRAIL_LENGTH - 1) // do a -1 so the orbit always closes

// Game physics and system constants
WORLD_RADUIS_SQ :: 1000 * 1000
SOFTENING :: 2.0

// Signatures used by different systems
STAR_SIG: Signature : {.Star}
RENDER_SIG: Signature : {.Position, .Size, .Renderable}
PHYSICS_SIG: Signature : {.Position, .Velocity, .Size}
TRAIL_SIG: Signature : {.PositionTrail}
KE_SCORE_SIG: Signature : {.Position, .Velocity, .Size, .Life}
ENERGY_SOURCE_SIG: Signature : {.EnergySource, .Size}
