# lucyfmt

Minimalistic Odin formatter.

- Indents lines with 1 tab per scope level
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
odin build . -out:lucyfmt
```

## Usage

```sh
./lucyfmt file.odin          # print to stdout
./lucyfmt -w file.odin       # format in-place
cat file.odin | ./lucyfmt    # read from stdin
```
