# odeps

A dead simple dependecy tool for Odin. It downloads the contents of a GitHub repository or folder (recursively).

## Basic usage:

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
