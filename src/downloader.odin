package odeps_core

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "vendor:curl"


Github_Content_Type :: enum {
	File,
	Dir,
}

Github_Content_Item :: struct {
	name:         string `json:"name"`,
	type_str:     string `json:"type"`,
	download_url: string `json:"download_url"`,
	url:          string `json:"url"`,
	type:         Github_Content_Type `json:"-"`,
}

Github_Parse_Error :: enum {
	None,
	Invalid_JSON,
	Not_An_Array,
}

// Helper to recursively download folder contents
download_folder_contents :: proc(url: string, target_dir: string, token: string = "") -> bool {
	data, ok := fetch_url(url, token)
	if !ok {
		return false
	}
	defer delete(data)

	// Ensure target directory exists
	if !os.exists(target_dir) {
		os.make_directory(target_dir)
	}

	items, err := parse_github_contents(data, context.temp_allocator)
	if err != .None {
		fmt.eprintln("Failed to parse GitHub contents:", err)
		return false
	}

	for item in items {
		item_path := filepath.join({target_dir, item.name})
		defer delete(item_path)

		switch item.type {
		case .File:
			fmt.println("Downloading file:", item_path)
			file_data, file_ok := fetch_url(item.download_url, token)
			if file_ok {
				os.write_entire_file(item_path, transmute([]byte)file_data)
				delete(file_data)
			} else {
				fmt.eprintln("Failed to download file:", item.download_url)
			}
		case .Dir:
			fmt.println("Entering directory:", item_path)
			download_folder_contents(item.url, item_path, token)
		}
	}

	return true
}

parse_github_contents :: proc(
	data: string,
	allocator := context.allocator,
) -> (
	[]Github_Content_Item,
	Github_Parse_Error,
) {
	items: []Github_Content_Item
	err := json.unmarshal(transmute([]byte)data, &items, json.DEFAULT_SPECIFICATION, allocator)

	if err != nil {
		#partial switch v in err {
		case json.Error:
			return nil, .Invalid_JSON
		case json.Unmarshal_Data_Error:
			return nil, .Invalid_JSON
		case json.Unsupported_Type_Error:
			return nil, .Not_An_Array
		case:
			return nil, .Invalid_JSON
		}
	}

	// Post-process to set the enum type based on the string
	for &item in items {
		if item.type_str == "file" {
			item.type = .File
		} else if item.type_str == "dir" {
			item.type = .Dir
		}
	}

	return items, .None
}


// Fetch data from a URL using GitHub API headers
// curl -H "Authorization: token YOUR_TOKEN" \
//      -H "Accept: application/vnd.github.v3.raw" \
//      -L -O "https://api.github.com/repos/username/repo-name/contents/path/to/file?ref=commit_hash"
fetch_url :: proc(
	url: string,
	token: string = "",
	allocator := context.allocator,
) -> (
	string,
	bool,
) {
	h := curl.easy_init()
	if h == nil {
		fmt.eprintln("Unable to initialize curl")
		return "", false
	}
	defer curl.easy_cleanup(h)

	b := strings.builder_make(allocator)
	data := Curl_Data{&b, context}

	curl.easy_setopt(h, .URL, strings.clone_to_cstring(url, context.temp_allocator))
	curl.easy_setopt(h, .WRITEFUNCTION, write_callback)
	curl.easy_setopt(h, .WRITEDATA, &data)

	// -L equivalent
	curl.easy_setopt(h, .FOLLOWLOCATION, 1)

	headers: ^curl.slist = nil
	headers = curl.slist_append(headers, "User-Agent: Odin-Request")
	headers = curl.slist_append(headers, "Accept: application/vnd.github.v3.raw")

	if token != "" {
		auth_header := fmt.tprintf("Authorization: token %s", token)
		headers = curl.slist_append(
			headers,
			strings.clone_to_cstring(auth_header, context.temp_allocator),
		)
	}

	defer curl.slist_free_all(headers)
	curl.easy_setopt(h, .HTTPHEADER, headers)

	res := curl.easy_perform(h)
	if res != .E_OK {
		fmt.eprintln("Curl failed:", curl.easy_strerror(res))
		strings.builder_destroy(&b)
		return "", false
	}

	return strings.to_string(b), true
}
