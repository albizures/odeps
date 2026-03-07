package cli

import "../github"
import "../lock"
import "core:fmt"
import "core:os"
import "core:strings"

handle_update :: proc(cmd: Update_Command) {
	deps, deps_ok := lock.get_dependencies(context.temp_allocator)
	if !deps_ok {
		fmt.eprintln("Failed to get dependencies from lock file.")
		os.exit(1)
	}

	if len(deps) == 0 {
		fmt.println("No dependencies to update.")
		return
	}

	target_name := cmd.name
	updated_any := false

	for dep in deps {
		if len(target_name) > 0 && dep.folder != target_name {
			continue
		}

		fmt.printf("Checking update for %s...\n", dep.folder)

		latest_commit, commit_ok := github.get_commit(dep.url)
		if !commit_ok {
			fmt.eprintf("Failed to get latest commit for %s\n", dep.url)
			continue
		}
		defer delete(latest_commit)

		if dep.commit == latest_commit {
			fmt.printf("%s is already up-to-date.\n", dep.folder)
			continue
		}

		status, status_ok := github.get_compare_status(dep.url, dep.commit, latest_commit, context.temp_allocator)
		if !status_ok {
			// If we can't compare, assume we need to update since commits differ
			status = "behind"
		}

		if status == "identical" {
			fmt.printf("%s is already up-to-date.\n", dep.folder)
			continue
		}

		fmt.printf("Updating %s from %s to %s...\n", dep.folder, dep.commit[:7], latest_commit[:7])

		contents_url, url_ok := github.get_contents_url(dep.url, latest_commit)
		if !url_ok {
			fmt.eprintln("Failed to construct contents URL")
			continue
		}

		dl_ok := github.download_folder_contents(contents_url, dep.folder)
		if dl_ok {
			if lock.update_dependency(dep.folder, latest_commit) {
				fmt.printf("Successfully updated %s\n", dep.folder)
				updated_any = true
			} else {
				fmt.eprintf("Failed to update odeps-lock.tome for %s\n", dep.folder)
			}
		} else {
			fmt.eprintf("Failed to download contents for %s\n", dep.folder)
		}
	}

	if !updated_any && len(target_name) > 0 {
		fmt.eprintf("Dependency '%s' not found or failed to update.\n", target_name)
	}
}
