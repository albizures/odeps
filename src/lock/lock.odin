package lock

import tome "../tome/src"
import "core:fmt"
import "core:os"
import "core:strings"

LOCK_FILE_NAME :: "odeps-lock.tome"

Dependency :: struct {
	folder: string,
	url:    string,
	commit: string,
}

get_dependencies :: proc(allocator := context.allocator) -> ([dynamic]Dependency, bool) {
	content, err := os.read_entire_file(LOCK_FILE_NAME, context.temp_allocator)
	if err != nil {
		return nil, false
	}

	parsed, errors := tome.parse(string(content), context.temp_allocator)
	if len(errors) > 0 {
		fmt.eprintln("Failed to parse lock file:", errors)
		return nil, false
	}

	deps_val, deps_ok := parsed["deps"]
	if !deps_ok {
		return nil, true // Empty
	}

	deps_array, is_array := deps_val.(tome.Array)
	if !is_array {
		return nil, false
	}

	deps := make([dynamic]Dependency, allocator)
	for d in deps_array {
		dep_obj, is_obj := d.(tome.Object)
		if !is_obj do continue

		folder, _ := dep_obj["folder"].(tome.String)
		url, _ := dep_obj["url"].(tome.String)
		commit, _ := dep_obj["commit"].(tome.String)

		append(&deps, Dependency{
			folder = string(folder),
			url = string(url),
			commit = string(commit),
		})
	}

	return deps, true
}

update_dependency :: proc(folder: string, new_commit: string) -> bool {
	content, err := os.read_entire_file(LOCK_FILE_NAME, context.allocator)
	if err != nil {
		fmt.eprintln("Failed to read lock file")
		return false
	}
	defer delete(content)

	parsed, errors := tome.parse(string(content), context.allocator)
	if len(errors) > 0 {
		fmt.eprintln("Failed to parse lock file:", errors)
		return false
	}

	deps_val, deps_ok := parsed["deps"]
	if !deps_ok {
		fmt.eprintln("Lock file missing deps array")
		return false
	}

	deps_array, is_array := deps_val.(tome.Array)
	if !is_array {
		fmt.eprintln("Invalid lock file format: 'deps' is not an array")
		return false
	}

	found := false
	for &d in deps_array {
		dep_obj, is_obj := d.(tome.Object)
		if !is_obj do continue

		dep_folder, _ := dep_obj["folder"].(tome.String)
		if string(dep_folder) == folder {
			dep_obj["commit"] = tome.String(new_commit)
			found = true
			break
		}
	}

	if !found {
		fmt.eprintln("Dependency not found in lock file:", folder)
		return false
	}

	serialized := tome.serialize(
		parsed,
		context.allocator,
		{max_inline_items = 0, max_inline_properties = 4, indent_type = .Tabs, indent_count = 1},
	)
	defer delete(serialized)

	write_ok := os.write_entire_file(LOCK_FILE_NAME, transmute([]u8)serialized)
	return write_ok == nil
}

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
