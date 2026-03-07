package tome_tests

import tome "../src"
import "core:log"
import "core:testing"


@(test)
test_parse_int :: proc(t: ^testing.T) {
	value, errors := tome.parse("test=123", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	testing.expect_value(t, value["test"].(tome.Integer), 123)
}

@(test)
test_parse_float :: proc(t: ^testing.T) {
	value, errors := tome.parse("test=123.4", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	testing.expect_value(t, value["test"].(tome.Float), 123.4)
}

@(test)
test_parse_string :: proc(t: ^testing.T) {
	value, errors := tome.parse("test=\"hello\"", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	testing.expect_value(t, value["test"].(tome.String), "hello")
}

@(test)
test_parse_null :: proc(t: ^testing.T) {
	value, errors := tome.parse("test=nil", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	_, is_null := value["test"].(tome.Nil)
	testing.expect(t, is_null)
}


@(test)
test_parse_bool :: proc(t: ^testing.T) {
	value, errors := tome.parse("test=true", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	testing.expect_value(t, value["test"].(tome.Bool), true)
}

@(test)
test_parse_bool_false :: proc(t: ^testing.T) {
	value, errors := tome.parse("test=false", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	testing.expect_value(t, value["test"].(tome.Bool), false)
}

@(test)
test_parse_array :: proc(t: ^testing.T) {
	value, errors := tome.parse("test=[1, 2, 3]", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	arr, is_array := value["test"].(tome.Array)

	testing.expect(t, is_array)
	testing.expect_value(t, len(arr), 3)
	testing.expect_value(t, arr[0].(tome.Integer), 1)
	testing.expect_value(t, arr[1].(tome.Integer), 2)
	testing.expect_value(t, arr[2].(tome.Integer), 3)
}

@(test)
test_parse_object :: proc(t: ^testing.T) {
	value, errors := tome.parse("test={a = 1, b = 2}", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	obj, is_object := value["test"].(tome.Object)

	testing.expect(t, is_object)
	testing.expect_value(t, obj["a"].(tome.Integer), 1)
	testing.expect_value(t, obj["b"].(tome.Integer), 2)
}

@(test)
test_parse_array_of_objects :: proc(t: ^testing.T) {
	value, errors := tome.parse("test=[{a = 1}, {b = 2}]", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)

	testing.expect_value(t, value["test"].(tome.Array)[0].(tome.Object)["a"].(tome.Integer), 1)
	testing.expect_value(t, value["test"].(tome.Array)[1].(tome.Object)["b"].(tome.Integer), 2)
}

@(test)
test_parse_object_with_array :: proc(t: ^testing.T) {
	value, errors := tome.parse("test={a = [1, 2], b = 3}", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	testing.expect_value(t, value["test"].(tome.Object)["a"].(tome.Array)[0].(tome.Integer), 1)
	testing.expect_value(t, value["test"].(tome.Object)["a"].(tome.Array)[1].(tome.Integer), 2)
	testing.expect_value(t, value["test"].(tome.Object)["b"].(tome.Integer), 3)
}

// test_parse_array_with_array :: proc(t: ^testing.T) {
// 	value, errors := tome.parse("test=[[1, 2], [3, 4]]")

// 	testing.expect_value(t, len(errors), 0)
// 	testing.expect_value(t, value["test"].(tome.Array).length(), 2)
// }

// test_parse_array_with_null :: proc(t: ^testing.T) {
// 	value, errors := tome.parse("test=[nil, 2]")

// 	testing.expect_value(t, len(errors), 0)
// 	testing.expect_value(t, value["test"].(tome.Array).length(), 2)
// }

// test_parse_array_with_bool :: proc(t: ^testing.T) {
// 	value, errors := tome.parse("test=[true, false]")

// 	testing.expect_value(t, len(errors), 0)
// 	testing.expect_value(t, value["test"].(tome.Array).length(), 2)
// }

// test_parse_array_with_string :: proc(t: ^testing.T) {
// 	value, errors := tome.parse("test=[\"hello\", \"world\"]")

// 	testing.expect_value(t, len(errors), 0)
// 	testing.expect_value(t, value["test"].(tome.Array).length(), 2)
// }

// test_parse_array_with_float :: proc(t: ^testing.T) {
// 	value, errors := tome.parse("test=[1.2, 3.4]")

// 	testing.expect_value(t, len(errors), 0)
// 	testing.expect_value(t, value["test"].(tome.Array).length(), 2)
// }

// test_parse_array_with_int :: proc(t: ^testing.T) {
// 	value, errors := tome.parse("test=[1, 2]")

// 	testing.expect_value(t, len(errors), 0)
// 	testing.expect_value(t, value["test"].(tome.Array).length(), 2)
// }
