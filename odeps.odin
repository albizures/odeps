package odeps

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "src"
import "src/orl"


main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Usage: odeps <url> [target_directory]")
		return
	}

	url := os.args[1]

	if !src.is_folder(url) {
		fmt.eprintln("Url expected to be a folder")
		return
	}

	commit, ok := src.get_commit(url)
	if ok {
		fmt.println("Latest commit:", commit)

		contents_url, url_ok := src.get_contents_url(url, commit)
		if url_ok {
			url_parts, _ := orl.parse_url(url)
			path := url_parts.path
			if strings.has_suffix(path, "/") {
				path = path[:len(path) - 1]
			}
			repo_name := filepath.base(path)
			target_dir := repo_name

			if len(os.args) >= 3 {
				target_dir = filepath.join({os.args[2], repo_name})
			}

			fmt.println("Downloading contents from:", contents_url)
			dl_ok := src.download_folder_contents(contents_url, target_dir)
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
