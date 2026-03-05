package odeps

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "src"
import "src/orl"


main :: proc() {
	argv := os.args[1:]

	if !src.is_folder(argv[0]) {
		fmt.eprintln("Url expected to be a folder")
		return
	}

	commit, ok := src.get_commit(argv[0])
	if ok {
		fmt.println("Latest commit:", commit)

		contents_url, url_ok := src.get_contents_url(argv[0], commit)
		if url_ok {
			url_parts, _ := orl.parse_url(argv[0])
			target_dir := filepath.base(url_parts.path)

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
