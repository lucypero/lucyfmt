package lucyfmt

import "core:fmt"
import "core:os"

main :: proc() {
	args := os.args[1:]

	write_back := false
	file_path: string

	for arg in args {
		if arg == "-w" {
			write_back = true
		} else {
			file_path = arg
		}
	}

	input: string
	read_from_stdin := len(file_path) == 0

	if read_from_stdin {
		buf: [dynamic]u8
		defer delete(buf)
		tmp: [4096]u8
		for {
			n, err := os.read(os.stdin, tmp[:])
			if n > 0 {
				append(&buf, ..tmp[:n])
			}
			if err != nil {
				break
			}
		}
		input = string(buf[:])
	} else {
		data, err := os.read_entire_file(file_path, context.allocator)
		if err != nil {
			fmt.eprintfln("error: could not read file: %s", file_path)
			os.exit(1)
		}
		input = string(data)
	}

	result := format_source(input)

	if write_back && !read_from_stdin {
		werr := os.write_entire_file(file_path, transmute([]u8)result)
		if werr != nil {
			fmt.eprintfln("error: could not write file: %s", file_path)
			os.exit(1)
		}
	} else {
		fmt.print(result)
	}
}
