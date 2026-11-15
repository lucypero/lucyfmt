package lucyfmt

import "core:strings"
import "core:fmt"

format_source :: proc(input: string) -> string {
	sb_out := strings.builder_make_len_cap(0, len(input))
	t := Tokenizer {input, 0}

	indentation_pending := false
	current_indentation_level := 0

	tokens := make([dynamic]Token, 0, 20, context.temp_allocator)
	pending_tokens := make([dynamic]Token, 0, 20, context.temp_allocator)
	
	for {
		tok := scan(&t)
		append(&tokens, tok)
		if tok.kind == .EOF do break
	}

	for tok in tokens {

		if indentation_pending {
			// skip whitespace at start of line
			for tok.kind == .Whitespace do continue
		}
		
		#partial switch tok.kind {
		case .CloseParens, .CloseBrace: current_indentation_level -= 1
		}
		
		if indentation_pending && tok.kind != .NewLine {
			// inserting indentation (tabs)
			for i in 0..<current_indentation_level {
				strings.write_byte(&sb_out, '\t')
			}

			indentation_pending = false
		}
		
		// Writing back the contents

		if tok.kind == .Whitespace {
			append(&pending_tokens, tok)
			continue
		}

		// Preparing for future tokens
		#partial switch tok.kind {
		case .OpenParens, .OpenBrace: current_indentation_level += 1
		// case .CloseParens, .CloseBrace: current_indentation_level -= 1
		case .NewLine: 
			indentation_pending = true
		}

		// Taking care of pending tokens
		if tok.kind != .NewLine {
			// Write pending tokens (not a newline so it's not trailing whitespace)
			for pt in pending_tokens {
				strings.write_string(&sb_out, pt.contents)
			}
		}
		
		clear(&pending_tokens)
		strings.write_string(&sb_out, tok.contents)
	}

	// add newline at the end of the file
	// if !indentation_pending {
	// 	strings.write_byte(&sb_out, '\n')
	// }
	
	return strings.to_string(sb_out)
}
