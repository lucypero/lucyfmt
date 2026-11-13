package lucyfmt

import "core:io"
import "core:strings"
import "core:fmt"

main :: proc() {

}

format_source :: proc(input: string) -> string {
	sb_out := strings.builder_make()
	
	r : strings.Reader
	strings.reader_init(&r, input)

	for {
		tok := scan(&r)
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

scan :: proc(r: ^strings.Reader) -> Token {
	for {
		cur_r , size, err := strings.reader_read_rune(r)
		if err == .EOF do return {.EOF, ""}

		one_rune_str, _ := strings.substring(r.s, cast(int)r.prev_rune, cast(int)r.i)

		switch {
		case is_letter(cur_r):
			return scan_word(r)
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
	}

	return {.EOF, ""}
}

scan_word :: proc(r: ^strings.Reader) -> Token {
	word_start := r.i - 1
	
	for {
		cur_r , size, err := strings.reader_read_rune(r)
		if err == .EOF do return {.EOF, ""}
		if !is_alpha(cur_r) {
			// end of word. returning.
			word, _ := strings.substring(r.s, cast(int)word_start, cast(int)r.i - 1)
			strings.reader_unread_rune(r)
			return {.Word, word}
		}
	}
}

is_alpha :: proc(r: rune) -> bool {
	switch r {
	case 'a'..='z', 'A'..='Z': return true
	case 1..=9: return true
	}

	return false
}

is_letter :: proc(r: rune) -> bool {
	switch r {
	case 'a'..='z', 'A'..='Z': return true
	}

	return false
	
}
