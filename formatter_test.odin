package lucyfmt

import "core:strings"
import "core:testing"
import "core:fmt"
import "core:log"

Test_Case :: struct {
	name:     string,
	input:    string,
	expected: string,
}

@(test)
test_format :: proc(t: ^testing.T) {
	cases := []Test_Case{
		// 1. Basic indent
		{
			name     = "basic indent",
			input    = "main :: proc() {\nx := 1\n}\n",
			expected = "main :: proc() {\n\tx := 1\n}\n",
		},
		// 2. Nested blocks
		{
			name     = "nested blocks",
			input    = "outer :: proc() {\nif true {\nx := 1\n}\n}\n",
			expected = "outer :: proc() {\n\tif true {\n\t\tx := 1\n\t}\n}\n",
		},
		// 3. Braces in strings ignored
		{
			name     = "braces in strings",
			input    = "x := \"}\"\nif true {\ny := 1\n}\n",
			expected = "x := \"}\"\nif true {\n\ty := 1\n}\n",
		},
		// 4. Braces in single-line comments ignored
		{
			name     = "braces in comments",
			input    = "// {\nif true {\nx := 1\n}\n",
			expected = "// {\nif true {\n\tx := 1\n}\n",
		},
		// 5. Braces in multi-line comments ignored
		{
			name     = "braces in multi-line comments",
			input    = "/* { */\nif true {\nx := 1\n}\n",
			expected = "/* { */\nif true {\n\tx := 1\n}\n",
		},
		// 6. Nested multi-line comments
		{
			name     = "nested multi-line comments",
			input    = "/* /* { */ */\nif true {\nx := 1\n}\n",
			expected = "/* /* { */ */\nif true {\n\tx := 1\n}\n",
		},
		// 7. Braces in raw strings ignored
		{
			name     = "braces in raw strings",
			input    = "x := `}`\nif true {\ny := 1\n}\n",
			expected = "x := `}`\nif true {\n\ty := 1\n}\n",
		},
		// 8. Braces in char literals ignored
		{
			name     = "braces in char literals",
			input    = "x := '}'\nif true {\ny := 1\n}\n",
			expected = "x := '}'\nif true {\n\ty := 1\n}\n",
		},
		// 9. Empty lines preserved
		{
			name     = "empty lines preserved",
			input    = "a :: proc() {\n\nx := 1\n\n}\n",
			expected = "a :: proc() {\n\n\tx := 1\n\n}\n",
		},
		// 10. } else { pattern
		{
			name     = "close-open pattern",
			input    = "if true {\nx := 1\n} else {\ny := 2\n}\n",
			expected = "if true {\n\tx := 1\n} else {\n\ty := 2\n}\n",
		},
		// 11. Idempotency
		{
			name     = "idempotency",
			input    = "main :: proc() {\n\tx := 1\n}\n",
			expected = "main :: proc() {\n\tx := 1\n}\n",
		},
		// 12. Escaped quotes in strings
		{
			name     = "escaped quotes",
			input    = "x := \"\\\"}\\\"\"\nif true {\ny := 1\n}\n",
			expected = "x := \"\\\"}\\\"\"\nif true {\n\ty := 1\n}\n",
		},
		// 13. Wrong existing indentation corrected
		{
			name     = "fix wrong indent",
			input    = "  if true {\n      x := 1\n  }\n",
			expected = "if true {\n\tx := 1\n}\n",
		},
		// 14. Multi-line raw strings
		{
			name     = "multi-line raw strings",
			input    = "x := `hello {\nworld }\n`\nif true {\ny := 1\n}\n",
			expected = "x := `hello {\nworld }\n`\nif true {\n\ty := 1\n}\n",
		},
		// 15. Single-line comment preserved
		{
			name     = "single-line comment preserved",
			input    = "//   custom comment\nif true {\nx := 1\n}\n",
			expected = "//   custom comment\nif true {\n\tx := 1\n}\n",
		},
		// 16. Multi-line comment preserved
		{
			name     = "multi-line comment preserved",
			input    = "/* multi\nline comment */\nif true {\nx := 1\n}\n",
			expected = "/* multi\nline comment */\nif true {\n\tx := 1\n}\n",
		},
		// 17. Paren indentation
		{
			name     = "paren indentation",
			input    = "foo(\nbar,\nbaz\n)\n",
			expected = "foo(\n\tbar,\n\tbaz\n)\n",
		},
		// 18. Nested paren indentation
		{
			name     = "nested paren indentation",
			input    = "foo(\nbar,\nbaz(\nqux\n)\n)\n",
			expected = "foo(\n\tbar,\n\tbaz(\n\t\tqux\n\t)\n)\n",
		},
		// 19. Paren + brace indentation
		{
			name     = "paren and brace indentation",
			input    = "main :: proc() {\nfoo(\nbar\n)\n}\n",
			expected = "main :: proc() {\n\tfoo(\n\t\tbar\n\t)\n}\n",
		},
		{
			name     = "paren and brace indentation - advanced",
			input    = `

package main

import "core:fmt"

main :: proc() {

		// comment here
		
	a: int
	
	fmt.printfln("%v %v %v",
	a,
	3,
	5
	)
}
`,
			expected = `

package main

import "core:fmt"

main :: proc() {

	// comment here

	a: int

	fmt.printfln("%v %v %v",
		a,
		3,
		5
	)
}
`
		},
		{
			name     = "multi line tests",
			input    = `

package main

import "core:fmt"

main :: proc() {

		hello :=  ` + "`" + `lala
hello hello
` + "`" + `


}
`,
			expected = `

package main

import "core:fmt"

main :: proc() {

	hello :=  ` + "`" + `lala
hello hello
` + "`" + `


}
`,
		},
		{
			name = "when",
			input = `

lala :: proc() {
	alloc_err := virtual.arena_init_growing(&temp_arena, mem.Megabyte)
	
	when ODIN_DEBUG {
		lprintln("Tracking Allocations...")
	}
	
	apple := "table"
}
`,
			expected = `

lala :: proc() {
	alloc_err := virtual.arena_init_growing(&temp_arena, mem.Megabyte)

	when ODIN_DEBUG {
		lprintln("Tracking Allocations...")
	}

	apple := "table"
}
`
		},
		{
			name = "switch statement",
			input = `
			
lala :: proc() {

	imgui_impl_sdl2.ProcessEvent(&e)
	
	#partial switch e.type {
		case .QUIT:
		break main_loop
		case .WINDOWEVENT:
			if e.window.event == .CLOSE {
				break main_loop
			}
	}
	
	lala := 1
}
`,
			expected = `

lala :: proc() {

	imgui_impl_sdl2.ProcessEvent(&e)

	#partial switch e.type {
	case .QUIT:
		break main_loop
	case .WINDOWEVENT:
		if e.window.event == .CLOSE {
			break main_loop
		}
	}

	lala := 1
}
`
		},
		
	}

	for tc in cases {
		result := format_source(tc.input)
		defer delete(result)

		if result != tc.expected {
			sb := strings.builder_make_none()
			defer strings.builder_destroy(&sb)
			
			fmt.sbprintln(&sb,"FAIL: ", tc.name)
			fmt.sbprintln(&sb,"=====   Input:    ", make_whitespace_visible(tc.input))
			fmt.sbprintln(&sb,"=====   Expected: ", make_whitespace_visible(tc.expected))
			fmt.sbprintln(&sb,"=====   Test output: ", make_whitespace_visible(result))
			
			log.error(strings.to_string(sb))
			
			testing.fail(t)
		}
	}
}

@(test)
test_crlf_normalization :: proc(t: ^testing.T) {
	input := "main :: proc() {\r\nx := 1\r\n}\r\n"
	expected := "main :: proc() {\n\tx := 1\n}\n"
	result := format_source(input)

	if result != expected {
		fmt.printfln("FAIL: crlf normalization")
		fmt.printfln("  expected: %q", expected)
		fmt.printfln("  got:      %q", result)
		testing.fail(t)
	}
}

make_whitespace_visible :: proc(str: string) -> string {
	
	str := str
	did_allocate: bool
	
	sb := strings.builder_make_none()
	strings.write_string(&sb, str)
	
	lines, err := strings.split_lines(str)
	
	strings.builder_replace_all(&sb, "\t", "[TAB]")
	
	for line in lines {
		// TODO:  make leading whitespace visible
		strings.starts_with(line, " ")
		
		
		
		// TODO: make trailing whitespace visible
	}
	
	strings.write_string(&sb, "[END]")
	
	
	// str, did_allocate = strings.replace_all(str, " ", "[TAB]")
	
	return strings.to_string(sb)
}
