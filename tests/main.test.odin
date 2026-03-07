package downloader_tests

import "../src/github"
import "core:strings"
import "core:testing"

@(test)
test_get_contents_url :: proc(t: ^testing.T) {
	defer free_all(context.temp_allocator)

	// Case 1: Base repo
	{
		url := "https://github.com/odin-lang/Odin"
		commit := "123456"
		expected := "https://api.github.com/repos/odin-lang/Odin/contents/?ref=123456"
		actual, ok := github.get_contents_url(url, commit)
		testing.expect(t, ok, "get_contents_url failed for base repo")
		testing.expect_value(t, actual, expected)
	}

	// Case 2: Deep path
	{
		url := "https://github.com/odin-lang/Odin/tree/master/core/os"
		commit := "abcdef"
		expected := "https://api.github.com/repos/odin-lang/Odin/contents/core/os?ref=abcdef"
		actual, ok := github.get_contents_url(url, commit)
		testing.expect(t, ok, "get_contents_url failed for deep path")
		testing.expect_value(t, actual, expected)
	}

	// Case 3: Invalid URL
	{
		url := "https://github.com/odin-lang"
		commit := "123456"
		_, ok := github.get_contents_url(url, commit)
		testing.expect(t, !ok, "get_contents_url should fail for invalid URL")
	}
}

@(test)
test_is_folder :: proc(t: ^testing.T) {
	defer free_all(context.temp_allocator)

	// Case 1: Valid repo root
	testing.expect(t, github.is_folder("https://github.com/odin-lang/Odin"), "Should be a folder")

	// Case 2: Valid subfolder
	testing.expect(
		t,
		github.is_folder("https://github.com/odin-lang/Odin/tree/master/core"),
		"Should be a folder",
	)

	// Case 3: Non-GitHub URL
	testing.expect(
		t,
		!github.is_folder("https://google.com/odin-lang/Odin"),
		"Should not be a GitHub folder",
	)

	// Case 4: Invalid GitHub URL (too short)
	testing.expect(
		t,
		!github.is_folder("https://github.com/odin-lang"),
		"Should not be a folder (missing repo)",
	)
}

@(test)
test_convert_link_to_api :: proc(t: ^testing.T) {
	defer free_all(context.temp_allocator)

	// Case 1: Base repo
	{
		url := "https://github.com/odin-lang/Odin"
		expected := "https://api.github.com/repos/odin-lang/Odin/commits?per_page=1"
		actual, ok := github.convert_link_to_api(url)
		testing.expect(t, ok, "convert_link_to_api failed for base repo")
		testing.expect_value(t, actual, expected)
	}

	// Case 2: With branch and path
	{
		url := "https://github.com/odin-lang/Odin/tree/dev/core/fmt"
		expected := "https://api.github.com/repos/odin-lang/Odin/commits?path=core%2Ffmt&sha=dev&per_page=1"
		actual, ok := github.convert_link_to_api(url)
		testing.expect(t, ok, "convert_link_to_api failed for branch/path")
		testing.expect_value(t, actual, expected)
	}
}
