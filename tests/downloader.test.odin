package downloader_tests

import "../src/github"
import "core:testing"

@(test)
test_parse_github_contents :: proc(t: ^testing.T) {
	mock_json := `[
		{
			"name": "README.md",
			"type": "file",
			"download_url": "https://raw.githubusercontent.com/user/repo/main/README.md"
		},
		{
			"name": "src",
			"type": "dir",
			"url": "https://api.github.com/repos/user/repo/contents/src"
		}
	]`

	items, err := github.parse_github_contents(mock_json, context.temp_allocator)
	testing.expect_value(t, err, github.Github_Parse_Error.None)
	testing.expect_value(t, len(items), 2)

	testing.expect_value(t, items[0].name, "README.md")
	testing.expect_value(t, items[0].type, github.Github_Content_Type.File)
	testing.expect_value(
		t,
		items[0].download_url,
		"https://raw.githubusercontent.com/user/repo/main/README.md",
	)

	testing.expect_value(t, items[1].name, "src")
	testing.expect_value(t, items[1].type, github.Github_Content_Type.Dir)
	testing.expect_value(t, items[1].url, "https://api.github.com/repos/user/repo/contents/src")
}

@(test)
test_parse_github_contents_invalid_json :: proc(t: ^testing.T) {
	mock_json := `invalid json`
	_, err := github.parse_github_contents(mock_json, context.temp_allocator)
	testing.expect_value(t, err, github.Github_Parse_Error.Invalid_JSON)
}

@(test)
test_parse_github_contents_not_an_array :: proc(t: ^testing.T) {
	mock_json := `{"name": "test"}`
	_, err := github.parse_github_contents(mock_json, context.temp_allocator)
	testing.expect_value(t, err, github.Github_Parse_Error.Not_An_Array)
}
