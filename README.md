# odeps

A small command-line tool written in Odin to download the contents of a GitHub repository folder (recursively). It uses the GitHub API and libcurl (via the `vendor:curl` binding) to determine the latest commit and fetch folder contents.

- Resolve latest commit for a repository path and branch.
- Construct GitHub contents API URL and recursively download folder contents.
- Handles files and directories; preserves structure.
- Minimal, dependency-light implementation in Odin.

- Odin compiler available in PATH (https://odin-lang.org).
- libcurl available for the `vendor:curl` binding.
- Tested on macOS; should work on Linux where libcurl is present.

From the repository root:
```
odin build .
```

To build and run directly:
```
odin run .
```

Basic usage:
```
odeps <github_url> [target_directory]
```

Examples:
- Download a repository root:
```
odeps https://github.com/username/repo
# creates folder: repo
```

- Download a folder on a specific branch:
```
odeps https://github.com/username/repo/tree/branch/path/to/folder
# creates folder: folder (inside cwd unless target_directory supplied)
```

- Provide a target directory:
```
odeps https://github.com/username/repo/tree/main/some/dir output_dir
# content downloaded into output_dir/repo
```

- The tool uses the GitHub API; for public repos no auth is required. For private repos or higher rate limits, you may want to modify the code to pass a token to `download_folder_contents` / `fetch_url` (see `src/downloader.odin`).

Run the tests shipped with the repo:
```
odin test tests/
```

You can run an individual test file:
```
odin test tests/downloader.test.odin
```

- `src/main.odin` / `odeps.odin` provide the CLI entrypoint and glue.
- `src/main.odin` contains logic to build API URLs and query GitHub commits.
- `src/downloader.odin` fetches `contents` endpoints and downloads files, recursing into directories.
- URL parsing utilities live in `src/orl/` (`src/orl/src/url.odin`, `src/orl/src/query.odin`).

- Follow the codebase conventions in `AGENTS.md` (naming, allocator usage, testing patterns).
- The code uses `strings.builder` and JSON unmarshalling via `core:encoding/json`.
- `vendor:curl` provides curl bindings; ensure `libcurl` exists on your system.

- Open an issue or submit a PR with a clear description and tests.
- Run `odin check src/` before submitting changes.
- Add or update tests under `tests/` when modifying behavior.

This project is licensed under the MIT License - see the `LICENSE` file for details.
