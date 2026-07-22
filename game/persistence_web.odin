#+build js

package game

/*
 * No-op persistence stubs for the WASM build.
 * Save/load is native only; a WASM backend (IndexedDB/localStorage via
 * emscripten) is deferred. Keeps the call sites in game.odin tag-free.
 */

persist_serialize :: proc(g: ^Game, buf: []u8) -> (n: int, ok: bool) {
	return 0, false
}

persist_deserialize :: proc(g: ^Game, buf: []u8) -> bool {
	return false
}

persist_save_to_disk :: proc(g: ^Game) -> bool {
	return false
}

persist_load_from_disk :: proc(g: ^Game) -> bool {
	return false
}

persist_save_dir :: proc() -> string {
	return ""
}

persist_maybe_autosave :: proc(g: ^Game) {}
