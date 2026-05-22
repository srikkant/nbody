package main

import rl "vendor:raylib"

get_celestial_color :: proc(g: ^Game, ctype: CelestialType) -> rl.Color {
	return g.params.celestials[ctype].color
}

get_celestial_params :: proc(g: ^Game, ctype: CelestialType) -> Game_CelestialParams {
	return g.params.celestials[ctype]
}

get_celestial_display_name :: proc(ctype: CelestialType) -> cstring {
	switch ctype {
	case .None:
		return "none"
	case .Asteroid:
		return "asteroid"
	case .Moonlet:
		return "moonlet"
	case .DwarfPlanet:
		return "dwarf planet"
	case .SubEarth:
		return "sub-earth"
	case .SuperEarth:
		return "super earth"
	case .MegaEarth:
		return "mega earth"
	case .MiniNeptune:
		return "mini neptune"
	case .SubNeptune:
		return "sub-neptune"
	case .SuperNeptune:
		return "super neptune"
	case .GiantPlanet:
		return "giant planet"
	case .SuperJupiter:
		return "super jupiter"
	case .Star:
		return "star"
	}
	return "Unknown"
}
