package game

import rl "vendor:raylib"

get_celestial_color :: proc(g: ^Game, ctype: Celestial_Type) -> rl.Color {
	return g.params.celestials[ctype].color
}

get_celestial_params :: proc(g: ^Game, ctype: Celestial_Type) -> Parameters_Celestial {
	return g.params.celestials[ctype]
}

get_celestial_display_name :: proc(ctype: Celestial_Type) -> cstring {
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

get_inspected_entity :: proc(g: ^Game) -> (Entity_Id, bool) {
	closest_id: Entity_Id = 0
	closest_dist: f32 = 120.0 // screen-space lock threshold in pixels
	found := false

	mouse_screen := rl.GetMousePosition()

	for idx in 0 ..< g.entities_count {
		e := &g.entities[idx]
		if e.sig == {} do continue
		if !(.Celestial in e.sig) do continue
		if e.celestial.type == .Star do continue // skip star

		screen_pos := rl.GetWorldToScreen2D(e.pos.current, g.camera.rl_cam)
		dist := rl.Vector2Distance(mouse_screen, screen_pos)

		if dist < closest_dist {
			closest_dist = dist
			closest_id = Entity_Id(idx)
			found = true
		}
	}

	return closest_id, found
}
