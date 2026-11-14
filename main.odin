package lucyfmt

import "core:strings"
import "core:fmt"

format_source :: proc(input: string) -> string {
	sb_out := strings.builder_make_len_cap(0, len(input))
	t := Tokenizer {input, 0}

	indentation_pending := false
	current_indentation_level := 0

	pending_tokens := make([dynamic]Token, 0, 20)
	defer delete(pending_tokens)
	
	for {
		tok := scan(&t)
		if tok.kind == .EOF do break

		if indentation_pending {
			// skip whitespace at start of line
			for tok.kind == .Whitespace do tok = scan(&t)
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
	if !indentation_pending {
		strings.write_byte(&sb_out, '\n')
	}
	return strings.to_string(sb_out)
}

TokenType :: enum { Word, OpenParens, CloseParens, OpenBrace, CloseBrace, NewLine, EOF, Whitespace, Other}

Token :: struct {
	kind: TokenType,
	contents: string
}

Tokenizer :: struct {
	src: string,
	pos: int
}

read :: proc(t: ^Tokenizer) -> byte {
	t.pos += 1
	return t.src[t.pos-1]
}

peek :: proc(t: ^Tokenizer) -> byte {
	return t.src[t.pos]
}

scan :: proc(t: ^Tokenizer) -> Token {
	for {
		if t.pos >= len(t.src) do break
		
		start_pos := t.pos
		current_char := peek(t)

		// Scanning single character tokens
		if kind, ok := get_single_char_token(current_char); ok {
			t.pos += 1
			return Token {kind, t.src[start_pos:t.pos]}
		}

		// Scanning word
		if is_whitespace(current_char) {
			for t.pos < len(t.src) && is_whitespace(peek(t)) do t.pos +=1
			return Token {.Whitespace, t.src[start_pos:t.pos]}
		}

		// Scanning word
		if is_letter(current_char) {
			for t.pos < len(t.src) && is_alphanumeric(peek(t)) do t.pos +=1
			return Token {.Word, t.src[start_pos:t.pos]}
		}

		// Constructing Other token
		for t.pos < len(t.src) && !starts_token(peek(t)) do t.pos += 1
		return Token {.Other, t.src[start_pos:t.pos]}
	}

	return Token {.EOF, ""}
}

starts_token :: proc(character: u8) -> bool {
	_, is_single_char_token := get_single_char_token(character)
	return is_letter(character) || is_single_char_token || is_whitespace(character)
}

is_alphanumeric :: proc(character: u8) -> bool {
	switch character {
	case 'a'..='z', 'A'..='Z', '0'..='9', '_': return true
	case: return false
	}
}

is_letter :: proc(character: u8) -> bool {
	switch character {
	case 'a'..='z', 'A'..='Z': return true
	case: return false
	}
}

get_single_char_token :: proc(character: u8) -> (TokenType, bool) {
	switch character {
	case '(': return .OpenParens, true
	case ')': return .CloseParens, true
	case '{': return .OpenBrace, true
	case '}': return .CloseBrace, true
	case '\n': return .NewLine, true
	case: return .Other, false
	}
}

@(private) _ascii_space := [256]bool{'\t' = true, '\n' = false, '\v' = true, '\f' = true, '\r' = true, ' ' = true}

// does not count \n (newline) (newline is not considered whitespace)
is_whitespace :: proc(character: u8) -> bool {
	return _ascii_space[character]
}
