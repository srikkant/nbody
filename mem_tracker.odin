package main

import "core:fmt"
import "core:mem"

init_memory_tracker :: proc() -> ^mem.Tracking_Allocator {
	track := new(mem.Tracking_Allocator)
	mem.tracking_allocator_init(track, context.allocator)
	return track
}

free_memory_tracker :: proc(track: ^mem.Tracking_Allocator) {
	if len(track.allocation_map) > 0 {
		fmt.printf("=== %v Memory Leaks Detected ===\n", len(track.allocation_map))
		for _, entry in track.allocation_map {
			fmt.printf("- %v bytes allocated at %v\n", entry.size, entry.location)
		}
	}

	if len(track.bad_free_array) > 0 {
		fmt.printf("=== %v Bad Frees Detected ===\n", len(track.bad_free_array))
		for entry in track.bad_free_array {
			fmt.printf("- Bad free at %v\n", entry.location)
		}
	}

	fmt.printf("\nTotal Memory Allocated: %v bytes\n", track.total_memory_allocated)
	fmt.printf("Peak Memory Usage:      %v bytes\n", track.peak_memory_allocated)

	mem.tracking_allocator_destroy(track)
}
