package odeps

import "core:fmt"
import "core:os"
import "src/cli"

main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Usage: odeps <url> [target_directory]")
		return
	}

	url := os.args[1]
	cmd := cli.parse_argv(os.args[1:])

	switch v in cmd {
	case cli.Add_Command:
		cli.handle_add(v)
	case cli.Update_Command:
		cli.handle_update(v)
	}
}
