#+build !js

package game

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"

log_file_path_buf: [1200]u8
log_file_path: string
log_initialized := false

log_init :: proc() -> runtime.Logger {
	if log_initialized {
		return runtime.Logger {
			procedure = game_logger_proc,
			data = nil,
			lowest_level = .Debug,
			options = {},
		}
	}

	dir := persist_save_dir()
	if dir == "" do return context.logger

	log_cleanup_old_files(dir)

	t := time.now()
	year, month, day := time.date(t)
	hour, min, sec := time.clock_from_time(t)

	log_file_path = fmt.bprintf(
		log_file_path_buf[:],
		"%s/nbody_%04d%02d%02d_%02d%02d%02d.log",
		dir,
		year,
		int(month),
		day,
		hour,
		min,
		sec,
	)

	// Test if we can write to the log file, create it empty.
	f, err := os.open(log_file_path, {.Write, .Create, .Trunc})
	if err != nil {
		log_file_path = "" // disable logging if file creation fails
		return context.logger
	}
	os.close(f)

	log_initialized = true

	return runtime.Logger {
		procedure = game_logger_proc,
		data = nil,
		lowest_level = .Debug,
		options = {},
	}
}

log_shutdown :: proc() {
	log_initialized = false
	log_file_path = ""
}

log_cleanup_old_files :: proc(dir: string) {
	fi, err := os.read_directory_by_path(dir, -1, context.temp_allocator)
	if err != nil do return

	log_files: [dynamic]os.File_Info
	log_files.allocator = context.temp_allocator

	for f in fi {
		if f.type != .Regular do continue
		if strings.has_prefix(f.name, "nbody_") && strings.has_suffix(f.name, ".log") {
			append(&log_files, f)
		}
	}

	slice.sort_by(log_files[:], proc(i, j: os.File_Info) -> bool {
		return i.name < j.name
	})

	if len(log_files) > 4 {
		for i in 0 ..< len(log_files) - 4 {
			os.remove(log_files[i].fullpath)
		}
	}
}

game_logger_proc :: proc(
	data: rawptr,
	level: runtime.Logger_Level,
	text: string,
	options: runtime.Logger_Options,
	location := #caller_location,
) {
	if log_file_path == "" do return

	t := time.now()
	year, month, day := time.date(t)
	hour, min, sec := time.clock_from_time(t)

	level_str := "INFO"
	switch level {
	case .Debug:
		level_str = "DEBUG"
	case .Info:
		level_str = "INFO"
	case .Warning:
		level_str = "WARNING"
	case .Error:
		level_str = "ERROR"
	case .Fatal:
		level_str = "FATAL"
	}

	log_buf: [2048]u8
	log_line := fmt.bprintf(
		log_buf[:],
		"[%04d-%02d-%02d %02d:%02d:%02d] [%s] (%s:%d) %s\n",
		year,
		int(month),
		day,
		hour,
		min,
		sec,
		level_str,
		location.file_path,
		location.line,
		text,
	)

	f, err := os.open(log_file_path, {.Write, .Append})
	if err == nil {
		os.write_string(f, log_line)
		os.close(f)
	}
}
