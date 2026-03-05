package url_tests

import "../src"
import "core:testing"

@(test)
test_url_parsing_complex :: proc(t: ^testing.T) {
	url, errors := src.parse_url(
		"https://user:pass@example.com:443/out/in?q=1#top",
		context.temp_allocator,
	)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	testing.expect_value(t, url.protocol, "https")
	testing.expect_value(t, url.user_info, "user:pass")
	testing.expect_value(t, url.domain, "example.com")
	testing.expect_value(t, url.port, "443")
	testing.expect_value(t, url.path, "/out/in")
	testing.expect_value(t, url.query, "q=1")
	testing.expect_value(t, url.fragment, "top")
}

@(test)
test_url_to_string :: proc(t: ^testing.T) {
	defer free_all(context.temp_allocator)
	url, _ := src.parse_url(
		"https://user:pass@example.com:443/out/in?q=1#top",
		context.temp_allocator,
	)
	str := src.url_to_string(url, context.temp_allocator)
	testing.expect_value(t, str, "https://user:pass@example.com:443/out/in?q=1#top")

	url2, _ := src.parse_url("http://example.com", context.temp_allocator)
	str2 := src.url_to_string(url2, context.temp_allocator)
	testing.expect_value(t, str2, "http://example.com")


}

@(test)
test_url_parsing_simple :: proc(t: ^testing.T) {
	url, errors := src.parse_url("http://example.com", context.temp_allocator)
	defer free_all(context.temp_allocator)

	testing.expect_value(t, len(errors), 0)
	testing.expect_value(t, url.protocol, "http")
	testing.expect_value(t, url.user_info, "")
	testing.expect_value(t, url.domain, "example.com")
	testing.expect_value(t, url.port, "")
	testing.expect_value(t, url.path, "")
	testing.expect_value(t, url.query, "")
	testing.expect_value(t, url.fragment, "")
}
