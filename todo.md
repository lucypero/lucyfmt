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

It's not indenting the if block here. i don't know why.

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
