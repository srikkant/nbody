package main

sys_automation :: proc(g: ^Game) {
	if g.paused do return
	dt := frame_time(g)

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if EMITTER_SIG <= e.sig {
			utils_math_update_timer(&e.emitter.timer, dt)
			utils_math_update_timer(&e.emitter.destroy_timer, dt)

			max_count_reached := false

			if e.emitter.timer.done && g.energy >= e.emitter.base_cost {
				push_event(
					g,
					Game_Event_ObjectSpawn {
						pos = e.pos.current,
						velocity = e.emitter.emit_vel,
						density = e.emitter.emit_density,
						radius = e.emitter.emit_radius,
						show_orbit = true,
						celestial = e.emitter.emit_celestial,
						renderable = RenderableComponent{color = e.emitter.emit_color},
					},
				)

				e.emitter.current_count += 1
				if e.emitter.current_count == e.emitter.max_count {
					max_count_reached = true
				}
			}

			if e.emitter.destroy_timer.done || max_count_reached {
				push_event(g, Game_Event_ObjectDestroyed{Entity(i)})
			}
		}
	}
}
