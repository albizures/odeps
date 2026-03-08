package tome_tests

import tome "../src"
import "core:log"
import "core:strings"
import "core:testing"

@(test)
test_serialize_basic :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	doc["test"] = tome.Integer(123)

	result := tome.serialize(doc, context.temp_allocator)

	testing.expect_value(t, result, "test=123")
}

@(test)
test_serialize_float :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	doc["test"] = tome.Float(123.4)

	result := tome.serialize(doc, context.temp_allocator)

	testing.expect_value(t, result, "test=123.400")
}

@(test)
test_serialize_string :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	doc["test"] = tome.String("hello")

	result := tome.serialize(doc, context.temp_allocator)

	testing.expect_value(t, result, "test=\"hello\"")
}

@(test)
test_serialize_null :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	doc["test"] = tome.Nil{}

	result := tome.serialize(doc, context.temp_allocator)

	testing.expect_value(t, result, "test=nil")
}

@(test)
test_serialize_bool :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	doc["test"] = tome.Bool(true)

	result := tome.serialize(doc, context.temp_allocator)

	testing.expect_value(t, result, "test=true")
}

@(test)
test_serialize_array :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	arr := make(tome.Array, context.temp_allocator)
	append(&arr, tome.Integer(1))
	append(&arr, tome.Integer(2))
	append(&arr, tome.Integer(3))
	doc["test"] = arr

	result := tome.serialize(doc, context.temp_allocator)

	testing.expect_value(t, result, "test=[1, 2, 3]")
}

@(test)
test_serialize_object :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	obj := make(tome.Object, context.temp_allocator)
	obj["a"] = tome.Integer(1)
	obj["b"] = tome.Integer(2)
	doc["test"] = obj

	result := tome.serialize(doc, context.temp_allocator)

	testing.expect(t, result == "test={a=1, b=2}" || result == "test={b=2, a=1}")
}


@(test)
test_serialize_multiple_root_keys :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	doc["key1"] = tome.Integer(1)
	doc["key2"] = tome.Integer(2)

	result := tome.serialize(doc, context.temp_allocator)

	testing.expect(t, result == "key1=1,\nkey2=2" || result == "key2=2,\nkey1=1")
}

@(test)
test_serialize_multiline_array :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	arr := make(tome.Array, context.temp_allocator)
	for i in 1 ..= 6 {
		append(&arr, tome.Integer(i))
	}
	doc["test"] = arr

	result := tome.serialize(doc, context.temp_allocator)

	expected := "test=[\n\t1,\n\t2,\n\t3,\n\t4,\n\t5,\n\t6,\n]"

	testing.expect_value(t, result, expected)
}

@(test)
test_serialize_multiline_object :: proc(t: ^testing.T) {
	doc := make(tome.Object, context.temp_allocator)
	obj := make(tome.Object, context.temp_allocator)
	obj["a"] = tome.Integer(1)
	obj["b"] = tome.Integer(2)
	obj["c"] = tome.Integer(3)
	obj["d"] = tome.Integer(4)
	doc["test"] = obj

	options := tome.DEFAULT_SERIALIZE_OPTIONS
	options.indent_type = .Spaces
	options.indent_count = 2

	result := tome.serialize(doc, context.temp_allocator, options)

	// Since order of maps is not guaranteed, check if it starts and ends correctly and contains the parts
	testing.expect(t, strings.has_prefix(result, "test={\n"))
	testing.expect(t, strings.has_suffix(result, "}"))
	testing.expect(t, strings.contains(result, "  a=1,\n"))
	testing.expect(t, strings.contains(result, "  b=2,\n"))
	testing.expect(t, strings.contains(result, "  c=3,\n"))
	testing.expect(t, strings.contains(result, "  d=4,\n"))
}
