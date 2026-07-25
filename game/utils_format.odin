package game

import "core:fmt"
import "core:math"

// Static rotating string buffers (no temp allocator, no heap)
@(private = "file")
format_buffers: [UTILS_FORMAT_SLOTS][32]u8
format_slot_idx: int = 0

@(private = "file")
get_format_buffer :: proc() -> []u8 {
	buf := format_buffers[format_slot_idx][:]
	format_slot_idx = (format_slot_idx + 1) % UTILS_FORMAT_SLOTS
	return buf
}

fmt_compact :: proc(v: f64) -> cstring {
	buf := get_format_buffer()
	abs_v := abs(v)

	str: string
	if abs_v < 1000.0 {
		if abs_v == math.floor(abs_v) {
			str = fmt.bprintf(buf, "%.0f", v)
		} else {
			str = fmt.bprintf(buf, "%.1f", v)
		}
	} else if abs_v < 1e6 {
		str = fmt.bprintf(buf, "%.1fK", v / 1e3)
	} else if abs_v < 1e9 {
		str = fmt.bprintf(buf, "%.2fM", v / 1e6)
	} else if abs_v < 1e12 {
		str = fmt.bprintf(buf, "%.2fB", v / 1e9)
	} else if abs_v < 1e15 {
		str = fmt.bprintf(buf, "%.2fT", v / 1e12)
	} else {
		str = fmt.bprintf(buf, "%.2e", v)
	}

	buf[len(str)] = 0
	return cstring(raw_data(buf))
}

fmt_multiplier :: proc(op: Upgrade_Op, magnitude: f32, level: u8) -> cstring {
	buf := get_format_buffer()
	str: string

	if level == 0 {
		str = fmt.bprintf(buf, "Base")
	} else {
		switch op {
		case .Add:
			addend := magnitude * f32(level)
			if addend >= 0 {
				str = fmt.bprintf(buf, "+%.1f", addend)
			} else {
				str = fmt.bprintf(buf, "%.1f", addend)
			}
		case .Mul:
			factor := math.pow(magnitude, f32(level))
			if magnitude < 1.0 {
				discount := (1.0 - factor) * 100.0
				str = fmt.bprintf(buf, "-%.0f%%", discount)
			} else {
				str = fmt.bprintf(buf, "x%.2f", factor)
			}
		}
	}

	buf[len(str)] = 0
	return cstring(raw_data(buf))
}
