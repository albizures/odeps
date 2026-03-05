package url_core

import "core:mem"
import "core:strings"
import "core:unicode/utf8"

Query_Param :: struct {
	key:   string,
	value: string,
}


Query_Parser :: struct {
	using consumable: Consumable_Rune,
	params:           [dynamic]Query_Param,
	errors:           [dynamic]Url_Error,
	allocator:        mem.Allocator,
}

parse_query_params :: proc(
	query: string,
	allocator := context.allocator,
) -> (
	[dynamic]Query_Param,
	[]Url_Error,
) {
	parser: Query_Parser = {
		consumable = {data = query},
		params = make([dynamic]Query_Param, allocator),
		errors = make([dynamic]Url_Error, allocator),
		allocator = allocator,
	}

	consume_rune(&parser.consumable)

	for parser.current != utf8.RUNE_EOF {
		key_start := parser.index

		// Parse key until '=', '&', or EOF
		for parser.current != utf8.RUNE_EOF && parser.current != '=' && parser.current != '&' {
			consume_rune(&parser.consumable)
		}

		key_raw := parser.data[key_start:parser.index]
		value_raw := ""

		if parser.current == '=' {
			consume_rune(&parser.consumable) // consume '='
			value_start := parser.index

			// Parse value until '&' or EOF
			for parser.current != utf8.RUNE_EOF && parser.current != '&' {
				consume_rune(&parser.consumable)
			}
			value_raw = parser.data[value_start:parser.index]
		}

		if parser.current == '&' {
			consume_rune(&parser.consumable) // consume '&'
		}

		if len(key_raw) > 0 || len(value_raw) > 0 {
			key_decoded := decode_query_component(key_raw, parser.allocator)
			value_decoded := decode_query_component(value_raw, parser.allocator)

			append(&parser.params, Query_Param{key = key_decoded, value = value_decoded})
		}
	}

	return parser.params, parser.errors[:]
}


@(private)
is_hex :: proc(c: byte) -> bool {
	return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

@(private)
hex_to_byte :: proc(c: byte) -> byte {
	if c >= '0' && c <= '9' {
		return c - '0'
	}
	if c >= 'a' && c <= 'f' {
		return c - 'a' + 10
	}
	if c >= 'A' && c <= 'F' {
		return c - 'A' + 10
	}
	return 0
}

@(private)
decode_query_component :: proc(s: string, allocator := context.allocator) -> string {
	if len(s) == 0 {
		return ""
	}

	b := strings.builder_make_none(allocator)
	strings.builder_grow(&b, len(s))

	i := 0
	for i < len(s) {
		if s[i] == '+' {
			strings.write_byte(&b, ' ')
			i += 1
		} else if s[i] == '%' && i + 2 < len(s) && is_hex(s[i + 1]) && is_hex(s[i + 2]) {
			high := hex_to_byte(s[i + 1])
			low := hex_to_byte(s[i + 2])
			strings.write_byte(&b, (high << 4) | low)
			i += 3
		} else {
			strings.write_byte(&b, s[i])
			i += 1
		}
	}

	return strings.to_string(b)
}

append_param :: proc(params: ^[dynamic]Query_Param, key: string, value: string) {
	append(params, Query_Param{key = key, value = value})
}

get :: proc(params: []Query_Param, key: string) -> (string, bool) {
	for p in params {
		if p.key == key {
			return p.value, true
		}
	}
	return "", false
}

get_all :: proc(
	params: []Query_Param,
	key: string,
	allocator := context.allocator,
) -> [dynamic]string {
	res := make([dynamic]string, allocator)
	for p in params {
		if p.key == key {
			append(&res, p.value)
		}
	}
	return res
}

query_params_to_string :: proc(params: []Query_Param, allocator := context.allocator) -> string {
	if len(params) == 0 {
		return ""
	}

	b := strings.builder_make_none(allocator)

	for i := 0; i < len(params); i += 1 {
		p := params[i]
		if i > 0 {
			strings.write_byte(&b, '&')
		}
		write_encoded_query_component(&b, p.key)
		strings.write_byte(&b, '=')
		write_encoded_query_component(&b, p.value)
	}

	return strings.to_string(b)
}

@(private)
write_encoded_query_component :: proc(b: ^strings.Builder, s: string) {
	for i := 0; i < len(s); i += 1 {
		c := s[i]
		switch c {
		case 'a' ..= 'z', 'A' ..= 'Z', '0' ..= '9', '-', '_', '.', '~':
			strings.write_byte(b, c)
		case ' ':
			strings.write_byte(b, '+')
		case:
			strings.write_byte(b, '%')
			hex := "0123456789ABCDEF"
			strings.write_byte(b, hex[c >> 4])
			strings.write_byte(b, hex[c & 15])
		}
	}
}
