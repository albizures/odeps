package cli

import "../github"
import "../orl"
import "core:fmt"
import "core:path/filepath"
import "core:strings"

handle_add :: proc(cmd: Add_Command) {
	if !github.is_folder(cmd.url) {
		fmt.eprintln("Url expected to be a folder")
		return
	}

	commit, ok := github.get_commit(cmd.url)
	if ok {
		fmt.println("Latest commit:", commit)

		contents_url, url_ok := github.get_contents_url(cmd.url, commit)
		if url_ok {
			url_parts, _ := orl.parse_url(cmd.url)
			path := url_parts.path
			if strings.has_suffix(path, "/") {
				path = path[:len(path) - 1]
			}
			repo_name := filepath.base(path) if len(cmd.name) == 0 else cmd.name
			target_dir: string
			if len(cmd.target) == 0 {
				target_dir = repo_name
			} else {
				temp_dir, _ := filepath.join({cmd.target, repo_name}, context.temp_allocator)
				target_dir = temp_dir
			}


			fmt.println("Downloading contents from:", contents_url)
			dl_ok := github.download_folder_contents(contents_url, target_dir)
			if dl_ok {
				fmt.println("Downloaded data successfully!")
			} else {
				fmt.eprintln("Failed to download folder data.")
			}
		} else {
			fmt.eprintln("Failed to construct contents URL")
		}
	} else {
		fmt.println("Failed to get commit")
	}
}
