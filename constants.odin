package main

// TODO: Make these configurable
RENDER_WIDTH :: 1920
RENDER_HEIGHT :: 1080

MAX_ENTITIES :: 4096
MAX_COMPONENTS :: 10

// World out of bounds
WORLD_RADUIS_SQ :: 1000 * 1000

// Game physics and system constants
G :: 1
SLINGSHOT_STIFFNESS :: 2
STAR_MASS :: 100000
STAR_RADIUS :: 16
COMET_MASS :: 10000
COMET_RADIUS :: 4

// Signatures used by different systems
STAR_SIG: Signature : {.Star}
RENDER_SIG: Signature : {.Position, .Size, .Renderable}
PHYSICS_SIG: Signature : {.Position, .Velocity, .Size}
