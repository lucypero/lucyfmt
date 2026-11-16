package lucyfmt

import "core:strings"

format_source :: proc(input: string) -> string {
	sb_out := strings.builder_make_len_cap(0, len(input))
	t := Tokenizer {input, 0}

	is_start_of_line := true
	
	tokens := make([dynamic]Token, 0, 20, context.temp_allocator)
	pending_tokens := make([dynamic]Token, 0, 20, context.temp_allocator)

	// at each bracket Open, it stores at which indentation level it appeared
	indentation_stack := make([dynamic]int, 0, 20, context.temp_allocator)
	line_indent := 0
	
	for {
		tok := scan(&t)
		append(&tokens, tok)
		if tok.kind == .EOF do break
	}

	outer: for tok, i in tokens {

		if is_start_of_line {
			// skip whitespace at start of line
			if tok.kind == .Whitespace do continue outer
		}
		
		if is_start_of_line && tok.kind != .NewLine {
			
			// count leading closers on this line (look ahead; don't pop yet)
			// closer_count : int = 0
			// for j := i; j < len(tokens); j += 1 {
			// 	token_kind := tokens[j].kind
			// 	if token_kind == .Whitespace do continue
			// 	if !is_closer(token_kind) do break
			// 	closer_count += 1
			// }

			line_indent = len(indentation_stack) > 0 ? indentation_stack[len(indentation_stack) - 1] + 1 : 0
			// if closer_count > 0 do line_indent -= 1
			if is_closer(tok.kind) do line_indent -= 1
			
			indentation_level_for_this_line := line_indent
			
			// if it's a `case` line, it gets -1 indentation
			if is_keyword_case(tok) do indentation_level_for_this_line = max(0, indentation_level_for_this_line - 1)
			
			// inserting indentation (tabs)
			for _ in 0..<indentation_level_for_this_line do strings.write_byte(&sb_out, '\t')
			
			is_start_of_line = false
		}
		
		// Writing back the contents
		if tok.kind == .Whitespace {
			append(&pending_tokens, tok)
			continue
		}

		switch {
		case is_closer(tok.kind): if len(indentation_stack) > 0 do pop(&indentation_stack)
		case is_opener(tok.kind): append(&indentation_stack, line_indent)		
		}
		
		if tok.kind == .NewLine {
			is_start_of_line = true
		} else {
			for pt in pending_tokens {
				strings.write_string(&sb_out, pt.contents)
			}
		}
		
		clear(&pending_tokens)
		strings.write_string(&sb_out, tok.contents)
	}

	return strings.to_string(sb_out)
}

is_keyword_case :: proc(tok: Token) -> bool {
	return tok.kind == .Word && tok.contents == "case"
}

is_closer :: proc(tok: TokenType) -> bool {
	#partial switch tok {
	case .CloseParens, .CloseBrace, .CloseSquareBracket: return true
	case: return false
	}
}

is_opener :: proc(tok: TokenType) -> bool {
	#partial switch tok {
	case .OpenParens, .OpenBrace, .OpenSquareBracket: return true
	case: return false
	}
}
