package url_core

import "core:strings"
import "core:unicode/utf8"

Url_Step :: enum {
	Protocol,
	User_Info,
	Domain,
	Port,
	Path,
	Query,
	Fragment,
}

Url_Error :: enum {
	Invalid,
}

Consumable_Rune :: struct {
	index:   int,
	data:    string,
	width:   int,
	current: rune,
}

Url_Parser :: struct {
	using consumable: Consumable_Rune,
	last_step_index:  int,
	step:             Url_Step,
	url:              Url,
	errors:           [dynamic]Url_Error,
}


Url :: struct {
	protocol:  string,
	user_info: string,
	domain:    string,
	port:      string,
	path:      string,
	query:     string,
	fragment:  string,
	host:      string,
	origin:    string,
}


parse_url :: proc(url: string, allocator := context.allocator) -> (Url, []Url_Error) {
	// 	// Parse the URL and return the domain
	// 	// return "example.com"
	parser: Url_Parser = {
		consumable = {data = url},
		step = .Protocol,
		errors = make([dynamic]Url_Error, allocator),
	}

	consume_rune(&parser.consumable)
	parse_next(&parser)

	return parser.url, parser.errors[:]
}


url_to_string :: proc(url: Url, allocator := context.allocator) -> string {
	b := strings.builder_make(allocator)

	if url.protocol != "" {
		strings.write_string(&b, url.protocol)
		strings.write_string(&b, "://")
	}

	if url.user_info != "" {
		strings.write_string(&b, url.user_info)
		strings.write_byte(&b, '@')
	}

	strings.write_string(&b, url.domain)

	if url.port != "" {
		strings.write_byte(&b, ':')
		strings.write_string(&b, url.port)
	}

	strings.write_string(&b, url.path)

	if url.query != "" {
		strings.write_byte(&b, '?')
		strings.write_string(&b, url.query)
	}

	if url.fragment != "" {
		strings.write_byte(&b, '#')
		strings.write_string(&b, url.fragment)
	}

	return strings.to_string(b)
}

@(private)
parse_next :: proc(parser: ^Url_Parser) {
	parse_protocol(parser)
	parse_authority(parser)
	parse_path(parser)
	parse_query(parser)
	parse_fragment(parser)
}

@(private)
parse_protocol :: proc(p: ^Url_Parser) {
	for p.current != utf8.RUNE_EOF {
		if p.current == ':' {
			end := p.index
			parse_protocol_separator(p)
			p.url.protocol = p.data[p.last_step_index:end]
			p.last_step_index = p.index
			break
		} else {
			consume_rune(&p.consumable)
		}
	}
}

@(private)
parse_protocol_separator :: proc(p: ^Url_Parser) {
	expect_rune(p, ':', .Invalid, consume = true)
	expect_rune(p, '/', .Invalid, consume = true)
	expect_rune(p, '/', .Invalid, consume = true)
}

@(private)
parse_authority :: proc(p: ^Url_Parser) {
	// Need to check for user_info: user:pass@
	// To do this, we can scan ahead or just collect until '@' or '/' or '?' or '#'
	// If we hit '@', we know the previous part was user_info.
	start_idx := p.index
	has_at := false
	at_idx := -1

	// Scan ahead to see if user_info exists in authority (look for '@').
	// We use a manual, consumable lookahead here instead of consume_rune()
	// to avoid mutating the parser state, which would require rewinding
	// if the authority turns out to just be a domain without user_info.
	lookahead := p.consumable

	for lookahead.current != utf8.RUNE_EOF &&
	    lookahead.current != '/' &&
	    lookahead.current != '?' &&
	    lookahead.current != '#' {

		if lookahead.current == '@' {
			has_at = true
			at_idx = lookahead.index
			break
		}
		consume_rune(&lookahead)
	}

	if has_at {
		// we have user_info
		for p.index < at_idx {
			consume_rune(&p.consumable)
		}
		p.url.user_info = p.data[start_idx:at_idx]
		consume_rune(&p.consumable) // consume '@'
		p.last_step_index = p.index
	}

	parse_domain_and_port(p)
}

@(private)
parse_domain_and_port :: proc(p: ^Url_Parser) {
	start_idx := p.index
	has_port := false
	for p.current != utf8.RUNE_EOF && p.current != '/' && p.current != '?' && p.current != '#' {
		if p.current == ':' {
			has_port = true
			p.url.domain = p.data[start_idx:p.index]
			consume_rune(&p.consumable) // consume ':'
			start_idx = p.index
			break
		}
		consume_rune(&p.consumable)
	}

	if !has_port {
		p.url.domain = p.data[start_idx:p.index]
	} else {
		// port parsing
		for p.current != utf8.RUNE_EOF &&
		    p.current != '/' &&
		    p.current != '?' &&
		    p.current != '#' {
			consume_rune(&p.consumable)
		}
		p.url.port = p.data[start_idx:p.index]
	}
	p.last_step_index = p.index
}

@(private)
parse_path :: proc(p: ^Url_Parser) {
	start_idx := p.index
	for p.current != utf8.RUNE_EOF && p.current != '?' && p.current != '#' {
		consume_rune(&p.consumable)
	}
	p.url.path = p.data[start_idx:p.index]
	p.last_step_index = p.index
}

@(private)
parse_query :: proc(p: ^Url_Parser) {
	if p.current == '?' {
		consume_rune(&p.consumable) // consume '?'
		start_idx := p.index
		for p.current != utf8.RUNE_EOF && p.current != '#' {
			consume_rune(&p.consumable)
		}
		p.url.query = p.data[start_idx:p.index]
		p.last_step_index = p.index
	}
}

@(private)
parse_fragment :: proc(p: ^Url_Parser) {
	if p.current == '#' {
		consume_rune(&p.consumable) // consume '#'
		start_idx := p.index
		for p.current != utf8.RUNE_EOF {
			consume_rune(&p.consumable)
		}
		p.url.fragment = p.data[start_idx:p.index]
		p.last_step_index = p.index
	}
}

@(private)
expect_rune :: proc(p: ^Url_Parser, r: rune, error: Url_Error, consume := false) {
	if p.current != r {
		append(&p.errors, error)
	}

	if consume {
		consume_rune(&p.consumable)
	}
}

@(private)
consume_rune :: proc(c: ^Consumable_Rune) -> rune #no_bounds_check {
	if c.index >= len(c.data) {
		c.current = utf8.RUNE_EOF
		c.index = len(c.data)
	} else {
		c.index += c.width
		c.current, c.width = utf8.decode_rune_in_string(c.data[c.index:])
		if c.index >= len(c.data) {
			c.current = utf8.RUNE_EOF
		}
	}
	return c.current
}
