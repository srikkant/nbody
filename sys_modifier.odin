package main

import rl "vendor:raylib"

sys_modifier :: proc(g: ^Game) {

	// reset sligshot, mass etc to default values
	g.slingshot.launch_power = 0
	g.slingshot.preview = 1 // TODO: This should be zero in the final game and an unlockable upgrade for the user

	for i in 0 ..< MAX_MODIFIERS {
		m := &g.modifiers[i]
		if !m.active do continue

		// If the modifier has a duration, check if it has expired
		if m.duration != 0 && rl.GetTime() - m.started_at > m.duration {
			g.modifiers[i] = {}
			continue
		}

		g.slingshot.launch_power += g.slingshot.launch_power * m.slingshot_power
		g.slingshot.preview += g.slingshot.preview * m.slingshot_preview
	}
}
