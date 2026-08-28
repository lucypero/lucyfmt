# lucyfmt

Minimalistic Odin formatter.

- Indents lines with 1 tab per scope level
- Pulls a lone opening `{` up onto the previous line when that line is a block header awaiting its body — a `proc` / `struct` / `enum` / `union` / `bit_field` declaration or a control-flow statement (`if` / `for` / `switch` / `when` / `else`, `#partial` prefix and labels included). A lone `{` that opens a standalone scope block is left on its own line. Blank lines between the header and the brace are dropped; the merge is skipped when a comment sits in between, or when the brace is inside a raw string or multi-line comment. A trailing `// comment` on the brace line is carried along.
- Collapses a line beginning with `else` (`else`, `else {`, `else if …`, `else when …`) onto the previous line when it ends with `}`, using the same blank-line / comment / raw-string rules as above.
- Does not indent `when` blocks
- Leaves the contents like multi line strings and multi line comments untouched
- Adds one indent level to parameters if they were broken up into multiple lines. example:

input:

```odin
	fmt.printfln("%v %v %v",
	a,
	3,
	5
	)
```

output:

```odin
	fmt.printfln("%v %v %v",
		a,
		3,
		5
	)
```

## Build

```sh
odin build .
```

Last compiled with Odin version: `dev-2026-08:db0cd7963`

## Usage

```sh
./lucyfmt file.odin          # print to stdout
./lucyfmt -w file.odin       # format in-place
cat file.odin | ./lucyfmt    # read from stdin
```
