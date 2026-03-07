package tome_tests

import tome "../src"
import "core:log"
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
