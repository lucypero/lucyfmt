package lucyfmt

import "core:fmt"
import "core:strings"

Parser_State :: struct {
	indent_level:        int,
	multi_comment_depth: int,
	in_raw_string:       bool,
	paren_depth:          int,
	when_detected: bool
}

Scan_Result :: struct {
	leading_close:     bool,
	net_change:       int,
	paren_change:     int,
	leading_close_paren: bool,
}

scan_line :: proc(line: string, state: ^Parser_State) -> Scan_Result {
	result: Scan_Result
	found_first_non_ws := false
	i := 0

	for i < len(line) {
		ch := line[i]
		
		if strings.starts_with(line[i:], "when") {
			state.when_detected = true
		}

		// Inside a raw string — look for closing backtick
		if state.in_raw_string {
			if ch == '`' {
				state.in_raw_string = false
			}
			i += 1
			continue
		}

		// Inside a multi-line comment — look for /* (nest) or */ (unnest)
		if state.multi_comment_depth > 0 {
			if i + 1 < len(line) && ch == '/' && line[i + 1] == '*' {
				state.multi_comment_depth += 1
				i += 2
				continue
			}
			if i + 1 < len(line) && ch == '*' && line[i + 1] == '/' {
				state.multi_comment_depth -= 1
				i += 2
				continue
			}
			i += 1
			continue
		}

		// Single-line comment — skip rest of line
		if i + 1 < len(line) && ch == '/' && line[i + 1] == '/' {
			break
		}

		// Start of multi-line comment
		if i + 1 < len(line) && ch == '/' && line[i + 1] == '*' {
			state.multi_comment_depth += 1
			i += 2
			continue
		}

		// Double-quoted string
		if ch == '"' {
			i += 1
			for i < len(line) {
				if line[i] == '\\' {
					i += 2
					continue
				}
				if line[i] == '"' {
					i += 1
					break
				}
				i += 1
			}
			continue
		}

		// Raw string (backtick)
		if ch == '`' {
			state.in_raw_string = true
			i += 1
			continue
		}

		// Char literal
		if ch == '\'' {
			i += 1
			for i < len(line) {
				if line[i] == '\\' {
					i += 2
					continue
				}
				if line[i] == '\'' {
					i += 1
					break
				}
				i += 1
			}
			continue
		}

	// Braces
	if ch == '{' {
		
		if state.when_detected {
			
			state.when_detected = false
		} else {
			result.net_change += 1
		}
		
		
		i += 1
		continue
	}
	if ch == '}' {
		if !found_first_non_ws && ch != ' ' && ch != '\t' {
			result.leading_close = true
		}
		result.net_change -= 1
		i += 1
		continue
	}

	// Parentheses
	if ch == '(' {
		result.paren_change += 1
		i += 1
		continue
	}
	if ch == ')' {
		if !found_first_non_ws && ch != ' ' && ch != '\t' {
			result.leading_close_paren = true
		}
		result.paren_change -= 1
		i += 1
		continue
	}

		if !found_first_non_ws && ch != ' ' && ch != '\t' {
			found_first_non_ws = true
		}

		i += 1
	}

	return result
}

format_source :: proc(input: string) -> string {
	// Normalize \r\n to \n
	normalized, was_alloc := strings.replace_all(input, "\r\n", "\n")

	lines := strings.split(normalized, "\n")

	state := Parser_State{}
	builder: strings.Builder
	strings.builder_init(&builder, 0, len(input))
	
	previous_line : Scan_Result
	previous_state : Parser_State

	for line, line_idx in lines {
		// Don't add trailing newline for last empty element from split
		if line_idx == len(lines) - 1 && len(line) == 0 {
			break
		}

		stripped := strings.trim_left(line, " \t")

		if len(stripped) == 0 {
			strings.write_byte(&builder, '\n')
			continue
		}

		is_comment := state.multi_comment_depth > 0 || strings.has_prefix(stripped, "//")
		
		result := scan_line(stripped, &state)

		write_indent: int
		if result.leading_close {
			write_indent = max(0, state.indent_level - 1)
		} else {
			write_indent = state.indent_level
		}
		if result.leading_close_paren {
			write_indent = max(0, write_indent + state.paren_depth - 1)
		} else {
			write_indent += state.paren_depth
		}
		
		if strings.starts_with(stripped, "case") {
			write_indent -= 1
		}

		state.indent_level = max(0, state.indent_level + result.net_change)
		state.paren_depth = max(0, state.paren_depth + result.paren_change)
		
		// DNT: Do not touch (inside of multi line strings and multi line comments)
		did_dnt_start : bool = (state.in_raw_string && !previous_state.in_raw_string) ||
			(state.multi_comment_depth > 0 && previous_state.multi_comment_depth <= 0)
			
		was_dnt_previous_line : bool = (previous_state.in_raw_string) || previous_state.multi_comment_depth > 0
		
		// leave the inside of dnt's untouched, even if the dnt ended in current line
		if (!did_dnt_start && (state.in_raw_string || state.multi_comment_depth > 0)) || was_dnt_previous_line {
			strings.write_string(&builder, line)
		} else {
			// add back indentation
			for _ in 0 ..< write_indent {
				strings.write_byte(&builder, '\t')
			}
			
			// write line stripped of whitespace
			strings.write_string(&builder, stripped)
		}
		
		strings.write_byte(&builder, '\n')
		
		previous_state = state
		previous_line = result
	}

	result := strings.to_string(builder)
	output := strings.clone(result)
	strings.builder_destroy(&builder)
	return output
}
