package main

sys_emitters :: proc(g: ^Game) {
	dt := frame_time()

	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		if EMITTER_SIG <= e.sig {
			done := utils_math_update_timer(&e.emitter.timer, dt)
			destroy := utils_math_update_timer(&e.emitter.destroy_timer, dt)

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
						renderable = RenderableComponent{color = e.emitter.emit_color},
					},
				)


				e.emitter.current_count += 1
				if e.emitter.current_count == e.emitter.max_count {
					destroy = true
				}
			}

			if destroy {
				push_event(g, Game_Event_ObjectDestroyed{Entity(i)})
			}
		}
	}
}
