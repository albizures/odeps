package url_tests

import "core:mem"
import "core:strings"
import "core:testing"

import "../src/url"

@(test)
test_query_parser_basic :: proc(t: ^testing.T) {
	q := "a=1&b=2"
	params, errs := url.parse_query_params(q, context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errs), 0)
	testing.expect_value(t, len(params), 2)
	testing.expect_value(t, params[0].key, "a")
	testing.expect_value(t, params[0].value, "1")
	testing.expect_value(t, params[1].key, "b")
	testing.expect_value(t, params[1].value, "2")
}

@(test)
test_query_parser_duplicate_keys :: proc(t: ^testing.T) {
	q := "a=1&a=2"
	params, errs := url.parse_query_params(q, context.temp_allocator)
	defer free_all(context.temp_allocator)
	testing.expect_value(t, len(errs), 0)
	testing.expect_value(t, len(params), 2)
	testing.expect_value(t, params[0].key, "a")
	testing.expect_value(t, params[0].value, "1")
	testing.expect_value(t, params[1].key, "a")
	testing.expect_value(t, params[1].value, "2")
}

@(test)
test_query_parser_url_encoded :: proc(t: ^testing.T) {
	q := "a=hello%20world&b=foo%2Bbar&c%2B%2B=c%2B%2B"
	params, errs := url.parse_query_params(q, context.temp_allocator)
	defer free_all(context.temp_allocator)
	testing.expect_value(t, len(errs), 0)
	testing.expect_value(t, len(params), 3)
	testing.expect_value(t, params[0].key, "a")
	testing.expect_value(t, params[0].value, "hello world")
	testing.expect_value(t, params[1].key, "b")
	testing.expect_value(t, params[1].value, "foo+bar")
	testing.expect_value(t, params[2].key, "c++")
	testing.expect_value(t, params[2].value, "c++")
}

@(test)
test_query_parser_plus_space :: proc(t: ^testing.T) {
	q := "a=hello+world"
	params, errs := url.parse_query_params(q, context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errs), 0)
	testing.expect_value(t, len(params), 1)
	testing.expect_value(t, params[0].key, "a")
	testing.expect_value(t, params[0].value, "hello world")
}

@(test)
test_query_helpers_append_and_get :: proc(t: ^testing.T) {
	params := make([dynamic]url.Query_Param, context.temp_allocator)
	defer free_all(context.temp_allocator)

	url.append(&params, "name", "odin")
	url.append(&params, "type", "language")
	url.append(&params, "tag", "fast")
	url.append(&params, "tag", "systems")

	testing.expect_value(t, len(params), 4)

	// test get (first match)
	val, ok := url.get(params[:], "name")
	testing.expect(t, ok, "should find name")
	testing.expect_value(t, val, "odin")

	val, ok = url.get(params[:], "tag")
	testing.expect(t, ok, "should find tag")
	testing.expect_value(t, val, "fast") // gets the first one

	val, ok = url.get(params[:], "missing")
	testing.expect(t, !ok, "should not find missing")
	testing.expect_value(t, val, "")

	// test get_all
	tags := url.get_all(params[:], "tag", context.temp_allocator)
	testing.expect_value(t, len(tags), 2)
	testing.expect_value(t, tags[0], "fast")
	testing.expect_value(t, tags[1], "systems")

	missing := url.get_all(params[:], "missing", context.temp_allocator)
	testing.expect_value(t, len(missing), 0)
}

@(test)
test_query_helpers_to_string :: proc(t: ^testing.T) {
	params := make([dynamic]url.Query_Param, context.temp_allocator)
	defer free_all(context.temp_allocator)

	url.append(&params, "q", "hello world") // space encodes to +
	url.append(&params, "id", "123")
	url.append(&params, "sym", "a&b=c") // special chars encode to %XX

	str := url.to_string(params[:], context.temp_allocator)
	testing.expect_value(t, str, "q=hello+world&id=123&sym=a%26b%3Dc")


}
