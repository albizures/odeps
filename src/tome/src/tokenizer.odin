package tome

import "core:unicode/utf8"

CUTSET :: "\n"

Span :: struct {
	start, end: int,
}

Tokenizer :: struct {
	data:    string,
	current: rune,
	index:   int,
	width:   int,
}

Token :: struct {
	using span: Span,
	kind:       Token_Kind,
}

Token_Kind :: enum {
	// special
	Invalid,
	EOF,
	Comment,

	// values
	False,
	True,
	Nil,
	Integer,
	Float,
	String,

	// syntax
	Equal,
	Comma,
	Open_Brace,
	Close_Brace,
	Open_Bracket,
	Close_Bracket,

	// other
	Ident,
}

is_letter :: proc(r: rune) -> bool {
	c := u8(r)
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

is_number :: proc(r: rune) -> bool {
	c := u8(r)
	return c >= '0' && c <= '9'
}

make_tokenizer :: proc(data: string) -> Tokenizer {
	t := Tokenizer {
		data = data,
	}

	consume_rune(&t)

	return t
}


get_token :: proc(t: ^Tokenizer, loc := #caller_location) -> (token: Token) {
	switch t.current {
	case 'A' ..= 'Z', 'a' ..= 'z', '_':
		token.start = t.index
		consume_ident(t)
		token.end = t.index
		value := t.data[token.start:token.end]

		if value == "true" {
			token.kind = .True
		} else if value == "false" {
			token.kind = .False
		} else if value == "nil" {
			token.kind = .Nil
		} else {
			token.kind = .Ident
		}
	case '0' ..= '9':
		token.start = t.index
		token.kind = consume_number(t)
		token.end = t.index
	case '"':
		token.start = t.index
		value := consume_string(t)
		token.end = t.index
		token.kind = .String
	case '\n', ' ', '\t', '\r':
		consume_rune(t)
		// maybe it would be better to ignore whitespace in the beginning
		return get_token(t)
	case '#':
		token.start = t.index
		token.kind = .Comment
		consume_comment(t)
		token.end = t.index
	case:
		token.start = t.index
		token.kind = get_kind(t.current)
		consume_rune(t)
		token.end = t.index
	}

	return
}

get_kind :: proc(r: rune) -> Token_Kind {
	switch r {
	case utf8.RUNE_EOF:
		return .EOF
	case ',':
		return .Comma
	case '{':
		return .Open_Brace
	case '}':
		return .Close_Brace
	case '[':
		return .Open_Bracket
	case ']':
		return .Close_Bracket
	case '=':
		return .Equal
	case:
		return .Invalid
	}
}

@(private)
consume_comment :: proc(t: ^Tokenizer) {
	for t.current != '\n' && t.current != utf8.RUNE_EOF {
		consume_rune(t)
	}
}

@(private)
consume_rune :: proc(t: ^Tokenizer) -> rune #no_bounds_check {
	if t.index >= len(t.data) {
		t.current = utf8.RUNE_EOF
		t.index = len(t.data)
	} else {
		t.index += t.width
		t.current, t.width = utf8.decode_rune_in_string(t.data[t.index:])
		if t.index >= len(t.data) {
			t.current = utf8.RUNE_EOF
		}
	}
	return t.current
}

@(private)
consume_ident :: proc(t: ^Tokenizer) {
	for is_letter(t.current) || is_number(t.current) || t.current == '_' {
		consume_rune(t)
	}
}

@(private)
consume_string :: proc(t: ^Tokenizer) -> string {
	quote := t.current
	consume_rune(t)
	start := t.index
	end := t.index
	for t.current != utf8.RUNE_EOF {
		r := t.current
		end = t.index
		consume_rune(t)
		if r < 0 {
			// just considering the string as finished
			break
		}
		if r == quote {
			break
		}
		if r == '\\' {
			scan_escape(t)
		}
	}

	return string(t.data[start:end])
}

@(private)
consume_number :: proc(t: ^Tokenizer) -> Token_Kind {
	with_decimal_point := false

	loop: for t.current != utf8.RUNE_EOF {
		switch consume_rune(t) {
		case '0' ..= '9':
		// okay
		case '.':
			assert(!with_decimal_point, "already has a decimal point")
			with_decimal_point = true
			continue
		case:
			break loop
		}
	}

	return .Float if with_decimal_point else .Integer
}

@(private)
scan_escape :: proc(t: ^Tokenizer) -> bool {
	switch t.current {
	case '"', '\'', '\\', '/', 'b', 'n', 'r', 't', 'f':
		consume_rune(t)
		return true
	case 'u':
		// Expect 4 hexadecimal digits
		for i := 0; i < 4; i += 1 {
			r := consume_rune(t)
			switch r {
			case '0' ..= '9', 'a' ..= 'f', 'A' ..= 'F':
			// Okay
			case:
				return false
			}
		}
		return true
	case:
		// Ignore the next rune regardless
		consume_rune(t)
	}
	return false
}


get_span_value :: proc(t: Tokenizer, token: Token) -> string {
	return t.data[token.start:token.end]
}
