package downloader_tests

import "../src/lock"
import "../src/tome/src"
import "core:fmt"
import "core:os"
import "core:testing"

LOCK_FILE_NAME :: lock.LOCK_FILE_NAME

@(test)
test_lock_add_dependency :: proc(t: ^testing.T) {
	// Setup
	os.remove(LOCK_FILE_NAME)
	defer os.remove(LOCK_FILE_NAME)
	defer free_all(context.temp_allocator)

	// Add first dependency
	ok := lock.add_dependency("vendor/foo", "https://github.com/user/foo", "abcdef")
	testing.expect(t, ok, "Failed to add first dependency")

	// Read and verify
	content, err := os.read_entire_file(LOCK_FILE_NAME, context.allocator)
	testing.expect(t, err == nil, "Failed to read lock file")
	
	parsed, errors := src.parse(string(content), context.allocator)
	testing.expect_value(t, len(errors), 0)
	
	version, has_version := parsed["version"].(src.Integer)
	testing.expect(t, has_version, "Version missing")
	testing.expect_value(t, version, 1)

	deps, has_deps := parsed["deps"].(src.Array)
	testing.expect(t, has_deps, "Deps missing")
	testing.expect_value(t, len(deps), 1)

	dep1, is_obj1 := deps[0].(src.Object)
	testing.expect(t, is_obj1, "Dep1 is not an object")
	
	folder1, _ := dep1["folder"].(src.String)
	testing.expect_value(t, string(folder1), "vendor/foo")

	// Add second dependency
	ok2 := lock.add_dependency("vendor/bar", "https://github.com/user/bar", "123456")
	testing.expect(t, ok2, "Failed to add second dependency")

	// Read and verify again
	content2, err2 := os.read_entire_file(LOCK_FILE_NAME, context.allocator)
	testing.expect(t, err2 == nil, "Failed to read lock file again")
	
	parsed2, errors2 := src.parse(string(content2), context.allocator)
	testing.expect_value(t, len(errors2), 0)

	deps2, has_deps2 := parsed2["deps"].(src.Array)
	testing.expect(t, has_deps2, "Deps missing")
	testing.expect_value(t, len(deps2), 2)

	dep2, is_obj2 := deps2[1].(src.Object)
	testing.expect(t, is_obj2, "Dep2 is not an object")
	
	folder2, _ := dep2["folder"].(src.String)
	testing.expect_value(t, string(folder2), "vendor/bar")
}
