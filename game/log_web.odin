#+build js

package game

import "base:runtime"
import "core:fmt"

log_init :: proc() -> runtime.Logger {
	return runtime.Logger{
		procedure = web_logger_proc,
		data = nil,
		lowest_level = .Debug,
		options = {},
	}
}

log_shutdown :: proc() {}

web_logger_proc :: proc(
	data: rawptr,
	level: runtime.Logger_Level,
	text: string,
	options: runtime.Logger_Options,
	location := #caller_location,
) {
	level_str := "INFO"
	switch level {
	case .Debug:   level_str = "DEBUG"
	case .Info:    level_str = "INFO"
	case .Warning: level_str = "WARNING"
	case .Error:   level_str = "ERROR"
	case .Fatal:   level_str = "FATAL"
	}

	fmt.printf("[%s] (%s:%d) %s\n", level_str, location.file_path, location.line, text)
}
