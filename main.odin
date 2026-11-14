package lucyfmt

import "core:strings"
import "core:fmt"

format_source :: proc(input: string) -> string {
	sb_out := strings.builder_make()
	t := Tokenizer {input, 0}

	for {
		tok := scan(&t)
		if tok.kind == .EOF do break
		fmt.sbprintf(&sb_out, "%v\n", tok)
	}

	return strings.to_string(sb_out)
}

TokenType :: enum { Word, OpenParens, CloseParens, OpenBrace, CloseBrace, NewLine, EOF, Other}

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
	return is_letter(character) || is_single_char_token
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
