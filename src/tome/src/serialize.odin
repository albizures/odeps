package tome

import "core:fmt"
import "core:strings"

Indent_Type :: enum {
	Tabs,
	Spaces,
}

Serialize_Options :: struct {
	max_inline_items:      int,
	max_inline_properties: int,
	indent_type:           Indent_Type,
	indent_count:          int,
}

DEFAULT_SERIALIZE_OPTIONS :: Serialize_Options {
	max_inline_items      = 5,
	max_inline_properties = 3,
	indent_type           = .Tabs,
	indent_count          = 1,
}

serialize :: proc(
	obj: Object,
	allocator := context.allocator,
	options := DEFAULT_SERIALIZE_OPTIONS,
) -> string {
	builder := strings.builder_make(allocator)

	first := true
	for key, value in obj {
		if !first {
			strings.write_string(&builder, ",\n")
		}
		first = false

		strings.write_string(&builder, key)
		strings.write_string(&builder, "=")
		serialize_value(&builder, value, options, 0)
	}

	return strings.to_string(builder)
}

@(private)
write_indent :: proc(builder: ^strings.Builder, options: Serialize_Options, level: int) {
	for _ in 0 ..< (level * options.indent_count) {
		if options.indent_type == .Tabs {
			strings.write_string(builder, "\t")
		} else {
			strings.write_string(builder, " ")
		}
	}
}

@(private)
serialize_value :: proc(
	builder: ^strings.Builder,
	val: Value,
	options: Serialize_Options,
	indent_level: int,
) {
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
		multiline := len(v) > options.max_inline_items
		strings.write_string(builder, "[")
		if multiline {
			strings.write_string(builder, "\n")
		}
		for item, i in v {
			if multiline {
				write_indent(builder, options, indent_level + 1)
			} else if i > 0 {
				strings.write_string(builder, ", ")
			}
			serialize_value(builder, item, options, indent_level + 1)
			if multiline {
				strings.write_string(builder, ",\n")
			}
		}
		if multiline {
			write_indent(builder, options, indent_level)
		}
		strings.write_string(builder, "]")
	case Object:
		multiline := len(v) > options.max_inline_properties
		strings.write_string(builder, "{")
		if multiline {
			strings.write_string(builder, "\n")
		}
		first := true
		for key, value in v {
			if multiline {
				write_indent(builder, options, indent_level + 1)
			} else if !first {
				strings.write_string(builder, ", ")
			}
			first = false

			strings.write_string(builder, key)
			strings.write_string(builder, "=")
			serialize_value(builder, value, options, indent_level + 1)
			if multiline {
				strings.write_string(builder, ",\n")
			}
		}
		if multiline {
			write_indent(builder, options, indent_level)
		}
		strings.write_string(builder, "}")
	}
}
