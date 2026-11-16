package lucyfmt

import "core:strings"

format_source :: proc(input: string) -> string {
	// TODO: figure out how to deal with \r in a better way later.
	input_real, _ := strings.remove_all(input, "\r", context.temp_allocator)
	sb_out := strings.builder_make_len_cap(0, len(input_real))
	
	// at each bracket Open, it stores at which indentation level it appeared
	indentation_stack := make([dynamic]int, 0, 20, context.temp_allocator)
	line_indent := 0

	tokens := tokenize(input_real)
	
	for tok, i in tokens {
		is_start_of_line := i == 0 || tokens[i - 1].kind == .NewLine 

		if is_start_of_line && tok.kind != .NewLine {
			line_indent = len(indentation_stack) > 0 ? indentation_stack[len(indentation_stack) - 1] + 1 : 0
			if is_closer(tok.kind) do line_indent -= 1
			indentation_level_for_this_line := line_indent
			if is_keyword_case(tok) do indentation_level_for_this_line = max(0, indentation_level_for_this_line - 1)
			for _ in 0..<indentation_level_for_this_line do strings.write_byte(&sb_out, '\t')
		}
		
		if !is_start_of_line && tok.whitespace_before && tok.kind != .NewLine do strings.write_byte(&sb_out, ' ')
		strings.write_string(&sb_out, tok.contents)
		
		switch {
		case is_closer(tok.kind): if len(indentation_stack) > 0 do pop(&indentation_stack)
		case is_opener(tok.kind): append(&indentation_stack, line_indent)		
		}
	}

	return strings.to_string(sb_out)
}

tokenize :: proc(input_str: string) -> []Token {
	
	tokens := make([dynamic]Token, 0, 256, context.temp_allocator)
	t := Tokenizer {input_str, 0}
	
	for {
		tok := scan(&t)
		if tok.kind == .EOF do break
		append(&tokens, tok)
	}

	return tokens[:]
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
