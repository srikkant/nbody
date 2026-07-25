package game

import "core:log"

modifier_find :: proc(g: ^Game, kind: Modifier_Kind) -> (index: u64, found: bool) {
	for i in u64(0) ..< g.modifiers_count {
		if g.modifiers[i].kind == kind {
			return i, true
		}
	}
	return 0, false
}

modifier_add :: proc(g: ^Game, kind: Modifier_Kind) -> bool {
	p := g.params.modifiers[kind]
	idx, found := modifier_find(g, kind)
	if found {
		m := &g.modifiers[idx]
		if m.permanent {
			log.warn("Cannot refresh permanent modifier")
			return false
		}
		math_reset_timer(&m.timer, p.duration)
		return true
	}

	if g.modifiers_count >= MAX_MODIFIERS {
		log.warn("Cannot add modifier: maximum capacity reached")
		return false
	}

	is_perm := (p.duration == 0.0)
	g.modifiers[g.modifiers_count] = Modifier {
		kind      = kind,
		permanent = is_perm,
		timer     = math_make_timer(p.duration),
	}
	g.modifiers_count += 1
	return true
}
