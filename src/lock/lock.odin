package lock

import tome "../tome/src"
import "core:fmt"
import "core:os"
import "core:strings"

LOCK_FILE_NAME :: "odeps-lock.tome"

add_dependency :: proc(folder: string, url: string, commit: string) -> bool {
	content, err := os.read_entire_file(LOCK_FILE_NAME, context.allocator)

	lock_obj: tome.Object

	if err == nil {
		// Parse existing lock file
		parsed, errors := tome.parse(string(content), context.allocator)
		if len(errors) > 0 {
			fmt.eprintln("Failed to parse lock file:", errors)
			return false
		}

		lock_obj = parsed
	} else {
		// Initialize new lock file
		lock_obj = make(tome.Object, 2, context.allocator)
		lock_obj["version"] = tome.Integer(1)
		lock_obj["deps"] = tome.Array(make([dynamic]tome.Value, context.allocator))
	}

	defer delete(content)

	// Check if deps exists and is an array
	deps_val, deps_ok := lock_obj["deps"]
	if !deps_ok {
		lock_obj["deps"] = tome.Array(make([dynamic]tome.Value, context.allocator))
		deps_val = lock_obj["deps"]
	}

	deps_array, is_array := deps_val.(tome.Array)
	if !is_array {
		fmt.eprintln("Invalid lock file format: 'deps' is not an array")
		return false
	}

	// Create new dependency object
	dep_obj := make(tome.Object, 3, context.allocator)
	dep_obj["folder"] = tome.String(folder)
	dep_obj["url"] = tome.String(url)
	dep_obj["commit"] = tome.String(commit)

	// Append to deps array
	append(cast(^[dynamic]tome.Value)&deps_array, tome.Value(dep_obj))
	lock_obj["deps"] = deps_array // Update the value in case it was reallocated or needed


	// Serialize back to file
	serialized := tome.serialize(
		lock_obj,
		context.allocator,
		{max_inline_items = 0, max_inline_properties = 4, indent_type = .Tabs, indent_count = 1},
	)
	defer delete(serialized)
	write_ok := os.write_entire_file(LOCK_FILE_NAME, transmute([]u8)serialized)

	return write_ok == nil
}
