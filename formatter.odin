package lucyfmt

// import "core:fmt"
import "core:strings"
import "core:container/queue"

IndentType :: enum {
	Normal,
	When
}

Parser_State :: struct {
	indent_level:        int,
	multi_comment_depth: int,
	in_raw_string:       bool,
	paren_depth:          int,
	ident_stack: queue.Queue(IndentType)
}

Scan_Result :: struct {
	leading_close:     bool,
	// change in indentation
	net_change:       int,
	paren_change:     int,
	leading_close_paren: bool,
	when_detected: bool
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
		
		if strings.starts_with(line[i:], "when") {
			result.when_detected = true
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
			if result.when_detected {
				queue.push_front(&state.ident_stack, IndentType.When)
			} else {
				queue.push_front(&state.ident_stack, IndentType.Normal)
				result.net_change += 1
			}

			i += 1
			continue
		}
		if ch == '}' {
			indent_type := queue.pop_front(&state.ident_stack)
			if indent_type != .When {
				result.net_change -= 1
			}
			
			if !found_first_non_ws && ch != ' ' && ch != '\t' && indent_type != .When {
				result.leading_close = true
			}
			
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

// Returns true if it is safe to append " {" to the end of prev_line, i.e. the
// line does not end inside / with a comment and does not already end with a brace.
can_append_brace :: proc(prev_line: string) -> bool {
	s := strings.trim_space(prev_line)
	if len(s) == 0 {
		return false
	}
	if strings.starts_with(s, "//") || strings.starts_with(s, "/*") {
		return false
	}
	if strings.ends_with(s, "*/") || strings.ends_with(s, "{") {
		return false
	}

	// Reject if a comment opens somewhere on the line (outside string/char/raw).
	i := 0
	in_str, in_char, in_raw: bool
	for i < len(s) {
		ch := s[i]
		if in_raw {
			if ch == '`' {
				in_raw = false
			}
			i += 1
			continue
		}
		if in_str {
			if ch == '\\' {
				i += 2
				continue
			}
			if ch == '"' {
				in_str = false
			}
			i += 1
			continue
		}
		if in_char {
			if ch == '\\' {
				i += 2
				continue
			}
			if ch == '\'' {
				in_char = false
			}
			i += 1
			continue
		}
		if ch == '"' {
			in_str = true
			i += 1
			continue
		}
		if ch == '\'' {
			in_char = true
			i += 1
			continue
		}
		if ch == '`' {
			in_raw = true
			i += 1
			continue
		}
		if i + 1 < len(s) && ch == '/' && (s[i + 1] == '/' || s[i + 1] == '*') {
			return false
		}
		i += 1
	}

	return true
}

// Pull a lone opening brace (optionally followed by a line comment) up onto the
// previous non-empty line, for every brace-opening construct. Intervening blank
// lines are dropped. Braces inside raw strings / multi-line comments are left
// untouched, and the merge is skipped when the target line ends in a comment.
cuddle_braces :: proc(lines: []string) -> []string {
	out := make([dynamic]string)

	state := Parser_State{}
	queue.init(&state.ident_stack)

	for line in lines {
		in_dnt := state.in_raw_string || state.multi_comment_depth > 0
		stripped := strings.trim_space(line)

		attached := false
		if !in_dnt && len(stripped) > 0 && stripped[0] == '{' {
			rest := strings.trim_space(stripped[1:])
			is_lone := len(rest) == 0 || strings.starts_with(rest, "//")
			if is_lone {
				last := len(out) - 1
				for last >= 0 && len(strings.trim_space(out[last])) == 0 {
					last -= 1
				}
				if last >= 0 && can_append_brace(out[last]) {
					merged, _ := strings.concatenate({strings.trim_right(out[last], " \t"), " {"})
					if len(rest) > 0 {
						merged, _ = strings.concatenate({merged, " ", rest})
					}
					out[last] = merged
					for len(out) > last + 1 {
						pop(&out)
					}
					attached = true
				}
			}
		}

		if !attached {
			append(&out, line)
		}

		scan_line(stripped, &state)
	}

	return out[:]
}

format_source :: proc(input: string) -> string {
	// Normalize \r\n to \n
	normalized, _ := strings.replace_all(input, "\r\n", "\n")

	lines := cuddle_braces(strings.split(normalized, "\n"))

	state := Parser_State{}
	queue.init(&state.ident_stack)
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

		result : Scan_Result = scan_line(stripped, &state)

		// DNT: Do not touch (inside of multi line strings and multi line comments)
		did_dnt_start : bool = (state.in_raw_string && !previous_state.in_raw_string) ||
		(state.multi_comment_depth > 0 && previous_state.multi_comment_depth <= 0)

		was_dnt_previous_line : bool = (previous_state.in_raw_string) || previous_state.multi_comment_depth > 0

		// leave the inside of dnt's untouched, even if the dnt ended in current line
		if (!did_dnt_start && (state.in_raw_string || state.multi_comment_depth > 0)) || was_dnt_previous_line {
			// Leave the line as is.
			strings.write_string(&builder, line)
		} else { // Add indentation as appropriate
			
			write_indent: int
			hit_leading : int
			
			if result.leading_close {
				write_indent = max(0, state.indent_level - 1)
				hit_leading += 1
			} else {
				write_indent = state.indent_level
			}
			
			if result.leading_close_paren {
				write_indent = max(0, write_indent + state.paren_depth - 1)
				hit_leading += 1
			} else {
				write_indent += state.paren_depth
			}
			
			// Prevent under-indent if there are close parens and close brace on the same line
			if hit_leading >= 2 {
				write_indent += 1
			}

			if strings.starts_with(stripped, "case") {
				write_indent -= 1
			}
			
			// add back indentation
			for _ in 0 ..< write_indent {
				strings.write_byte(&builder, '\t')
			}

			// write line stripped of whitespace
			strings.write_string(&builder, stripped)
		}

		state.indent_level = max(0, state.indent_level + min(result.net_change, 1))
		state.paren_depth = max(0, state.paren_depth + min(result.paren_change, 1))
		
		// Do not over-indent if there were parens and brace opens on the same line
		if result.net_change > 0 && result.paren_change > 0 {
			state.paren_depth -= 1
		}
		
		strings.write_byte(&builder, '\n')

		previous_state = state
		previous_line = result
	}

	result := strings.to_string(builder)
	output := strings.clone(result)
	return output
}
