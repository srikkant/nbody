package game

sys_modifier :: proc(g: ^Game) {
	for i in 0 ..< MAX_MODIFIERS {
		m := &g.modifiers[i]
		if !m.active do continue
	}
}
