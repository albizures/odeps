package odeps_core

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:strings"
import "orl"
import "vendor:curl"

get_contents_url :: proc(raw_url: string, commit: string) -> (string, bool) {
	url, _ := orl.parse_url(raw_url)
	parts := strings.split(url.path, "/", context.temp_allocator)

	if len(parts) < 3 {
		return "", false
	}

	user := parts[1]
	repo := parts[2]
	file_path := ""

	if len(parts) >= 5 && parts[3] == "tree" {
		if len(parts) > 5 {
			file_path = strings.join(parts[5:], "/", context.temp_allocator)
		}
	}

	api_url := fmt.tprintf(
		"https://api.github.com/repos/%s/%s/contents/%s?ref=%s",
		user,
		repo,
		file_path,
		commit,
	)

	return api_url, true
}

is_folder :: proc(url: string) -> bool {
	parsed, errs := orl.parse_url(url)
	if len(errs) > 0 {
		return false
	}

	if !strings.contains(parsed.domain, "github.com") {
		return false
	}

	parts := strings.split(parsed.path, "/", context.temp_allocator)
	// Example parts for repo root: ["", "user", "repo"] - length 3
	// Example parts for folder: ["", "user", "repo", "tree", "branch", "path"] - length >= 5
	return len(parts) >= 3
}

Curl_Data :: struct {
	b:   ^strings.Builder,
	ctx: runtime.Context,
}

write_callback :: proc "c" (
	ptr: rawptr,
	size: c.size_t,
	nmemb: c.size_t,
	userdata: rawptr,
) -> c.size_t {
	data := cast(^Curl_Data)userdata
	context = data.ctx

	real_size := size * nmemb
	slice := (cast([^]byte)ptr)[:real_size]
	strings.write_bytes(data.b, slice)

	return real_size
}

// find out what's the commit of a given link, by using github api
// ref: curl -s "https://api.github.com/repos/[User]/[Repo]/commits?path=[Path_to_File]&sha=master&per_page=1" | grep '"sha"' | head -n 1
get_commit :: proc(raw_url: string, allocator := context.allocator) -> (string, bool) {
	api_url, ok := convert_link_to_api(raw_url)
	defer free_all(context.temp_allocator)

	if !ok {
		fmt.eprintln("Unable to get commit")
		return "", false
	}


	h := curl.easy_init()
	if h == nil {
		fmt.eprintln("Unable to initialize curl")
		return "", false
	}
	defer curl.easy_cleanup(h)

	b := strings.builder_make(allocator)
	data := Curl_Data{&b, context}

	curl.easy_setopt(h, .URL, strings.clone_to_cstring(api_url, context.temp_allocator))
	curl.easy_setopt(h, .WRITEFUNCTION, write_callback)
	curl.easy_setopt(h, .WRITEDATA, &data)

	// User-Agent is required by GitHub API
	headers: ^curl.slist = nil
	headers = curl.slist_append(headers, "User-Agent: Odin-Request")
	defer curl.slist_free_all(headers)
	curl.easy_setopt(h, .HTTPHEADER, headers)

	res := curl.easy_perform(h)
	if res != .E_OK {
		fmt.eprintln("Curl failed:", curl.easy_strerror(res))
		return "", false
	}

	response := strings.to_string(b)

	// Parse the JSON manually by searching for `"sha":`
	sha_idx := strings.index(response, "\"sha\":")
	if sha_idx == -1 {
		fmt.eprintln("Could not find commit hash in GitHub API response")
		return "", false
	}

	// Skip `"sha":` and the following `"`
	// `"sha": "..."`
	// 012345678
	start_idx := sha_idx + 6 // after `"sha":`

	// Find the start quote
	quote_start := strings.index(response[start_idx:], "\"")
	if quote_start == -1 {
		return "", false
	}
	start_idx += quote_start + 1

	quote_end := strings.index(response[start_idx:], "\"")
	if quote_end == -1 {
		return "", false
	}

	commit_hash := response[start_idx:start_idx + quote_end]
	return strings.clone(commit_hash), true
}


convert_link_to_api :: proc(raw_url: string) -> (string, bool) {
	url, _ := orl.parse_url(raw_url)
	parts := strings.split(url.path, "/", context.temp_allocator)

	if len(parts) < 3 {
		fmt.eprintln(
			"Invalid GitHub link. Expected format: https://github.com/User/Repo or https://github.com/User/Repo/tree/Branch/[Path]",
		)
		return "", false
	}

	user := parts[1]
	repo := parts[2]
	branch := ""
	file_path := ""

	if len(parts) >= 5 && parts[3] == "tree" {
		branch = parts[4]
		if len(parts) > 5 {
			file_path = strings.join(parts[5:], "/", context.temp_allocator)
		}
	}

	params := make([dynamic]orl.Query_Param, context.temp_allocator)
	if file_path != "" {
		orl.append(&params, "path", file_path)
	}
	if branch != "" {
		orl.append(&params, "sha", branch)
	}
	orl.append(&params, "per_page", "1")

	api_url := fmt.tprintf(
		"https://api.github.com/repos/%s/%s/commits?%s",
		user,
		repo,
		orl.to_string(params[:]),
	)

	return api_url, true
}
