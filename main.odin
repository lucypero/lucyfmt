package lucyfmt

import "core:strings"
import "core:fmt"
import "core:os"
import "core:odin/tokenizer"

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
	
	tk : tokenizer.Tokenizer
	tokenizer.init(&tk, input, "input_file.odin")

	for {
		tok := tokenizer.scan(&tk)
		if tok.kind == .EOF do break
		strings.write_string(&sb_out, tok.text)
	}


	
	return strings.to_string(sb_out)
}
