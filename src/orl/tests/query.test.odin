package url_tests

import "../src"
import "core:mem"
import "core:strings"
import "core:testing"

@(test)
test_query_parser_basic :: proc(t: ^testing.T) {
	q := "a=1&b=2"
	params, errs := src.parse_query_params(q, context.temp_allocator)
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
	params, errs := src.parse_query_params(q, context.temp_allocator)
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
	params, errs := src.parse_query_params(q, context.temp_allocator)
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
	params, errs := src.parse_query_params(q, context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errs), 0)
	testing.expect_value(t, len(params), 1)
	testing.expect_value(t, params[0].key, "a")
	testing.expect_value(t, params[0].value, "hello world")
}

@(test)
test_query_helpers_append_and_get :: proc(t: ^testing.T) {
	params := make([dynamic]src.Query_Param, context.temp_allocator)
	defer free_all(context.temp_allocator)

	src.append_param(&params, "name", "odin")
	src.append_param(&params, "type", "language")
	src.append_param(&params, "tag", "fast")
	src.append_param(&params, "tag", "systems")

	testing.expect_value(t, len(params), 4)

	// test get (first match)
	val, ok := src.get(params[:], "name")
	testing.expect(t, ok, "should find name")
	testing.expect_value(t, val, "odin")

	val, ok = src.get(params[:], "tag")
	testing.expect(t, ok, "should find tag")
	testing.expect_value(t, val, "fast") // gets the first one

	val, ok = src.get(params[:], "missing")
	testing.expect(t, !ok, "should not find missing")
	testing.expect_value(t, val, "")

	// test get_all
	tags := src.get_all(params[:], "tag", context.temp_allocator)
	testing.expect_value(t, len(tags), 2)
	testing.expect_value(t, tags[0], "fast")
	testing.expect_value(t, tags[1], "systems")

	missing := src.get_all(params[:], "missing", context.temp_allocator)
	testing.expect_value(t, len(missing), 0)
}

@(test)
test_query_helpers_to_string :: proc(t: ^testing.T) {
	params := make([dynamic]src.Query_Param, context.temp_allocator)
	defer free_all(context.temp_allocator)

	src.append_param(&params, "q", "hello world") // space encodes to +
	src.append_param(&params, "id", "123")
	src.append_param(&params, "sym", "a&b=c") // special chars encode to %XX

	str := src.query_params_to_string(params[:], context.temp_allocator)
	testing.expect_value(t, str, "q=hello+world&id=123&sym=a%26b%3Dc")


}
