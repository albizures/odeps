package github

import "../orl"
import "base:runtime"
import "core:c"
import "core:encoding/json"
import "core:fmt"
import "core:strings"
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

	response := b.buf[:]

	json_data, err := json.parse(response)
	if err != nil {
		fmt.eprintln("Could not parse JSON response")
		return "", false
	}
	defer json.destroy_value(json_data)

	root_array, is_array := json_data.(json.Array)
	if !is_array || len(root_array) == 0 {
		fmt.eprintln("Invalid JSON response or no commits found")
		return "", false
	}

	first_commit_obj, is_obj := root_array[0].(json.Object)
	if !is_obj {
		return "", false
	}

	sha_val, has_sha := first_commit_obj["sha"].(json.String)
	if !has_sha {
		return "", false
	}

	return strings.clone(string(sha_val), allocator), true
}

get_compare_status :: proc(raw_url: string, current_commit: string, target_commit: string, allocator := context.allocator) -> (string, bool) {
	url, _ := orl.parse_url(raw_url)
	parts := strings.split(url.path, "/", context.temp_allocator)

	if len(parts) < 3 {
		return "", false
	}

	user := parts[1]
	repo := parts[2]

	api_url := fmt.tprintf(
		"https://api.github.com/repos/%s/%s/compare/%s...%s",
		user,
		repo,
		current_commit,
		target_commit,
	)

	h := curl.easy_init()
	if h == nil {
		fmt.eprintln("Unable to initialize curl")
		return "", false
	}
	defer curl.easy_cleanup(h)

	b := strings.builder_make(context.temp_allocator)
	data := Curl_Data{&b, context}

	curl.easy_setopt(h, .URL, strings.clone_to_cstring(api_url, context.temp_allocator))
	curl.easy_setopt(h, .WRITEFUNCTION, write_callback)
	curl.easy_setopt(h, .WRITEDATA, &data)

	headers: ^curl.slist = nil
	headers = curl.slist_append(headers, "User-Agent: Odin-Request")
	defer curl.slist_free_all(headers)
	curl.easy_setopt(h, .HTTPHEADER, headers)

	res := curl.easy_perform(h)
	if res != .E_OK {
		fmt.eprintln("Curl failed:", curl.easy_strerror(res))
		return "", false
	}

	response := b.buf[:]

	json_data, err := json.parse(response)
	if err != nil {
		fmt.eprintln("Could not parse JSON response for compare status")
		return "", false
	}
	defer json.destroy_value(json_data)

	root_obj, is_obj := json_data.(json.Object)
	if !is_obj {
		return "", false
	}

	status_val, has_status := root_obj["status"].(json.String)
	if !has_status {
		return "", false
	}

	return strings.clone(string(status_val), allocator), true
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
