package odeps

import "core:fmt"
import "core:os"
import "core:path/filepath"
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
			target_dir := filepath.base(url_parts.path)

			if len(os.args) >= 3 {
				target_dir = os.args[2]
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
