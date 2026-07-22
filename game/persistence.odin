#+build !js

package game

import "core:fmt"
import "core:hash"
import "core:os"
import rl "vendor:raylib"

/*
 * Save/load persistence using a binary format and writes field-by-field.
 * This uses little endian format.
 *
 *   magic   : [4]u8  "NBOD" (SAVE_MAGIC)
 *   version : u32    SAVE_VERSION
 *   length  : u64    payload byte count
 *   crc32   : u64    checksum over payload bytes
 *   payload : persisted Game fields in explicit order
 *
 * If we encounter any version mismatch or validation failure, we reject the full
 * file and start fresh.
 */

Persist_Buffer :: struct {
	buf: []u8,
	pos: int,
	ok:  bool,
}

persist_file_buf: [MAX_SAVE_SIZE]u8
persist_dir_buf: [1024]u8
persist_env_buf: [1024]u8
persist_tmp_path_buf: [1200]u8
persist_final_path_buf: [1200]u8

/*
 * Write primitives
 */

persist_write_u8 :: proc(w: ^Persist_Buffer, v: u8) {
	if !w.ok do return
	if w.pos + 1 > len(w.buf) {
		w.ok = false
		return
	}
	w.buf[w.pos] = v
	w.pos += 1
}

persist_write_u16 :: proc(w: ^Persist_Buffer, v: u16) {
	persist_write_u8(w, u8(v & 0xFF))
	persist_write_u8(w, u8((v >> 8) & 0xFF))
}

persist_write_u32 :: proc(w: ^Persist_Buffer, v: u32) {
	persist_write_u16(w, u16(v & 0xFFFF))
	persist_write_u16(w, u16((v >> 16) & 0xFFFF))
}

persist_write_u64 :: proc(w: ^Persist_Buffer, v: u64) {
	persist_write_u32(w, u32(v & 0xFFFFFFFF))
	persist_write_u32(w, u32((v >> 32) & 0xFFFFFFFF))
}

persist_write_i64 :: proc(w: ^Persist_Buffer, v: i64) {
	persist_write_u64(w, u64(v))
}

persist_write_f32 :: proc(w: ^Persist_Buffer, v: f32) {
	persist_write_u32(w, transmute(u32)v)
}

persist_write_f64 :: proc(w: ^Persist_Buffer, v: f64) {
	persist_write_u64(w, transmute(u64)v)
}

persist_write_bool :: proc(w: ^Persist_Buffer, v: bool) {
	persist_write_u8(w, 1 if v else 0)
}

persist_write_vec2 :: proc(w: ^Persist_Buffer, v: [2]f32) {
	persist_write_f32(w, v.x)
	persist_write_f32(w, v.y)
}

persist_write_color :: proc(w: ^Persist_Buffer, c: rl.Color) {
	persist_write_u8(w, c.r)
	persist_write_u8(w, c.g)
	persist_write_u8(w, c.b)
	persist_write_u8(w, c.a)
}

persist_write_timer :: proc(w: ^Persist_Buffer, t: Timer) {
	persist_write_f32(w, t.curr)
	persist_write_f32(w, t.interval)
	persist_write_bool(w, t.done)
}

persist_write_signature :: proc(w: ^Persist_Buffer, sig: Entity_Signature) {
	bits: u16 = 0
	for c in Component_Type {
		if c in sig do bits |= u16(1) << u32(c)
	}
	persist_write_u16(w, bits)
}

persist_write_emitter :: proc(w: ^Persist_Buffer, em: Component_Emitter) {
	persist_write_f32(w, em.emit_density)
	persist_write_f32(w, em.emit_radius)
	persist_write_vec2(w, em.emit_vel)
	persist_write_u8(w, u8(em.emit_celestial.type))
	persist_write_color(w, em.emit_color)
	persist_write_i64(w, i64(em.max_count))
	persist_write_i64(w, i64(em.current_count))
	persist_write_timer(w, em.timer)
	persist_write_timer(w, em.destroy_timer)
	persist_write_f64(w, em.base_cost)
}

/*
 * Read primitives (little-endian)
 */

persist_read_u8 :: proc(r: ^Persist_Buffer) -> u8 {
	if !r.ok do return 0
	if r.pos + 1 > len(r.buf) {
		r.ok = false
		return 0
	}
	v := r.buf[r.pos]
	r.pos += 1
	return v
}

persist_read_u16 :: proc(r: ^Persist_Buffer) -> u16 {
	lo := u16(persist_read_u8(r))
	hi := u16(persist_read_u8(r))
	return lo | (hi << 8)
}

persist_read_u32 :: proc(r: ^Persist_Buffer) -> u32 {
	lo := u32(persist_read_u16(r))
	hi := u32(persist_read_u16(r))
	return lo | (hi << 16)
}

persist_read_u64 :: proc(r: ^Persist_Buffer) -> u64 {
	lo := u64(persist_read_u32(r))
	hi := u64(persist_read_u32(r))
	return lo | (hi << 32)
}

persist_read_i64 :: proc(r: ^Persist_Buffer) -> i64 {
	return i64(persist_read_u64(r))
}

persist_read_f32 :: proc(r: ^Persist_Buffer) -> f32 {
	return transmute(f32)persist_read_u32(r)
}

persist_read_f64 :: proc(r: ^Persist_Buffer) -> f64 {
	return transmute(f64)persist_read_u64(r)
}

persist_read_bool :: proc(r: ^Persist_Buffer) -> bool {
	return persist_read_u8(r) != 0
}

persist_read_vec2 :: proc(r: ^Persist_Buffer) -> [2]f32 {
	x := persist_read_f32(r)
	y := persist_read_f32(r)
	return {x, y}
}

persist_read_color :: proc(r: ^Persist_Buffer) -> rl.Color {
	cr := persist_read_u8(r)
	cg := persist_read_u8(r)
	cb := persist_read_u8(r)
	ca := persist_read_u8(r)
	return {cr, cg, cb, ca}
}

persist_read_timer :: proc(r: ^Persist_Buffer) -> Timer {
	curr := persist_read_f32(r)
	interval := persist_read_f32(r)
	done := persist_read_bool(r)
	return {curr = curr, interval = interval, done = done}
}

persist_read_signature :: proc(r: ^Persist_Buffer) -> Entity_Signature {
	bits := persist_read_u16(r)
	sig: Entity_Signature
	for c in Component_Type {
		if bits & (u16(1) << u32(c)) != 0 do sig += {c}
	}
	return sig
}

persist_read_celestial_type :: proc(r: ^Persist_Buffer) -> Celestial_Type {
	v := persist_read_u8(r)
	if v > u8(Celestial_Type.Star) {
		r.ok = false
		return .None
	}
	return Celestial_Type(v)
}

persist_read_emitter :: proc(r: ^Persist_Buffer, em: ^Component_Emitter) {
	em.emit_density = persist_read_f32(r)
	em.emit_radius = persist_read_f32(r)
	em.emit_vel = persist_read_vec2(r)
	em.emit_celestial.type = persist_read_celestial_type(r)
	em.emit_color = persist_read_color(r)
	em.max_count = int(persist_read_i64(r))
	em.current_count = int(persist_read_i64(r))
	em.timer = persist_read_timer(r)
	em.destroy_timer = persist_read_timer(r)
	em.base_cost = persist_read_f64(r)
}

persist_write_entity :: proc(w: ^Persist_Buffer, e: #soa^#soa[MAX_ENTITIES]Entity) {
	persist_write_signature(w, e.sig)
	persist_write_f32(w, e.life.created_at)
	persist_write_timer(w, e.life.remaining)
	persist_write_vec2(w, e.pos.current)
	for i in 0 ..< POSITION_TRAIL_LENGTH {
		persist_write_vec2(w, e.pos.trail[i])
	}
	persist_write_i64(w, i64(e.pos.trail_head))
	for i in 0 ..< MAX_ORBIT_LENGTH {
		persist_write_vec2(w, e.orbit.points[i])
	}
	persist_write_i64(w, i64(e.orbit.head))
	persist_write_f32(w, e.orbit.angle)
	persist_write_i64(w, i64(e.orbit.count))
	persist_write_f32(w, e.orbit.max_distance_sq)
	persist_write_vec2(w, e.velocity.current)
	persist_write_vec2(w, e.velocity.acceleration)
	persist_write_f32(w, e.mass)
	persist_write_f32(w, e.radius)
	persist_write_f32(w, e.energy_source.output)
	persist_write_timer(w, e.energy_source.timer)
	persist_write_emitter(w, e.emitter)
	persist_write_u8(w, u8(e.celestial.type))
	persist_write_color(w, e.renderable.color)
	persist_write_f64(w, e.collectible_energy.energy)
	persist_write_f32(w, e.shockwave.growth_rate)
	persist_write_color(w, e.shockwave.color)
}

persist_read_entity :: proc(r: ^Persist_Buffer, e: #soa^#soa[MAX_ENTITIES]Entity) {
	e.sig = persist_read_signature(r)
	e.life.created_at = persist_read_f32(r)
	e.life.remaining = persist_read_timer(r)
	e.pos.current = persist_read_vec2(r)
	for i in 0 ..< POSITION_TRAIL_LENGTH {
		e.pos.trail[i] = persist_read_vec2(r)
	}

	trail_head := persist_read_i64(r)
	if trail_head < 0 || trail_head >= POSITION_TRAIL_LENGTH {
		r.ok = false
		return
	}
	e.pos.trail_head = int(trail_head)

	for i in 0 ..< MAX_ORBIT_LENGTH {
		e.orbit.points[i] = persist_read_vec2(r)
	}
	head := persist_read_i64(r)
	e.orbit.angle = persist_read_f32(r)
	count := persist_read_i64(r)
	e.orbit.max_distance_sq = persist_read_f32(r)
	if head < 0 || head >= MAX_ORBIT_LENGTH || count < 0 || count > MAX_ORBIT_LENGTH {
		r.ok = false
		return
	}
	e.orbit.head = int(head)
	e.orbit.count = int(count)

	e.velocity.current = persist_read_vec2(r)
	e.velocity.acceleration = persist_read_vec2(r)
	e.mass = persist_read_f32(r)
	e.radius = persist_read_f32(r)
	e.energy_source.output = persist_read_f32(r)
	e.energy_source.timer = persist_read_timer(r)
	persist_read_emitter(r, &e.emitter)
	e.celestial.type = persist_read_celestial_type(r)
	e.renderable.color = persist_read_color(r)
	e.collectible_energy.energy = persist_read_f64(r)
	e.shockwave.growth_rate = persist_read_f32(r)
	e.shockwave.color = persist_read_color(r)
}

persist_write_params :: proc(w: ^Persist_Buffer, p: ^Parameters) {
	for t in Celestial_Type {
		c := p.celestials[t]
		persist_write_f32(w, c.density)
		persist_write_f32(w, c.radius)
		persist_write_f32(w, c.launch_cost)
		persist_write_color(w, c.color)
		persist_write_u8(w, u8(c.visual_class))
		persist_write_f32(w, c.quad_multiplier)
		persist_write_f32(w, c.trail_multiplier)
		persist_write_f32(w, c.glow_intensity)
	}

	ph := p.physics
	persist_write_f32(w, ph.gravity_constant)
	persist_write_f32(w, ph.mass_absorb_factor)
	persist_write_f32(w, ph.collision_mass_loss_factor)
	persist_write_f32(w, ph.collision_shatter_threshold_factor)
	persist_write_f32(w, ph.spawn_invincibility_duration_sec)
	persist_write_f32(w, ph.cursor_distance)
	persist_write_f32(w, ph.cursor_distance_squared)
	persist_write_f32(w, ph.world_radius)
	persist_write_f32(w, ph.world_radius_squared)
	persist_write_f32(w, ph.energy_gain_factor)
	persist_write_f32(w, ph.energy_source_gain_factor)
	persist_write_f32(w, ph.energy_refund_factor)

	persist_write_f32(w, p.slingshot.launch_power)
	persist_write_f32(w, p.slingshot.preview_duration)
}

persist_read_params :: proc(r: ^Persist_Buffer, p: ^Parameters) {
	for t in Celestial_Type {
		c := &p.celestials[t]
		c.density = persist_read_f32(r)
		c.radius = persist_read_f32(r)
		c.launch_cost = persist_read_f32(r)
		c.color = persist_read_color(r)
		class := persist_read_u8(r)
		if class > u8(Celestial_Class.Anchor) {
			r.ok = false
			return
		}
		c.visual_class = Celestial_Class(class)
		c.quad_multiplier = persist_read_f32(r)
		c.trail_multiplier = persist_read_f32(r)
		c.glow_intensity = persist_read_f32(r)
	}

	ph := &p.physics
	ph.gravity_constant = persist_read_f32(r)
	ph.mass_absorb_factor = persist_read_f32(r)
	ph.collision_mass_loss_factor = persist_read_f32(r)
	ph.collision_shatter_threshold_factor = persist_read_f32(r)
	ph.spawn_invincibility_duration_sec = persist_read_f32(r)
	ph.cursor_distance = persist_read_f32(r)
	ph.cursor_distance_squared = persist_read_f32(r)
	ph.world_radius = persist_read_f32(r)
	ph.world_radius_squared = persist_read_f32(r)
	ph.energy_gain_factor = persist_read_f32(r)
	ph.energy_source_gain_factor = persist_read_f32(r)
	ph.energy_refund_factor = persist_read_f32(r)

	p.slingshot.launch_power = persist_read_f32(r)
	p.slingshot.preview_duration = persist_read_f32(r)
}

persist_write_payload :: proc(w: ^Persist_Buffer, g: ^Game) {
	persist_write_f32(w, g.elapsed)

	persist_write_f64(w, g.score.energy)
	persist_write_i64(w, i64(g.score.energy_rate_ticker))
	persist_write_i64(w, i64(g.score.total_objects))
	for i in 0 ..< AVG_CALC_TICKS {
		persist_write_f64(w, g.score.energy_gains[i])
		persist_write_f64(w, g.score.energy_losses[i])
	}

	for i in Timer_BuiltIn {
		persist_write_timer(w, g.timers[i])
	}

	persist_write_bool(w, g.help.launch_done)

	persist_write_f32(w, g.camera.rl_cam.zoom)
	persist_write_vec2(w, g.camera.rl_cam.target)

	avail: u16 = 0
	for t in Celestial_Type {
		if t in g.slingshot.available_objects do avail |= u16(1) << u32(t)
	}
	persist_write_u16(w, avail)

	switch &out in g.slingshot.output {
	case Slingshot_Output_Emitter:
		persist_write_u8(w, SAVE_OUTPUT_TAG_EMITTER)
		persist_write_emitter(w, out.emitter)
	case Slingshot_Output_Celestial:
		persist_write_u8(w, SAVE_OUTPUT_TAG_CELESTIAL)
		persist_write_u8(w, u8(out.celestial.type))
	case:
		// Union is nil-able; nothing selected yet.
		persist_write_u8(w, SAVE_OUTPUT_TAG_NONE)
	}
	persist_write_f32(w, g.slingshot.launch_power)

	persist_write_params(w, &g.params)

	persist_write_u64(w, u64(g.entities_count))
	for i in 0 ..< g.entities_count {
		e := &g.entities[i]
		persist_write_entity(w, e)
	}

	persist_write_u64(w, u64(g.free_entities_count))
	for i in 0 ..< g.free_entities_count {
		persist_write_u64(w, u64(g.free_entities[i]))
	}

	persist_write_u64(w, u64(g.modifiers_count))
	for i in 0 ..< g.modifiers_count {
		m := g.modifiers[i]
		persist_write_bool(w, m.active)
		persist_write_f64(w, m.started_at)
		persist_write_f64(w, m.duration)
	}
}

persist_read_payload :: proc(r: ^Persist_Buffer, g: ^Game) {
	g.elapsed = persist_read_f32(r)

	g.score.energy = persist_read_f64(r)
	g.score.energy_rate_ticker = int(persist_read_i64(r))
	g.score.total_objects = int(persist_read_i64(r))
	for i in 0 ..< AVG_CALC_TICKS {
		g.score.energy_gains[i] = persist_read_f64(r)
		g.score.energy_losses[i] = persist_read_f64(r)
	}

	for i in Timer_BuiltIn {
		g.timers[i] = persist_read_timer(r)
	}

	g.help.launch_done = persist_read_bool(r)

	g.camera.rl_cam.zoom = persist_read_f32(r)
	g.camera.rl_cam.target = persist_read_vec2(r)

	avail := persist_read_u16(r)
	available: bit_set[Celestial_Type]
	for t in Celestial_Type {
		if avail & (u16(1) << u32(t)) != 0 do available += {t}
	}
	g.slingshot.available_objects = available

	tag := persist_read_u8(r)
	switch tag {
	case SAVE_OUTPUT_TAG_NONE:
		g.slingshot.output = nil
	case SAVE_OUTPUT_TAG_EMITTER:
		out: Slingshot_Output_Emitter
		persist_read_emitter(r, &out.emitter)
		g.slingshot.output = out
	case SAVE_OUTPUT_TAG_CELESTIAL:
		out: Slingshot_Output_Celestial
		out.celestial.type = persist_read_celestial_type(r)
		g.slingshot.output = out
	case:
		r.ok = false
		return
	}
	g.slingshot.launch_power = persist_read_f32(r)

	persist_read_params(r, &g.params)

	entities_count := persist_read_u64(r)
	if entities_count > MAX_ENTITIES {
		r.ok = false
		return
	}
	g.entities_count = entities_count
	for i in 0 ..< entities_count {
		e := &g.entities[i]
		persist_read_entity(r, e)
	}

	free_count := persist_read_u64(r)
	if free_count > MAX_ENTITIES {
		r.ok = false
		return
	}
	g.free_entities_count = free_count
	for i in 0 ..< free_count {
		id := persist_read_u64(r)
		if id >= MAX_ENTITIES {
			r.ok = false
			return
		}
		g.free_entities[i] = Entity_Id(id)
	}

	modifiers_count := persist_read_u64(r)
	if modifiers_count > MAX_MODIFIERS {
		r.ok = false
		return
	}
	g.modifiers_count = modifiers_count
	for i in 0 ..< modifiers_count {
		m := &g.modifiers[i]
		m.active = persist_read_bool(r)
		m.started_at = persist_read_f64(r)
		m.duration = persist_read_f64(r)
	}
}

/*
 * Serializes the full game state into buf (header + payload).
 * Buffer-based so tests stay off disk. Returns bytes written and success.
 */
persist_serialize :: proc(g: ^Game, buf: []u8) -> (n: int, ok: bool) {
	if len(buf) < SAVE_HEADER_SIZE do return 0, false

	w := Persist_Buffer {
		buf = buf,
		pos = SAVE_HEADER_SIZE,
		ok  = true,
	}

	persist_write_payload(&w, g)
	if !w.ok do return 0, false

	payload := buf[SAVE_HEADER_SIZE:w.pos]

	hw := Persist_Buffer {
		buf = buf,
		ok  = true,
	}
	magic := SAVE_MAGIC
	for i in 0 ..< len(magic) {
		persist_write_u8(&hw, magic[i])
	}
	persist_write_u32(&hw, SAVE_VERSION)
	persist_write_u64(&hw, u64(len(payload)))
	persist_write_u64(&hw, u64(hash.crc32(payload)))

	return w.pos, true
}

/*
 * Validates header + checksum and populates the persisted fields of g.
 * Resets transient state: status = .Paused (the user resumes manually),
 * slingshot back to Inactive defaults, events and scratch buffers cleared.
 * Returns false on any validation failure.
 */
persist_deserialize :: proc(g: ^Game, buf: []u8) -> bool {
	if len(buf) < SAVE_HEADER_SIZE do return false

	r := Persist_Buffer {
		buf = buf,
		ok  = true,
	}
	magic := SAVE_MAGIC
	for i in 0 ..< len(magic) {
		if persist_read_u8(&r) != magic[i] do return false
	}
	if persist_read_u32(&r) != SAVE_VERSION do return false
	length := persist_read_u64(&r)
	crc := persist_read_u64(&r)
	if !r.ok do return false

	if length != u64(len(buf) - SAVE_HEADER_SIZE) do return false
	payload := buf[SAVE_HEADER_SIZE:]
	if u64(hash.crc32(payload)) != crc do return false

	r.pos = SAVE_HEADER_SIZE
	persist_read_payload(&r, g)
	if !r.ok do return false

	persist_reset_transient(g)
	return true
}

/*
 * Resets everything that is not persisted to sane post-load defaults.
 */
persist_reset_transient :: proc(g: ^Game) {
	// Loaded runs start paused; the user resumes from the pause state.
	g.status = .Paused
	g.events_count = 0

	g.slingshot.status = .Inactive
	g.slingshot.can_launch = false
	g.slingshot.start_pos = {}
	g.slingshot.end_pos = {}
	g.slingshot.shimmer_time = 0
	g.slingshot.preview = 1
	g.slingshot.preview_points = {}
	g.slingshot.preview_times = {}
	g.slingshot.preview_count = 0
	g.slingshot.snap = {}
	g.slingshot.ring_flashes = {}
	g.slingshot.obj_color = {}
	g.slingshot.obj_radius = 0

	// sys_camera does not run while paused, so seed the base offset here;
	// zoom and target come from the save.
	g.camera.rl_cam.offset = rl.Vector2{g.screenw / 2, g.screenh / 2}
	g.camera.shake_dir = {}
	g.camera.shake_intensity = 0

	for i in 0 ..< MAX_ENTITIES {
		g.delete_entities[i] = false
		g.mass_delta[i] = 0
	}
}

/*
 * OS user data dir for saves and creates the directory if missing.
 * Returns "" on failure (saving disabled for the session).
 * This probably needs to be handled better.
 */
persist_save_dir :: proc() -> string {
	dir: string

	when ODIN_OS == .Windows {
		base, err := os.lookup_env_buf(persist_env_buf[:], "APPDATA")
		if err != nil || len(base) == 0 {
			return ""
		}
		dir = fmt.bprintf(persist_dir_buf[:], "%s/%s", base, SAVE_DIR_NAME)
	} else when ODIN_OS == .Darwin {
		home, err := os.lookup_env_buf(persist_env_buf[:], "HOME")
		if err != nil || len(home) == 0 {
			return ""
		}
		dir = fmt.bprintf(
			persist_dir_buf[:],
			"%s/Library/Application Support/%s",
			home,
			SAVE_DIR_NAME,
		)
	} else {
		xdg, xdg_err := os.lookup_env_buf(persist_env_buf[:], "XDG_DATA_HOME")
		if xdg_err == nil && len(xdg) > 0 {
			dir = fmt.bprintf(persist_dir_buf[:], "%s/%s", xdg, SAVE_DIR_NAME)
		} else {
			home, err := os.lookup_env_buf(persist_env_buf[:], "HOME")
			if err != nil || len(home) == 0 {
				return ""
			}
			dir = fmt.bprintf(persist_dir_buf[:], "%s/.local/share/%s", home, SAVE_DIR_NAME)
		}
	}

	if !persist_make_dir_all(dir) {
		return ""
	}
	return dir
}

persist_make_dir_all :: proc(path: string) -> bool {
	for i in 1 ..< len(path) {
		if path[i] != '/' do continue
		prefix := path[:i]
		// Skip bare drive letters on Windows (e.g. "C:").
		if len(prefix) == 2 && prefix[1] == ':' do continue
		if !os.exists(prefix) {
			if os.make_directory(prefix) != nil do return false
		}
	}
	if !os.exists(path) {
		if os.make_directory(path) != nil do return false
	}
	return true
}

/*
 * Serializes into the static buffer and atomically writes save.bin
 * (tmp file + rename). Returns false on any failure; the game continues.
 */
persist_save_to_disk :: proc(g: ^Game) -> bool {
	dir := persist_save_dir()
	if dir == "" do return false

	n, ok := persist_serialize(g, persist_file_buf[:])
	if !ok {
		return false
	}

	tmp_path := fmt.bprintf(persist_tmp_path_buf[:], "%s/%s.tmp", dir, SAVE_FILENAME)
	final_path := fmt.bprintf(persist_final_path_buf[:], "%s/%s", dir, SAVE_FILENAME)

	if os.write_entire_file(tmp_path, persist_file_buf[:n]) != nil {
		return false
	}
	if os.rename(tmp_path, final_path) != nil {
		return false
	}
	return true
}

/*
 * Reads save.bin if present and deserializes it.
 * Missing file or invalid content = false; the caller starts fresh.
 */
persist_load_from_disk :: proc(g: ^Game) -> bool {
	dir := persist_save_dir()
	if dir == "" do return false

	path := fmt.bprintf(persist_final_path_buf[:], "%s/%s", dir, SAVE_FILENAME)
	if !os.exists(path) do return false

	f, open_err := os.open(path)
	if open_err != nil do return false
	defer os.close(f)

	total := 0
	for total < len(persist_file_buf) {
		n, err := os.read(f, persist_file_buf[total:])
		total += n
		if err != nil {
			if err == .EOF do break
			return false
		}
		if n == 0 do break
	}

	return persist_deserialize(g, persist_file_buf[:total])
}

/*
 * Autosave tick. Called once per frame from the Playing branch of game_run.
 */
persist_maybe_autosave :: proc(g: ^Game) {
	if g.timers[.Autosave].done {
		persist_save_to_disk(g)
	}
}
