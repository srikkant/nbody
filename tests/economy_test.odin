package tests

import game "../game"
import "core:testing"

@(test)
test_economy_add_and_spend :: proc(t: ^testing.T) {
	g := test_make_game()
	defer free(g)
	g.score.energy = 100
	g.score.lifetime_energy_earned = 500

	game.economy_add_energy(g, 50)
	testing.expect_value(t, g.score.energy, 150)
	testing.expect_value(t, g.score.lifetime_energy_earned, 550)

	// Negative/zero add does nothing
	game.economy_add_energy(g, -20)
	testing.expect_value(t, g.score.energy, 150)
	testing.expect_value(t, g.score.lifetime_energy_earned, 550)

	// Spend happy path
	ok := game.economy_try_spend(g, 40)
	testing.expect(t, ok, "spend should succeed")
	testing.expect_value(t, g.score.energy, 110)
	testing.expect_value(t, g.score.lifetime_energy_earned, 550)

	// Spend fail path (short energy)
	ok = game.economy_try_spend(g, 200)
	testing.expect(t, !ok, "spend should fail when short")
	testing.expect_value(t, g.score.energy, 110) // unchanged
}
