# lucyfmt

Minimalistic Odin formatter.

- Indents lines with 1 tab per scope level
- Enforces `proc() { ` (Opening brace on the same line as the signature)
- Does not indent `when` blocks
- Leaves the contents like multi line strings and multi line comments untouched
- Adds one indent level to parameters if they were broken up into multiple lines.

# Example

Input:

```odin
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


```

Output:

```odin
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
