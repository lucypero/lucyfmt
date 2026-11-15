package lucyfmt

import "core:strings"
import "core:fmt"

TokenType :: enum { Word, OpenParens, CloseParens, OpenBrace, CloseBrace, NewLine, EOF, Whitespace, Other, Comment}

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
