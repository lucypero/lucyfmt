package lucyfmt

import "core:strings"
import "core:fmt"
import "core:os"

main :: proc() {

	path :: "formatter_test.odin"

	file, err := os.read_entire_file(path, context.allocator)
	defer delete(file)
	assert(err == nil)

	tk : tokenizer.Tokenizer
	tokenizer.init(&tk, string(file), path)

	for {
		tok := tokenizer.scan(&tk)
		if tok.kind == .EOF do break
		fmt.printfln("%v", tok)
	}
}

format_source :: proc(input: string) -> string {
	sb_out := strings.builder_make()
	
	tk : Tokenizer
	tokenizer_init(&tk, input)

	for {
		tok := tokenizer.scan(&tk)
		if tok.kind == .EOF do break
		strings.write_string(&sb_out, tok.text)
	}

	return strings.to_string(sb_out)
}

Tokenizer :: struct {
	input: string,
	offset: int
}

tokenizer_init :: proc(t: ^Tokenizer, input: string) {
	t^ = Tokenizer {
		input,
		0
	}
}
