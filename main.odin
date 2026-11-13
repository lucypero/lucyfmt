package lucyfmt

import "core:io"
import "core:strings"
import "core:fmt"

main :: proc() {

}

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

TokenType :: enum { Word, OpenParens, CloseParens, OpenBrace, CloseBrace, NewLine, EOF}

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

scan :: proc(t: ^Tokenizer) -> Token {
	for {
		start_pos := t.pos
		
		if t.pos >= len(t.src) - 1 do return {.EOF, ""}
		cur_r := read(t)
		one_rune_str := t.src[t.pos-1:t.pos]
		
		switch {
		case is_letter(cur_r):
			return scan_word(t)
		case cur_r == '(': 
			return {.OpenParens, one_rune_str}
		case cur_r == ')': 
			return {.CloseParens, one_rune_str}
		case cur_r == '{': 
			return {.OpenBrace, one_rune_str}
		case cur_r == '}': 
			return {.CloseBrace, one_rune_str}
		case cur_r == '\n': 
			return {.NewLine, one_rune_str}
		}

		for {
			// keep reading until starts_token() and return an Other token
		}
	}

	return {.EOF, ""}
}

scan_word :: proc(t: ^Tokenizer) -> Token {
	word_start := t.pos - 1
	
	for {
		if t.pos >= len(t.src) - 1 do return {.EOF, ""}
		if !is_alpha(read(t)) {
			t.pos -= 1
			return {.Word, t.src[word_start:t.pos]}
		}
	}
}

is_alpha :: proc(r: u8) -> bool {
	switch r {
	case 'a'..='z', 'A'..='Z': return true
	case '1'..='9': return true
	}

	return false
}

is_letter :: proc(r: u8) -> bool {
	switch r {
	case 'a'..='z', 'A'..='Z': return true
	}

	return false
	
}
