package tome

import "core:log"
import "core:mem"
import "core:strconv"

Nil :: distinct rawptr
Integer :: i64
Float :: f64
Bool :: bool
String :: string
Array :: distinct [dynamic]Value
Object :: distinct map[string]Value
Null :: distinct rawptr

Value :: union {
	Integer,
	Float,
	Bool,
	String,
	Array,
	Object,
	Nil,
}


Tome_Error :: enum {
	Invalid_Token,
	Invalid_Ident,
	Invalid_Value,
	Missing_Ident,
	Invalid_Int,
	Invalid_Float,
	Invalid_Bool,
	Missing_Array_Close,
	Missing_Object_Close,
	Expect_Comma,
}

Parser :: struct {
	tokenizer:  Tokenizer,
	allocator:  mem.Allocator,
	errors:     [dynamic]Tome_Error,
	result:     ^Object,
	curr_token: Token,
}

advance_token :: proc(parser: ^Parser) {
	parser.curr_token = get_token(&parser.tokenizer)
}

parse :: proc(
	input: string,
	allocator := context.allocator,
) -> (
	result: Object,
	errors: []Tome_Error,
) {
	parser := Parser {
		tokenizer = make_tokenizer(input),
		allocator = allocator,
		errors    = make([dynamic]Tome_Error, allocator),
	}

	advance_token(&parser)

	return parse_object_members(&parser), parser.errors[:]
}

parse_object_members :: proc(p: ^Parser) -> (result: Object) {
	result = make(Object, p.allocator)
	loop: for {

		#partial switch p.curr_token.kind {
		case .Invalid:
			append(&p.errors, Tome_Error.Invalid_Token)
			advance_token(p)
		case .Comment:
			advance_token(p)
		case .Ident:
			parse_ident(p, &result)
		case .EOF:
			break loop
		case:
			append(&p.errors, Tome_Error.Invalid_Token)
			advance_token(p)
		}

		if p.curr_token.kind == .Comma {
			advance_token(p) // just ignore it
		} else if p.curr_token.kind == .EOF ||
		   p.curr_token.kind == .Close_Brace ||
		   p.curr_token.kind == .Close_Bracket {
			break loop
		} else { 	// if it's not a comma nor EOF, means there is something else, meaning a comma is expected
			append(&p.errors, Tome_Error.Expect_Comma)
		}
	}

	return
}

parse_ident :: proc(p: ^Parser, result: ^Object) {
	assert(p.curr_token.kind == .Ident, "Invalid call to parse_ident")
	// let's check if the identifier is valid
	if p.curr_token.span.start - p.curr_token.span.end >= 0 {
		append(&p.errors, Tome_Error.Invalid_Ident)
		return
	}

	name := get_span_value(p.tokenizer, p.curr_token)
	log.debug("Parse ident", name)
	advance_token(p)

	// expects an equal after the identifier
	if p.curr_token.kind != .Equal {
		append(&p.errors, Tome_Error.Invalid_Token)
		// let's continue parsing
	} else {
		advance_token(p)
	}

	result[name] = parse_value(p)
}

parse_value :: proc(p: ^Parser) -> (value: Value) {
	log.debug("Parse value", p.curr_token.kind)
	str := get_current_value(p)
	#partial switch p.curr_token.kind {
	case .String:
		value = parse_string(p, str)
	case .Integer:
		value = parse_int(p, str)
	case .Float:
		value = parse_float(p, str)
	case .True, .False:
		value = parse_bool(p, str)
	case .Open_Brace:
		value = parse_object(p)
		return // parse_object already advance internallly
	case .Open_Bracket:
		value = parse_array(p)
		return // parse_object already advance internallly
	case .Nil:
		value = Nil{}
	case:
		append(&p.errors, Tome_Error.Invalid_Value)
		value = Nil{}
	}

	advance_token(p)
	return
}

parse_array :: proc(p: ^Parser) -> (array: Array) {
	log.debug("Parse array")
	array = make(Array, p.allocator)

	advance_token(p) // advance [

	if p.curr_token.kind == .Close_Bracket { 	// empty
		advance_token(p)
		return
	}


	append(&array, parse_value(p))
	for p.curr_token.kind == .Comma {
		advance_token(p)

		if p.curr_token.kind == .Close_Bracket {
			advance_token(p)
			return
		}

		append(&array, parse_value(p))

	}

	if p.curr_token.kind == .Close_Bracket {
		advance_token(p)
	} else {
		append(&p.errors, Tome_Error.Missing_Array_Close)
	}

	return
}

parse_object :: proc(p: ^Parser) -> (obj: Object) {
	log.debug("parse object")
	advance_token(p) // advance {

	if p.curr_token.kind == .Open_Brace { 	// empty
		advance_token(p)
		return
	}

	obj = parse_object_members(p)

	if p.curr_token.kind == .Close_Brace {
		advance_token(p)
	} else {
		append(&p.errors, Tome_Error.Missing_Object_Close)
	}

	return
}

parse_string :: proc(parser: ^Parser, value: string) -> string {
	return unquote(value)
}

unquote :: proc(value: string) -> string {
	// for now we don't check the string
	return value[1:len(value) - 1]
}

parse_int :: proc(parser: ^Parser, value: string) -> i64 {
	number, ok := strconv.parse_i64(value)

	if !ok {
		append(&parser.errors, Tome_Error.Invalid_Int)
	}

	return number
}

parse_float :: proc(parser: ^Parser, value: string) -> f64 {
	number, ok := strconv.parse_f64(value)

	if !ok {
		append(&parser.errors, Tome_Error.Invalid_Float)
	}

	return number
}

parse_bool :: proc(parser: ^Parser, value: string) -> bool {
	if value == "true" {
		return true
	} else if value == "false" {
		return false
	}

	append(&parser.errors, Tome_Error.Invalid_Bool)
	return false
}


get_current_value :: proc(p: ^Parser) -> string {
	return get_span_value(p.tokenizer, p.curr_token)
}
