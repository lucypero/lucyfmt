package lucyfmt

import "core:strings"
import "core:testing"
import "core:fmt"
import "core:log"

MAKE_WHITESPACE_VISIBLE :: false

Test_Case :: struct {
	name:     string,
	input:    string,
	expected: string,
}

// Simple block indentation, blank lines, idempotency, line endings.
@(test)
test_basic :: proc(t: ^testing.T) {
	cases := []Test_Case{
		// Basic indent
		{
			name     = "basic indent",
			input    = "main :: proc() {\nx := 1\n}\n",
			expected = "main :: proc() {\n\tx := 1\n}\n",
		},
		// Nested blocks
		{
			name     = "nested blocks",
			input    = "outer :: proc() {\nif true {\nx := 1\n}\n}\n",
			expected = "outer :: proc() {\n\tif true {\n\t\tx := 1\n\t}\n}\n",
		},
		// Empty lines preserved
		{
			name     = "empty lines preserved",
			input    = "a :: proc() {\n\nx := 1\n\n}\n",
			expected = "a :: proc() {\n\n\tx := 1\n\n}\n",
		},
		// Idempotency
		{
			name     = "idempotency",
			input    = "main :: proc() {\n\tx := 1\n}\n",
			expected = "main :: proc() {\n\tx := 1\n}\n",
		},
		// Wrong existing indentation corrected
		{
			name     = "fix wrong indent",
			input    = "  if true {\n      x := 1\n  }\n",
			expected = "if true {\n\tx := 1\n}\n",
		},
		// CRLF line endings normalized to LF
		{
			name = "basic",
			input = "main :: proc() {\r\nx := 1\r\n}\r\n",
			expected = "main :: proc() {\n\tx := 1\n}\n"
		},
		// Compound literal with empty braces on their own lines
		{
			name     = "compound literal with empty braces",
			input    = "g_map = {\ng_map.arena,\nv2{1, 1},\nmap_size,\n{},\n{},\n}\n",
			expected = "g_map = {\n\tg_map.arena,\n\tv2{1, 1},\n\tmap_size,\n\t{},\n\t{},\n}\n",
		},
	}

	check_format(t, cases)
}


// Strings, raw strings and char literals: braces inside are ignored, contents untouched.
@(test)
test_strings :: proc(t: ^testing.T) {
	cases := []Test_Case{
		// Braces in strings ignored
		{
			name     = "braces in strings",
			input    = "x := \"}\"\nif true {\ny := 1\n}\n",
			expected = "x := \"}\"\nif true {\n\ty := 1\n}\n",
		},
		// Braces in raw strings ignored
		{
			name     = "braces in raw strings",
			input    = "x := `}`\nif true {\ny := 1\n}\n",
			expected = "x := `}`\nif true {\n\ty := 1\n}\n",
		},
		// Braces in char literals ignored
		{
			name     = "braces in char literals",
			input    = "x := '}'\nif true {\ny := 1\n}\n",
			expected = "x := '}'\nif true {\n\ty := 1\n}\n",
		},
		// Escaped quotes in strings
		{
			name     = "escaped quotes",
			input    = "x := \"\\\"}\\\"\"\nif true {\ny := 1\n}\n",
			expected = "x := \"\\\"}\\\"\"\nif true {\n\ty := 1\n}\n",
		},
		// Multi-line raw strings
		{
			name     = "multi-line raw strings",
			input    = "x := `hello {\nworld }\n`\nif true {\ny := 1\n}\n",
			expected = "x := `hello {\nworld }\n`\nif true {\n\ty := 1\n}\n",
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
	}

	check_format(t, cases)
}

// Single-line, multi-line and nested comments: braces inside are ignored, contents preserved.
@(test)
test_comments :: proc(t: ^testing.T) {
	cases := []Test_Case{
		// Braces in single-line comments ignored
		{
			name     = "braces in comments",
			input    = "// {\nif true {\nx := 1\n}\n",
			expected = "// {\nif true {\n\tx := 1\n}\n",
		},
		// Braces in multi-line comments ignored
		{
			name     = "braces in multi-line comments",
			input    = "/* { */\nif true {\nx := 1\n}\n",
			expected = "/* { */\nif true {\n\tx := 1\n}\n",
		},
		// Nested multi-line comments
		{
			name     = "nested multi-line comments",
			input    = "/* /* { */ */\nif true {\nx := 1\n}\n",
			expected = "/* /* { */ */\nif true {\n\tx := 1\n}\n",
		},
		// Single-line comment preserved
		{
			name     = "single-line comment preserved",
			input    = "//   custom comment\nif true {\nx := 1\n}\n",
			expected = "//   custom comment\nif true {\n\tx := 1\n}\n",
		},
		// Multi-line comment preserved
		{
			name     = "multi-line comment preserved",
			input    = "/* multi\nline comment */\nif true {\nx := 1\n}\n",
			expected = "/* multi\nline comment */\nif true {\n\tx := 1\n}\n",
		},
		// Brace in a trailing line comment after code is ignored
		{
			name     = "brace in trailing line comment",
			input    = "x := 1 // {\nif true {\ny := 1\n}\n",
			expected = "x := 1 // {\nif true {\n\ty := 1\n}\n",
		},
		// Multi-line comment starting mid-line: braces ignored, inner lines untouched
		{
			name     = "multi-line comment starting mid-line",
			input    = "x := 1 /* {\n} */\nif true {\ny := 1\n}\n",
			expected = "x := 1 /* {\n} */\nif true {\n\ty := 1\n}\n",
		},
		// Inline block comment containing a brace
		{
			name     = "inline block comment with brace",
			input    = "main :: proc() {\nx := /* } */ 1\n}\n",
			expected = "main :: proc() {\n\tx := /* } */ 1\n}\n",
		},
		// Comment lines inside a block are indented like code
		{
			name     = "comment inside block indented",
			input    = "main :: proc() {\n// note\nx := 1\n}\n",
			expected = "main :: proc() {\n\t// note\n\tx := 1\n}\n",
		},
	}

	check_format(t, cases)
}

// Indentation inside parentheses, alone and mixed with braces.
@(test)
test_parens :: proc(t: ^testing.T) {
	cases := []Test_Case{
		// Paren indentation
		{
			name     = "paren indentation",
			input    = "foo(\nbar,\nbaz\n)\n",
			expected = "foo(\n\tbar,\n\tbaz\n)\n",
		},
		// Nested paren indentation
		{
			name     = "nested paren indentation",
			input    = "foo(\nbar,\nbaz(\nqux\n)\n)\n",
			expected = "foo(\n\tbar,\n\tbaz(\n\t\tqux\n\t)\n)\n",
		},
		// Paren + brace indentation
		{
			name     = "paren and brace indentation",
			input    = "main :: proc() {\nfoo(\nbar\n)\n}\n",
			expected = "main :: proc() {\n\tfoo(\n\t\tbar\n\t)\n}\n",
		},
		{
			name     = "multiple parens and brace in one line",
			input    = `
for &scene in g_scenes {
	st := scene_status_load(&scene.status)
	#partial switch st {
	case .Ready, .QueuedForDeletion:
	case:
		continue
	}

	queue_wait_on_upload_fence(ct.queue, scene.fence_value)

	// binding vertex buffer view and instance buffer view
	vertex_buffers_views := [?]dx.VERTEX_BUFFER_VIEW{scene.vertex_buffer_view}

	ct.cmdlist->IASetVertexBuffers(0, len(vertex_buffers_views), &vertex_buffers_views[0])
	ct.cmdlist->IASetIndexBuffer(&scene.index_buffer_view)

	// rendering each mesh individually
	// going through scene tree

	// drawing scene

	DrawConstants :: struct {
		mesh_index: u32,
		material_index: u32,
	}

	scene_walk(scene, nil, proc(node: Node, scene: Scene, data: rawptr) {
		ct := &g_dx_context

		if node.mesh == -1 {
			return
		}

		mesh_to_render := scene.meshes[node.mesh]

		for prim in mesh_to_render.primitives {
			dc := DrawConstants {
				mesh_index = u32(g_mesh_drawn_count),
				material_index = u32(prim.material_index),
			}
			ct.cmdlist->SetGraphicsRoot32BitConstants(0, 2, &dc, 0)
			ct.cmdlist->DrawIndexedInstanced(prim.index_count, 1, prim.index_offset, 0, 0)
		}
	})

	asd := 3
}
`,
			expected = `
for &scene in g_scenes {
	st := scene_status_load(&scene.status)
	#partial switch st {
	case .Ready, .QueuedForDeletion:
	case:
		continue
	}

	queue_wait_on_upload_fence(ct.queue, scene.fence_value)

	// binding vertex buffer view and instance buffer view
	vertex_buffers_views := [?]dx.VERTEX_BUFFER_VIEW{scene.vertex_buffer_view}

	ct.cmdlist->IASetVertexBuffers(0, len(vertex_buffers_views), &vertex_buffers_views[0])
	ct.cmdlist->IASetIndexBuffer(&scene.index_buffer_view)

	// rendering each mesh individually
	// going through scene tree

	// drawing scene

	DrawConstants :: struct {
		mesh_index: u32,
		material_index: u32,
	}

	scene_walk(scene, nil, proc(node: Node, scene: Scene, data: rawptr) {
		ct := &g_dx_context

		if node.mesh == -1 {
			return
		}

		mesh_to_render := scene.meshes[node.mesh]

		for prim in mesh_to_render.primitives {
			dc := DrawConstants {
				mesh_index = u32(g_mesh_drawn_count),
				material_index = u32(prim.material_index),
			}
			ct.cmdlist->SetGraphicsRoot32BitConstants(0, 2, &dc, 0)
			ct.cmdlist->DrawIndexedInstanced(prim.index_count, 1, prim.index_offset, 0, 0)
		}
	})

	asd := 3
}
`,
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
		// Brackets broken across lines indent like parens
		{
			name     = "bracket indentation",
			input    = "arr[\ni + 1\n] = 2\n",
			expected = "arr[\n\ti + 1\n] = 2\n",
		},
		// Brackets closed on the same line (types) do not affect indentation
		{
			name     = "brackets in types",
			input    = "m := map[string][]int{\n\"a\" = nil,\n}\n",
			expected = "m := map[string][]int{\n\t\"a\" = nil,\n}\n",
		},
		// Multi-line array literal
		{
			name     = "multi-line array literal",
			input    = "x := [3]int{\n1,\n2,\n3,\n}\n",
			expected = "x := [3]int{\n\t1,\n\t2,\n\t3,\n}\n",
		},
	}

	check_format(t, cases)
}


// else: indentation around `} else {` and collapsing a lone else back onto the closing brace.
@(test)
test_else :: proc(t: ^testing.T) {
	cases := []Test_Case{
		// } else { pattern
		{
			name     = "close-open pattern",
			input    = "if true {\nx := 1\n} else {\ny := 2\n}\n",
			expected = "if true {\n\tx := 1\n} else {\n\ty := 2\n}\n",
		},
		// Collapse else: bare else, Allman style
		{
			name     = "collapse bare else",
			input    = "if a {\nx\n}\nelse\n{\ny\n}\n",
			expected = "if a {\n\tx\n} else {\n\ty\n}\n",
		},
		// Collapse else: else if with condition and brace
		{
			name     = "collapse else if",
			input    = "if a {\nx\n}\nelse if b {\ny\n}\n",
			expected = "if a {\n\tx\n} else if b {\n\ty\n}\n",
		},
		// Collapse else: already inline is idempotent
		{
			name     = "collapse else idempotent",
			input    = "if a {\nx\n} else {\ny\n}\n",
			expected = "if a {\n\tx\n} else {\n\ty\n}\n",
		},
		// Collapse else: intervening blank lines removed
		{
			name     = "collapse else skips blank lines",
			input    = "if a {\nx\n}\n\n\nelse {\ny\n}\n",
			expected = "if a {\n\tx\n} else {\n\ty\n}\n",
		},
		// Collapse else: bail when a comment sits between } and else
		{
			name     = "collapse else bails on comment gap",
			input    = "if a {\nx\n}\n// hmm\nelse {\ny\n}\n",
			expected = "if a {\n\tx\n}\n// hmm\nelse {\n\ty\n}\n",
		},
		// Collapse else: fully Allman if + else
		{
			name     = "collapse else full allman",
			input    = "if a\n{\nx\n}\nelse\n{\ny\n}\n",
			expected = "if a {\n\tx\n} else {\n\ty\n}\n",
		},
		// Collapse else: `else` word boundary, does not eat `elsewhere`
		{
			name     = "collapse else word boundary",
			input    = "main :: proc() {\nelsewhere := 1\n}\n",
			expected = "main :: proc() {\n\telsewhere := 1\n}\n",
		},
		// Collapse else: else when (when blocks stay un-indented)
		{
			name     = "collapse else when",
			input    = "when A {\nx\n}\nelse when B {\ny\n}\n",
			expected = "when A {\nx\n} else when B {\ny\n}\n",
		},
		// Collapse else: `else` inside a raw string is left alone
		{
			name     = "collapse else ignores raw string",
			input    = "x := `\nelse\n`\nif a {\nb\n}\nelse {\nc\n}\n",
			expected = "x := `\nelse\n`\nif a {\n\tb\n} else {\n\tc\n}\n",
		},
	}

	check_format(t, cases)
}

// switch statements: case labels at the switch's level, case bodies one level deeper.
@(test)
test_switch :: proc(t: ^testing.T) {
	cases := []Test_Case{
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
		// Plain switch, case with several statements
		{
			name     = "plain switch multiple statements",
			input    = "switch x {\ncase 1:\na()\nb()\ncase 2:\nc()\n}\n",
			expected = "switch x {\ncase 1:\n\ta()\n\tb()\ncase 2:\n\tc()\n}\n",
		},
		// Switch without a condition
		{
			name     = "switch without condition",
			input    = "switch {\ncase x > 1:\na()\ncase:\nb()\n}\n",
			expected = "switch {\ncase x > 1:\n\ta()\ncase:\n\tb()\n}\n",
		},
		// Type switch
		{
			name     = "type switch",
			input    = "switch v in val {\ncase int:\na()\ncase:\nb()\n}\n",
			expected = "switch v in val {\ncase int:\n\ta()\ncase:\n\tb()\n}\n",
		},
		// fallthrough is indented like any statement in a case body
		{
			name     = "fallthrough",
			input    = "switch x {\ncase 1:\nfallthrough\ncase 2:\ny()\n}\n",
			expected = "switch x {\ncase 1:\n\tfallthrough\ncase 2:\n\ty()\n}\n",
		},
		// Switch nested inside a case body
		{
			name     = "nested switch",
			input    = "switch a {\ncase 1:\nswitch b {\ncase 2:\nx()\n}\ncase 3:\ny()\n}\n",
			expected = "switch a {\ncase 1:\n\tswitch b {\n\tcase 2:\n\t\tx()\n\t}\ncase 3:\n\ty()\n}\n",
		},
	}

	check_format(t, cases)
}

// when blocks: the body of a when is not indented.
@(test)
test_when :: proc(t: ^testing.T) {
	cases := []Test_Case{
		{ // TODO: skip when indentation when u implement it
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
			name = "readme example",
			input = ```

main :: proc() 
{

/*
  hello
  odd multi line comment here
  spaces and tabs
*/

	when ODIN_DEBUG 
	{
		fmt.println(
"hello",
"world"
		)
	}
}
```,
			expected = ```

main :: proc() {

/*
  hello
  odd multi line comment here
  spaces and tabs
*/

	when ODIN_DEBUG {
	fmt.println(
		"hello",
		"world"
	)
	}
}
```
		},
		// Nested when blocks: neither body is indented
		{
			name     = "nested when",
			input    = "when A {\nwhen B {\nx := 1\n}\n}\n",
			expected = "when A {\nwhen B {\nx := 1\n}\n}\n",
		},
		// when inside a proc keeps the proc's indentation
		{
			name     = "when inside proc",
			input    = "main :: proc() {\nwhen A {\nx := 1\n}\n}\n",
			expected = "main :: proc() {\n\twhen A {\n\tx := 1\n\t}\n}\n",
		},
		// if inside a when is still indented
		{
			name     = "if inside when",
			input    = "when A {\nif b {\nx := 1\n}\n}\n",
			expected = "when A {\nif b {\n\tx := 1\n}\n}\n",
		},
		// Identifier containing `when` is not treated as a when block
		{
			name     = "identifier containing when",
			input    = "main :: proc() {\nif result.when_detected {\nx := 1\n} else {\ny := 2\n}\n}\n",
			expected = "main :: proc() {\n\tif result.when_detected {\n\t\tx := 1\n\t} else {\n\t\ty := 2\n\t}\n}\n",
		},
		// `when` inside a string is not treated as a when block
		{
			name     = "when inside string",
			input    = "x := \"when\"\nif true {\ny := 1\n}\n",
			expected = "x := \"when\"\nif true {\n\ty := 1\n}\n",
		},
	}

	check_format(t, cases)
}

// Unusual input: empty files, missing newlines, unbalanced braces.
@(test)
test_edge_cases :: proc(t: ^testing.T) {
	cases := []Test_Case{
		// Empty file stays empty
		{
			name     = "empty file",
			input    = "",
			expected = "",
		},
		// File with only blank lines
		{
			name     = "only blank lines",
			input    = "\n\n",
			expected = "\n\n",
		},
		// Missing trailing newline gets one added
		{
			name     = "no trailing newline",
			input    = "main :: proc() {\nx := 1\n}",
			expected = "main :: proc() {\n\tx := 1\n}\n",
		},
		// File with only comments is untouched
		{
			name     = "only comments",
			input    = "// line comment\n/* block\n   comment */\n",
			expected = "// line comment\n/* block\n   comment */\n",
		},
		// Extra closing braces clamp indentation at zero instead of going negative
		{
			name     = "too many closing braces",
			input    = "}\n}\nx := 1\n",
			expected = "}\n}\nx := 1\n",
		},
		// Unclosed brace still indents what follows
		{
			name     = "unclosed brace",
			input    = "main :: proc() {\nx := 1\n",
			expected = "main :: proc() {\n\tx := 1\n",
		},
	}

	check_format(t, cases)
}

// Brace cuddling: a lone opening brace is pulled onto a recognized block header, and left alone everywhere else.
@(test)
test_cuddle :: proc(t: ^testing.T) {
	cases := []Test_Case{
		// Cuddle: proc brace pulled onto the signature line
		{
			name     = "cuddle proc brace",
			input    = "main :: proc()\n{\nx := 1\n}\n",
			expected = "main :: proc() {\n\tx := 1\n}\n",
		},
		// Cuddle: struct brace
		{
			name     = "cuddle struct brace",
			input    = "Foo :: struct\n{\nx: int,\n}\n",
			expected = "Foo :: struct {\n\tx: int,\n}\n",
		},
		// Cuddle: control-flow brace (every construct)
		{
			name     = "cuddle if brace",
			input    = "if true\n{\nx := 1\n}\n",
			expected = "if true {\n\tx := 1\n}\n",
		},
		// Cuddle: intervening blank lines are removed
		{
			name     = "cuddle skips blank lines",
			input    = "main :: proc()\n\n\n{\nx := 1\n}\n",
			expected = "main :: proc() {\n\tx := 1\n}\n",
		},
		// Cuddle: split signature, brace onto the lone close paren
		{
			name     = "cuddle split signature",
			input    = "foo :: proc(\na: int,\nb: int,\n)\n{\nx := 1\n}\n",
			expected = "foo :: proc(\n\ta: int,\n\tb: int,\n) {\n\tx := 1\n}\n",
		},
		// Cuddle: bail when a comment sits between definition and brace
		{
			name     = "cuddle bails on comment gap",
			input    = "main :: proc()\n// note\n{\nx := 1\n}\n",
			expected = "main :: proc()\n// note\n{\n\tx := 1\n}\n",
		},
		// Cuddle: trailing comment on the brace line is carried along
		{
			name     = "cuddle carries trailing comment",
			input    = "main :: proc()\n{ // open\nx := 1\n}\n",
			expected = "main :: proc() { // open\n\tx := 1\n}\n",
		},
		// Cuddle: brace inside a raw string is left alone
		{
			name     = "cuddle ignores raw string brace",
			input    = "x := `\n{\n`\nif true\n{\ny := 1\n}\n",
			expected = "x := `\n{\n`\nif true {\n\ty := 1\n}\n",
		},
		// Cuddle: already cuddled input is idempotent
		{
			name     = "cuddle idempotent",
			input    = "main :: proc() {\n\tx := 1\n}\n",
			expected = "main :: proc() {\n\tx := 1\n}\n",
		},
		// Cuddle: else on its own line
		{
			name     = "cuddle else brace",
			input    = "if true {\nx := 1\n} else\n{\ny := 2\n}\n",
			expected = "if true {\n\tx := 1\n} else {\n\ty := 2\n}\n",
		},
		// Bare scope block after an assignment is NOT cuddled
		{
			name     = "bare scope block not cuddled (assignment)",
			input    = "main :: proc() {\nx := 1\n{\ny := 2\n}\n}\n",
			expected = "main :: proc() {\n\tx := 1\n\t{\n\t\ty := 2\n\t}\n}\n",
		},
		// Bare scope block after a call is NOT cuddled
		{
			name     = "bare scope block not cuddled (call)",
			input    = "main :: proc() {\nsetup()\n{\nwork()\n}\n}\n",
			expected = "main :: proc() {\n\tsetup()\n\t{\n\t\twork()\n\t}\n}\n",
		},
		// Proc with return type, Allman brace, still cuddled
		{
			name     = "cuddle proc with return type",
			input    = "add :: proc(a: int, b: int) -> int\n{\nreturn a\n}\n",
			expected = "add :: proc(a: int, b: int) -> int {\n\treturn a\n}\n",
		},
		// #partial switch, Allman brace, still cuddled
		{
			name     = "cuddle partial switch",
			input    = "foo :: proc() {\n#partial switch x\n{\ncase:\n}\n}\n",
			expected = "foo :: proc() {\n\t#partial switch x {\n\tcase:\n\t}\n}\n",
		},
		// Tagged union header (#no_nil) still cuddled
		{
			name     = "cuddle tagged union",
			input    = "V :: union #no_nil\n{\nint,\nf32,\n}\n",
			expected = "V :: union #no_nil {\n\tint,\n\tf32,\n}\n",
		},
		// struct with directive still cuddled
		{
			name     = "cuddle struct with directive",
			input    = "P :: struct #packed\n{\nx: u8,\n}\n",
			expected = "P :: struct #packed {\n\tx: u8,\n}\n",
		},
		// enum with backing type still cuddled
		{
			name     = "cuddle enum with backing type",
			input    = "E :: enum u8\n{\nA,\n}\n",
			expected = "E :: enum u8 {\n\tA,\n}\n",
		},
	}

	check_format(t, cases)
}

check_format :: proc(t: ^testing.T, cases: []Test_Case) {
	for tc in cases {
		result := format_source(tc.input)
		defer delete(result)
		defer free_all(context.temp_allocator)

		if result != tc.expected {
			sb := strings.builder_make_none()
			defer strings.builder_destroy(&sb)

			res_lines := strings.split(result, "\n", context.temp_allocator)
			expected_lines := strings.split(tc.expected, "\n", context.temp_allocator)

			when MAKE_WHITESPACE_VISIBLE {
				for &line in expected_lines {
					line = make_whitespace_visible(line)
				}
				
				for &line in res_lines {
					line = make_whitespace_visible(line)
				}
			}

			fmt.sbprintln(&sb,"FAIL test case:", tc.name)

			common := min(len(res_lines), len(expected_lines))
			for i in 0..<common {
				if res_lines[i] != expected_lines[i] {
					expected_lines[i] = strings.concatenate({expected_lines[i], " <-- DISCREPANCY"}, context.temp_allocator)
					res_lines[i] = strings.concatenate({res_lines[i], " <-- DISCREPANCY"}, context.temp_allocator)
				}
			}
			
			for i in common..<len(expected_lines) {
				expected_lines[i] = strings.concatenate({expected_lines[i], " <-- MISSING FROM OUTPUT"}, context.temp_allocator)
			}
			for i in common..<len(res_lines) {
				res_lines[i] = strings.concatenate({res_lines[i], " <-- EXTRA IN OUTPUT"}, context.temp_allocator)
			}

			fmt.sbprintfln(&sb,"==== Expected: ")
			for line in expected_lines {
				fmt.sbprintfln(&sb,"%v", line)
			}

			fmt.sbprintfln(&sb,"==== Test Output: ")
			for line in res_lines {
				fmt.sbprintfln(&sb,"%v", line)
			}

			log.error(strings.to_string(sb))
		}
	}
}

make_whitespace_visible :: proc(str: string) -> string {
	str := str
	sb := strings.builder_make_none(context.temp_allocator)
	strings.write_string(&sb, str)
	strings.builder_replace_all(&sb, "\t", "[T]")
	strings.builder_replace_all(&sb, " ", "[S]")
	strings.builder_replace_all(&sb, "\v", "[V]")
	strings.builder_replace_all(&sb, "\f", "[F]")
	strings.builder_replace_all(&sb, "\r", "[R]")
	strings.builder_replace_all(&sb, "\n", "[N]")
	strings.write_string(&sb, "[END]")
	// str, did_allocate = strings.replace_all(str, " ", "[TAB]")
	return strings.to_string(sb)
}
