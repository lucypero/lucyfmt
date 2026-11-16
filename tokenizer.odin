package lucyfmt

import "core:strings"

TokenType :: enum { Word, OpenParens, CloseParens, OpenBrace, CloseBrace, OpenSquareBracket, CloseSquareBracket, NewLine, EOF, Other, SingleLineComment, MultiLineComment, StringQuote, StringBacktick, Character}

Token :: struct {
	kind: TokenType,
	contents: string,
	whitespace_before: bool
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

peek_is :: proc{peek_is_char, peek_is_substr}

peek_is_char :: proc(t: ^Tokenizer, character: u8) -> bool {
	return peek(t) == character
}

peek_is_substr :: proc(t: ^Tokenizer, substr: string) -> bool {
	return strings.starts_with(t.src[t.pos:], substr)
}

scan :: proc(t: ^Tokenizer) -> Token {
	for {
		if t.pos >= len(t.src) do break
		
		// Detecting Whitespace
		whitespace_start := t.pos
		for t.pos < len(t.src) && is_whitespace(peek(t)) do t.pos += 1
		whitespace_before := t.pos > whitespace_start
		if t.pos >= len(t.src) do return {.EOF, "", whitespace_before}
		
		// Parsing everything else
		start_pos := t.pos
		next_token := classify_next_token(t)

		switch next_token {
		case .OpenParens, .CloseParens, .OpenBrace, .CloseBrace, .NewLine, .OpenSquareBracket, .CloseSquareBracket:
			t.pos += 1
		case .Word:
			for t.pos < len(t.src) && is_alphanumeric(peek(t)) do t.pos += 1
		case .SingleLineComment:
			for t.pos < len(t.src) && peek(t) != '\n' do t.pos += 1
		case .MultiLineComment:
			t.pos += 2
			for t.pos < len(t.src) && !peek_is(t, "*/") do t.pos += 1
			t.pos += 2 // Skipping the closing `*/`
		case .StringQuote:
			scan_quoted_escaping(t, '"')
		case .StringBacktick:
			t.pos += 1
			for t.pos < len(t.src) && peek(t) != '`' do t.pos += 1
			t.pos += 1
		case .Character:
			scan_quoted_escaping(t, '\'')
		case .Other:
			for t.pos < len(t.src) && classify_next_token(t) == .Other do t.pos += 1
		case .EOF:
		}

		return {next_token, t.src[start_pos:t.pos], whitespace_before}
	}

	return Token {.EOF, "", false}
}

// Scans quoted strings of text (like "a string" and 'a' character), while escaping anything after a `\`
scan_quoted_escaping :: proc(t: ^Tokenizer, quote: u8) {
	t.pos += 1
	for t.pos < len(t.src) {
		character := read(t)
		// Ignore escaped characters
		if character == '\\' {
			if t.pos < len(t.src) do t.pos += 1
			continue
		}
		if character == quote do break
	}
}

classify_next_token :: proc(t: ^Tokenizer) -> TokenType {
	character := peek(t)
	if kind, ok := get_single_char_token(character); ok do return kind
	if peek_is(t, "//") do return .SingleLineComment
	if peek_is(t, "/*") do return .MultiLineComment
	if is_letter(character) do return .Word
	if character == '"' do return .StringQuote
	if character == '`' do return .StringBacktick
	if character == '\'' do return .Character
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
	case '[': return .OpenSquareBracket, true
	case ']': return .CloseSquareBracket, true
	case '\n': return .NewLine, true
	case: return .Other, false
	}
}

@(private) _ascii_space := [256]bool{'\t' = true, '\n' = false, '\v' = true, '\f' = true, '\r' = true, ' ' = true}

// does not count \n (newline) (newline is not considered whitespace)
is_whitespace :: proc(character: u8) -> bool {
	return _ascii_space[character]
}
