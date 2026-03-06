package cli

import "core:fmt"
import "core:os"

Add_Command :: struct {
	url:    string,
	// target folder default to "."
	target: string,
	// name of the folder, default to repo or folder name from github
	name:   string,
}

Update_Command :: struct {
	name: string,
}


Command :: union {
	Add_Command,
	Update_Command,
}

parse_argv :: proc(argv: []string) -> Command {
	if len(argv) < 2 {
		print_usage()
		os.exit(0)
	}

	command_str := argv[0]

	switch command_str {
	case "add":
		return parse_add(argv)
	case "update":
		return parse_update(argv)
	case "help":
		handle_help(argv)
	case:
		fmt.eprintf("Unknown command: %s\n", command_str)
		print_usage()
		os.exit(1)
	}

	panic("This should not happened")
}

handle_help :: proc(argv: []string) {
	cmd: string
	if len(argv) >= 2 {
		cmd = argv[1]
	}

	if cmd == "add" {
		print_add_usage()
	} else if cmd == "update" {
		print_update_usage()
	} else {
		print_usage()
	}
	os.exit(0)
}

parse_add :: proc(argv: []string) -> Add_Command {
	if len(argv) < 2 {
		print_add_usage()
		os.exit(1)
	}

	cmd := Add_Command {
		url    = argv[1],
		target = os.exists("src") ? "src" : "",
		name   = "",
	}

	i := 2
	for i < len(argv) {
		arg := argv[i]
		if (arg == "-t" || arg == "--target") && i + 1 < len(argv) {
			cmd.target = argv[i + 1]
			i += 2
		} else if (arg == "-n" || arg == "--name") && i + 1 < len(argv) {
			cmd.name = argv[i + 1]
			i += 2
		} else {
			fmt.eprintf("Unknown or incomplete flag for add command: %s\n", arg)
			print_add_usage()
			os.exit(1)
		}
	}
	return cmd
}

parse_update :: proc(argv: []string) -> Update_Command {
	cmd := Update_Command{}
	if len(argv) >= 3 {
		cmd.name = argv[2]
	}
	return cmd
}

@(private)
print_usage :: proc() {
	fmt.println(
		`Usage:
odeps add https://github.com/username/repo
odeps add https://github.com/username/repo -t src
odeps help add

Commands:
  help    Display this help message
  add     Add a new dependency to the project
  update  Update an existing dependency`,
	)
}

@(private)
print_add_usage :: proc() {
	fmt.println(
		`Usage: odeps add <url> [flags]

Arguments:
  <url>   The GitHub repository URL to download from

Flags:
  -t, --target <dir>   Target folder to download into (default: ".")
  -n, --name <name>    Name of the folder to create (default: repo or folder name from GitHub)`,
	)
}

@(private)
print_update_usage :: proc() {
	fmt.println(
		`Usage: odeps update [name]

Arguments:
  [name]  Optional name of the dependency to update. If not provided, updates all dependencies.`,
	)
}
