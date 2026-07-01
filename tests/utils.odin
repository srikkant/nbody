package tests

import game "../game"

test_game_setup :: proc(g: ^game.Game) {
	g := new(game.Game)
	game.params_init(g)
	game.theme_init(g)
}

test_game_free :: proc(g: ^game.Game) {
	free(g)
}

