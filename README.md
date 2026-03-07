# odeps

A dead simple dependecy tool for Odin. It downloads the contents of a GitHub repository or folder (recursively).

## Basic usage:

```
odeps add <github_url> [-t <target_directory>] [-n <name>]
```

Examples:

- Download a repository root:

```
odeps add https://github.com/username/repo
# creates folder: repo
```
> [!NOTE]
> In case there is a src directory, it will be used instead of the root.

- Download a folder on a specific branch:

```
odeps add https://github.com/username/repo/tree/branch/path/to/folder
# creates folder: folder (inside cwd unless target_directory supplied)
```

- Provide a target directory:

```
odeps add https://github.com/username/repo/tree/main/some/dir -t output_dir
# content downloaded into output_dir/repo
```
