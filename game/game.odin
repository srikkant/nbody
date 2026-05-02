package game

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Game_Object :: struct {
	mass:  f32,
	r:     f32,
	pos:   rl.Vector2,
	vel:   rl.Vector2,
	color: rl.Color,
}

Game :: struct {
	view:                  rl.Rectangle,
	slingshot_mass:        f32,
	slingshot_radius:      f32,
	slingshot_active:      bool,
	slingshot_origin_pos:  rl.Vector2,
	slingshot_release_pos: rl.Vector2,
	objs:                  [dynamic]Game_Object,
}

STAR_MASS :: 100000000
STAR_RADIUS :: 64
COMET_MASS :: 5
COMET_RADIUS :: 4

VIRTUAL_SCREEN_SIZE :: 1000
SLINGSHOT_STIFFNESS :: 2
G :: 1

COLORS := []rl.Color{rl.RED, rl.GREEN, rl.BLUE, rl.YELLOW, rl.ORANGE, rl.PURPLE, rl.MAGENTA}

game_mouse_pos :: proc(g: ^Game) -> rl.Vector2 {
	relx := f32(rl.GetMouseX()) - g.view.x
	rely := f32(rl.GetMouseY()) - g.view.y

	// use height or width as both are same.
	mx := relx * VIRTUAL_SCREEN_SIZE / g.view.width
	my := rely * VIRTUAL_SCREEN_SIZE / g.view.height

	return rl.Vector2{mx, my}
}

game_input_update :: proc(g: ^Game) {
	if (rl.IsMouseButtonPressed(.LEFT)) {
		g.slingshot_active = true
		g.slingshot_origin_pos = game_mouse_pos(g)
		g.slingshot_release_pos = game_mouse_pos(g)
		g.slingshot_mass = COMET_MASS
		g.slingshot_radius = COMET_RADIUS
	}

	if g.slingshot_active {
		if rl.IsMouseButtonDown(.LEFT) {
			g.slingshot_release_pos = game_mouse_pos(g)
		}

		if (rl.IsMouseButtonReleased(.LEFT)) {
			g.slingshot_active = false
			vel := (g.slingshot_origin_pos - g.slingshot_release_pos) * SLINGSHOT_STIFFNESS

			append(
				&g.objs,
				Game_Object {
					mass = g.slingshot_mass,
					r = g.slingshot_radius,
					pos = g.slingshot_origin_pos,
					vel = vel,
					color = COLORS[int(rand.uint32()) % len(COLORS)],
				},
			)
		}
	}

	if (rl.IsKeyPressed(.C)) {
		g.slingshot_active = false
	}
}

game_update :: proc(g: ^Game) {
	game_input_update(g)
	game_update_objects(g)
}

game_update_objects :: proc(g: ^Game) {
	if (len(g.objs) == 0) do return

	dt := rl.GetFrameTime()
	softening := f32(5.0) // for preventing division by zero

	accels := make([]rl.Vector2, len(g.objs))
	defer delete(accels)

	for i in 0 ..< len(g.objs) {
		total_accel := rl.Vector2(0)

		for j in 0 ..< len(g.objs) {
			if i == j do continue

			// Vector from i to j
			diff := g.objs[j].pos - g.objs[i].pos
			r2 := diff.x * diff.x + diff.y * diff.y
			r3 := (r2 + softening) * math.sqrt(r2 + softening)

			// a = G * m_j * diff / r^3
			strength := G * g.objs[j].mass
			total_accel.x += (strength * diff.x) / r3
			total_accel.y += (strength * diff.y) / r3
		}

		accels[i] = total_accel
	}

	for i in 0 ..< len(g.objs) {
		g.objs[i].vel += accels[i] * dt
		g.objs[i].pos += g.objs[i].vel * dt

		// if out of bounds, remove
		if g.objs[i].pos.x < 0 ||
		   g.objs[i].pos.x > VIRTUAL_SCREEN_SIZE ||
		   g.objs[i].pos.y < 0 ||
		   g.objs[i].pos.y > VIRTUAL_SCREEN_SIZE {
			unordered_remove(&g.objs, i)
			continue
		}

		if (i > 0) {
			// if the object is inside the star, remove it
			if (g.objs[i].pos.x < g.objs[0].pos.x + g.objs[0].r &&
				   g.objs[i].pos.y < g.objs[0].pos.y + g.objs[0].r &&
				   g.objs[i].pos.x > g.objs[0].pos.x - g.objs[0].r &&
				   g.objs[i].pos.y > g.objs[0].pos.y - g.objs[0].r) {
				unordered_remove(&g.objs, i)
				continue
			}
		}
	}
}

game_draw_slingshot :: proc(g: ^Game) {
	if !g.slingshot_active do return

	rl.DrawCircle(
		i32(g.slingshot_release_pos.x),
		i32(g.slingshot_release_pos.y),
		g.slingshot_radius,
		rl.GRAY,
	)
	rl.DrawCircle(
		i32(g.slingshot_origin_pos.x),
		i32(g.slingshot_origin_pos.y),
		g.slingshot_radius,
		rl.WHITE,
	)
	rl.DrawLineEx(g.slingshot_origin_pos, g.slingshot_release_pos, 1, rl.GRAY)
}

game_draw_objects :: proc(g: ^Game) {
	for i in 0 ..< len(g.objs) {
		obj := &g.objs[i]
		rl.DrawCircle(i32(obj.pos.x), i32(obj.pos.y), obj.r, obj.color)
	}
}

game_draw :: proc(g: ^Game) {
	game_draw_objects(g)
	game_draw_slingshot(g)
}


init :: proc() {
	rl.SetTraceLogLevel(rl.TraceLogLevel.WARNING)
	rl.SetConfigFlags({.MSAA_4X_HINT, .WINDOW_HIGHDPI, .WINDOW_UNDECORATED, .WINDOW_RESIZABLE})
	rl.InitWindow(1440, 960, "cellular automata")
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	g := Game{}

	rtex := rl.LoadRenderTexture(VIRTUAL_SCREEN_SIZE, VIRTUAL_SCREEN_SIZE)

	// Add a star
	star := Game_Object {
		mass  = STAR_MASS,
		r     = STAR_RADIUS,
		pos   = rl.Vector2{VIRTUAL_SCREEN_SIZE / 2, VIRTUAL_SCREEN_SIZE / 2},
		color = rl.WHITE,
	}
	append(&g.objs, star)

	for !rl.WindowShouldClose() {
		ww := f32(rl.GetScreenWidth())
		wh := f32(rl.GetScreenHeight())
		size := math.min(wh, ww)
		offset_x := (ww - size) / 2
		offset_y := (wh - size) / 2
		g.view = rl.Rectangle{offset_x, offset_y, size, size}

		game_update(&g)

		rl.BeginTextureMode(rtex)
		rl.ClearBackground(rl.BLACK)

		game_draw(&g)

		rl.EndTextureMode()

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawTexturePro(
			rtex.texture,
			rl.Rectangle{0, 0, f32(rtex.texture.width), f32(-rtex.texture.height)},
			g.view,
			rl.Vector2(0),
			0,
			rl.WHITE,
		)

		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}
}
