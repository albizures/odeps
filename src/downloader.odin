package odeps_core

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "vendor:curl"

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

	json_data, err := json.parse(
		transmute([]byte)data,
		json.DEFAULT_SPECIFICATION,
		parse_integers = false,
		allocator = context.temp_allocator,
	)
	if err != nil {
		fmt.eprintln("Failed to parse JSON:", err)
		return false
	}

	if json_arr, is_array := json_data.(json.Array); is_array {
		for item in json_arr {
			if obj, is_obj := item.(json.Object); is_obj {
				type_str := obj["type"].(json.String)
				name_str := obj["name"].(json.String)

				item_path := filepath.join({target_dir, name_str})
				defer delete(item_path)

				if type_str == "file" {
					download_url := obj["download_url"].(json.String)
					fmt.println("Downloading file:", item_path)

					file_data, file_ok := fetch_url(download_url, token)
					if file_ok {
						os.write_entire_file(item_path, transmute([]byte)file_data)
						delete(file_data)
					} else {
						fmt.eprintln("Failed to download file:", download_url)
					}
				} else if type_str == "dir" {
					dir_url := obj["url"].(json.String)
					fmt.println("Entering directory:", item_path)
					download_folder_contents(dir_url, item_path, token)
				}
			}
		}
		return true
	} else if obj, is_obj := json_data.(json.Object); is_obj {
		// Single file fallback maybe?
		fmt.eprintln("Got object instead of array, might not be a directory")
		return false
	}

	return false
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
