# lucyfmt

Minimalistic Odin formatter. Only fixes indentation (1 tab per level). Everything else is left untouched.

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
