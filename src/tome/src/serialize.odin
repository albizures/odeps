package tome

import "core:fmt"
import "core:strings"

serialize :: proc(obj: Object, allocator := context.allocator) -> string {
	builder := strings.builder_make(allocator)

	first := true
	for key, value in obj {
		if !first {
			strings.write_string(&builder, ",\n")
		}
		first = false

		strings.write_string(&builder, key)
		strings.write_string(&builder, "=")
		serialize_value(&builder, value)
	}

	return strings.to_string(builder)
}

@(private)
serialize_value :: proc(builder: ^strings.Builder, val: Value) {
	switch v in val {
	case Integer:
		fmt.sbprintf(builder, "%d", v)
	case Float:
		fmt.sbprintf(builder, "%f", v)
	case Bool:
		if v {
			strings.write_string(builder, "true")
		} else {
			strings.write_string(builder, "false")
		}
	case String:
		strings.write_string(builder, "\"")
		strings.write_string(builder, string(v))
		strings.write_string(builder, "\"")
	case Nil:
		strings.write_string(builder, "nil")
	case Array:
		strings.write_string(builder, "[")
		for item, i in v {
			if i > 0 {
				strings.write_string(builder, ", ")
			}
			serialize_value(builder, item)
		}
		strings.write_string(builder, "]")
	case Object:
		strings.write_string(builder, "{")
		first := true
		for key, value in v {
			if !first {
				strings.write_string(builder, ", ")
			}
			first = false

			strings.write_string(builder, key)
			strings.write_string(builder, "=")
			serialize_value(builder, value)
		}
		strings.write_string(builder, "}")
	}
}
