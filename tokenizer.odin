package lucyfmt

import "core:strings"
import "core:fmt"

TokenType :: enum { Word, OpenParens, CloseParens, OpenBrace, CloseBrace, NewLine, EOF, Whitespace, Other, SingleLineComment}

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

peek_ahead_is :: proc(t: ^Tokenizer, look_ahead_by: int, char_is: u8) -> bool {
	ind_to_look := t.pos + look_ahead_by
	return ind_to_look < len(t.src) && t.src[ind_to_look] == char_is
}

scan :: proc(t: ^Tokenizer) -> Token {
	for {
		if t.pos >= len(t.src) do break
		
		start_pos := t.pos
		current_char := peek(t)
		next_token := classify_next_token(t)
		
		switch next_token {
		case .OpenParens, .CloseParens, .OpenBrace, .CloseBrace, .NewLine:
			t.pos += 1
		case .Word:
			for t.pos < len(t.src) && is_alphanumeric(peek(t)) do t.pos +=1
		case .SingleLineComment:
			for t.pos < len(t.src) && peek(t) != '\n' do t.pos +=1
		case .Whitespace:
			for t.pos < len(t.src) && is_whitespace(peek(t)) do t.pos +=1
		case .Other:
			for t.pos < len(t.src) && classify_next_token(t) == .Other do t.pos += 1
		case .EOF:
		}

		return {next_token, t.src[start_pos:t.pos]}
	}

	return Token {.EOF, ""}
}

classify_next_token :: proc(t: ^Tokenizer) -> TokenType {
	character := peek(t)
	if kind, ok := get_single_char_token(character); ok do return kind
	if is_whitespace(character) do return .Whitespace
	if character == '/' && peek_ahead_is(t, 1, '/') do return .SingleLineComment
	if is_letter(character) do return .Word
	return .Other
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
