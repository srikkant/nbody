package main

import rl "vendor:raylib"

get_celestial_color :: proc(g: ^Game, ctype: CelestialType) -> rl.Color {
	return g.params.celestials[ctype].color
}

get_celestial_params :: proc(g: ^Game, ctype: CelestialType) -> Game_CelestialParams {
	return g.params.celestials[ctype]
}
