package tome_tests

import tome "../src"
import "core:log"
import "core:testing"
import "core:unicode/utf8"


assert_token :: proc(
	t: ^testing.T,
	tokenizer: ^tome.Tokenizer,
	kind: tome.Token_Kind,
	value: string,
	span: tome.Span,
	loc := #caller_location,
) {
	token := tome.get_token(tokenizer)
	if token.kind == .EOF {
		testing.expect_value(t, value, "")
	} else {
		testing.expect_value(t, tome.get_span_value(tokenizer^, token), value, loc = loc)
	}

	testing.expect_value(t, token, tome.Token{kind = kind, span = span}, loc = loc)
}

@(test)
tokenize_int :: proc(t: ^testing.T) {
	value := "test=123"
	tokenizer := tome.make_tokenizer("test=123")
	assert_token(t, &tokenizer, .Ident, "test", {0, 4})
	assert_token(t, &tokenizer, .Equal, "=", {4, 5})
	assert_token(t, &tokenizer, .Integer, "123", {5, 8})
	assert_token(t, &tokenizer, .EOF, "", {8, 8})
}

@(test)
tokenize_decimal :: proc(t: ^testing.T) {
	tokenizer := tome.make_tokenizer("test=123.45")

	assert_token(t, &tokenizer, .Ident, "test", span = {0, 4})
	assert_token(t, &tokenizer, .Equal, "=", span = {4, 5})
	assert_token(t, &tokenizer, .Float, "123.45", span = {5, 11})
	assert_token(t, &tokenizer, .EOF, "", span = {11, 11})
}

@(test)
tokenize_bool :: proc(t: ^testing.T) {
	tokenizer := tome.make_tokenizer("test=true")

	assert_token(t, &tokenizer, .Ident, "test", span = {0, 4})
	assert_token(t, &tokenizer, .Equal, "=", span = {4, 5})
	assert_token(t, &tokenizer, .True, "true", span = {5, 9})
	assert_token(t, &tokenizer, .EOF, "", span = {9, 9})
}


@(test)
tokenize_multiline :: proc(t: ^testing.T) {
	tokenizer := tome.make_tokenizer(`test="
123
345
"
`)

	assert_token(t, &tokenizer, .Ident, "test", {0, 4})
	assert_token(t, &tokenizer, .Equal, "=", {4, 5})
	assert_token(t, &tokenizer, .String, "\"\n123\n345\n\"", {5, 16})
	assert_token(t, &tokenizer, .EOF, "", {17, 17})
}


@(test)
tokenize_escaping :: proc(t: ^testing.T) {
	tokenizer := tome.make_tokenizer(`test="\
\"123\"
345\
"
`)

	assert_token(t, &tokenizer, .Ident, "test", {0, 4})
	assert_token(t, &tokenizer, .Equal, "=", {4, 5})
	assert_token(t, &tokenizer, .String, `"\
\"123\"
345\
"`, {5, 22})
	assert_token(t, &tokenizer, .EOF, "", {23, 23})
}

@(test)
tokenize_comment :: proc(t: ^testing.T) {
	tokenizer := tome.make_tokenizer(`test="\
123
345\
"
# comment
`)

	assert_token(t, &tokenizer, .Ident, "test", {0, 4})
	assert_token(t, &tokenizer, .Equal, "=", {4, 5})
	assert_token(t, &tokenizer, .String, `"\
123
345\
"`, {5, 18})
	assert_token(t, &tokenizer, .Comment, "# comment", {19, 28})
	assert_token(t, &tokenizer, .EOF, "", {29, 29})
}


@(test)
tokenize_array :: proc(t: ^testing.T) {
	tokenizer := tome.make_tokenizer(`test=[
123,
345,
]
`)

	assert_token(t, &tokenizer, .Ident, "test", {0, 4})
	assert_token(t, &tokenizer, .Equal, "=", {4, 5})
	assert_token(t, &tokenizer, .Open_Bracket, "[", {5, 6})
	assert_token(t, &tokenizer, .Integer, "123", {7, 10})
	assert_token(t, &tokenizer, .Comma, ",", {10, 11})
	assert_token(t, &tokenizer, .Integer, "345", {12, 15})
	assert_token(t, &tokenizer, .Comma, ",", {15, 16})
	assert_token(t, &tokenizer, .Close_Bracket, "]", {17, 18})
	assert_token(t, &tokenizer, .EOF, "", {19, 19})
}

@(test)
tokenize_object :: proc(t: ^testing.T) {
	tokenizer := tome.make_tokenizer(`test={
name = 123,
value = 345
}
`)

	assert_token(t, &tokenizer, .Ident, "test", {0, 4})
	assert_token(t, &tokenizer, .Equal, "=", {4, 5})
	assert_token(t, &tokenizer, .Open_Brace, "{", {5, 6})
	assert_token(t, &tokenizer, .Ident, "name", {7, 11})
	assert_token(t, &tokenizer, .Equal, "=", {12, 13})
	assert_token(t, &tokenizer, .Integer, "123", {14, 17})
	assert_token(t, &tokenizer, .Comma, ",", {17, 18})
	assert_token(t, &tokenizer, .Ident, "value", {19, 24})
	assert_token(t, &tokenizer, .Equal, "=", {25, 26})
	assert_token(t, &tokenizer, .Integer, "345", {27, 30})
	assert_token(t, &tokenizer, .Close_Brace, "}", {31, 32})
	assert_token(t, &tokenizer, .EOF, "", {33, 33})
}
