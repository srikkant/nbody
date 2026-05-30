package tests

import game "../game"
import "core:testing"
import rl "vendor:raylib"

@(test)
test_game_init_empty :: proc(t: ^testing.T) {
	g := make_test_game()
	defer free_test_game(g)

	testing.expect(t, g != nil, "Game struct must allocate")
	testing.expect_value(t, g.entities_count, 0)
}
