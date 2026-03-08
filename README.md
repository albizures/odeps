# odeps

A dead simple dependecy tool for Odin. It downloads the contents of a GitHub repository or folder (recursively).


## Philosophy

In line with Odin's philosophy of having no package manager, odeps rejects complex dependency trees like those in npm or Cargo. Instead, each dependency is treated as a simple folder downloaded directly from GitHub, without any handling of nested dependencies.

Dependencies become part of the project's source code, ensuring straightforward versioning and management.

Why not git submodules? Git submodules introduce unnecessary complexity with their separate clone, update, and synchronization commands. They can be error-prone, leading to lost changes if not handled meticulously, and they don't align with the goal of dead-simple dependency management. Odeps offers a cleaner alternative: direct folder downloads that integrate seamlessly into your source tree without the overhead.

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
