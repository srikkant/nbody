package main

import rl "vendor:raylib"

sys_emitters :: proc(g: ^Game) {
	dt := rl.GetFrameTime()

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if EMITTER_SIG <= e.sig {
			done := utils_math_update_timer(&e.emitter.timer, dt)

			if done && g.energy >= e.emitter.base_cost {
				push_event(
					g,
					Game_Event_ObjectSpawn {
						pos = e.pos.current,
						velocity = e.emitter.emit_vel,
						density = e.emitter.emit_density,
						radius = e.emitter.emit_radius,
						show_trail = true,
						celestial = e.emitter.emit_celestial,
					},
				)

				e.emitter.current_count += 1
				if e.emitter.current_count == e.emitter.max_count {
					push_event(g, Game_Event_ObjectDestroyed{Entity(i)})
				}
			}
		}
	}
}
