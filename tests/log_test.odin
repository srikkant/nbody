package tests

import game "../game"
import "core:testing"
import "core:os"
import "core:log"
import "core:strings"
import "core:fmt"

@(test)
test_logger_writes_to_file :: proc(t: ^testing.T) {
	// Call log_init
	context.logger = game.log_init()
	defer game.log_shutdown()

	testing.expect(t, game.log_initialized, "logger should be initialized")
	testing.expect(t, game.log_file_path != "", "log file path should not be empty")

	// Call log
	log.warn("NBODY_TEST_LOG_MESSAGE_WARNING")

	// Verify that the file exists and has the message
	data, err := os.read_entire_file(game.log_file_path, context.temp_allocator)
	testing.expect(t, err == nil, "should read log file")

	content := string(data)
	testing.expect(t, strings.contains(content, "NBODY_TEST_LOG_MESSAGE_WARNING"), "log should contain message")
	testing.expect(t, strings.contains(content, "[WARNING]"), "log should contain level string")
}

@(test)
test_logger_cleanup_limits_files :: proc(t: ^testing.T) {
	dir := game.persist_save_dir()
	if dir == "" do return

	// Create 10 dummy log files
	for i in 0..<10 {
		dummy_path := fmt.tprintf("%s/nbody_99999999_0000%02d.log", dir, i)
		f, err := os.open(dummy_path, {.Write, .Create, .Trunc})
		if err == nil {
			os.write_string(f, "dummy")
			os.close(f)
		}
	}

	// Trigger cleanup
	game.log_cleanup_old_files(dir)

	// Verify only 4 or fewer dummy logs remain (since current limit keeps 4 of them during cleanup)
	fi, err := os.read_directory_by_path(dir, -1, context.temp_allocator)
	testing.expect(t, err == nil, "should read dir")

	dummy_count := 0
	for f in fi {
		if strings.has_prefix(f.name, "nbody_99999999_") && strings.has_suffix(f.name, ".log") {
			dummy_count += 1
			os.remove(f.fullpath) // clean up dummy files
		}
	}

	testing.expect(t, dummy_count <= 4, "should clean up oldest dummy logs")
}
