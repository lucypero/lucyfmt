# TODO

## Case 1

what to do with this?

```odin
	if strings.contains(compact, "::proc") ||
	strings.contains(compact, "::struct") ||
	strings.contains(compact, "::enum") ||
	strings.contains(compact, "::union") ||
	strings.contains(compact, "::bit_field") {
		return true
	}
```

## Case 2

It's not indenting the if block here. 
it's when there's a variable containing "when"
we must test if the word "when" is in the line. probably checking for whitespace in-between

```odin
		if ch == '{' {
			if result.when_detected {
			queue.push_front(&state.ident_stack, IndentType.When)
			} else {
				queue.push_front(&state.ident_stack, IndentType.Normal)
				result.net_change += 1
			}

			i += 1
			continue
		}
```


## Case 3


	g_map = {
		g_map.arena,
		v2{50, WINDOW_HEIGHT - 10},
		v2{1,1},
		map_size,
		cell_tex_size,
	{},
	{},
	}

It's indenting the {} incorrectly.
