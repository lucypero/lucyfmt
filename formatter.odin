package lucyfmt

import "core:strings"

Parser_State :: struct {
	indent_level:        int,
	multi_comment_depth: int,
	in_raw_string:       bool,
}

Scan_Result :: struct {
	leading_close: bool,
	net_change:    int,
}

scan_line :: proc(line: string, state: ^Parser_State) -> Scan_Result {
	result: Scan_Result
	found_first_non_ws := false
	i := 0

	for i < len(line) {
		ch := line[i]

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
			result.net_change += 1
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
	defer if was_alloc do delete(normalized)

	lines := strings.split(normalized, "\n")
	defer delete(lines)

	state := Parser_State{}
	builder: strings.Builder
	strings.builder_init(&builder, 0, len(input))

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

		result := scan_line(stripped, &state)

		write_indent: int
		if result.leading_close {
			write_indent = max(0, state.indent_level - 1)
		} else {
			write_indent = state.indent_level
		}

		for _ in 0 ..< write_indent {
			strings.write_byte(&builder, '\t')
		}
		strings.write_string(&builder, stripped)
		strings.write_byte(&builder, '\n')

		state.indent_level = max(0, state.indent_level + result.net_change)
	}

	result := strings.to_string(builder)
	output := strings.clone(result)
	strings.builder_destroy(&builder)
	return output
}
