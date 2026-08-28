# lucyfmt

Minimalistic Odin formatter.

- Indents lines with 1 tab per scope level
- Pulls a lone opening `{` up onto the previous line for every construct (proc, struct, `if`, `for`, …), dropping any blank lines in between. Skips the merge when a comment sits between the definition and the brace, or when the brace is inside a raw string or multi-line comment. A trailing `// comment` on the brace line is carried along.
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
