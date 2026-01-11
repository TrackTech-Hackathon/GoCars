## Unit tests for VirtualFileSystem
## Tests CRUD operations, directory management, and validation

extends SceneTree

const VirtualFileSystem = preload("res://scripts/core/virtual_filesystem.gd")

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0

func _init():
	print("=".repeat(70))
	print("Running VirtualFileSystem Tests")
	print("=".repeat(70))

	# Test groups
	test_file_operations()
	test_directory_operations()
	test_path_validation()
	test_reserved_files()
	test_file_tree()
	test_edge_cases()

	# Summary
	print("\n" + "=".repeat(70))
	print("Test Summary")
	print("=".repeat(70))
	print("Total tests: %d" % _test_count)
	print("Passed: %d" % _pass_count)
	print("Failed: %d" % _fail_count)

	if _fail_count == 0:
		print("\n✓ All tests passed!")
	else:
		print("\n✗ Some tests failed")

	quit()

func test_file_operations():
	print("\n--- File Operations Tests ---")

	var vfs = VirtualFileSystem.new()

	# Test 1: Default files are created
	assert_true(vfs.file_exists("main.py"), "Default main.py should exist")
	assert_true(vfs.file_exists("README.md"), "Default README.md should exist")

	# Test 2: Create new file
	assert_true(vfs.create_file("helpers.py", "# Helper functions"), "Should create new file")
	assert_true(vfs.file_exists("helpers.py"), "Created file should exist")

	# Test 3: Read file contents
	var content = vfs.read_file("helpers.py")
	assert_equal(content, "# Helper functions", "Should read correct file contents")

	# Test 4: Update file contents
	assert_true(vfs.update_file("helpers.py", "# Updated content"), "Should update file")
	var updated_content = vfs.read_file("helpers.py")
	assert_equal(updated_content, "# Updated content", "Should read updated contents")

	# Test 5: Delete file
	assert_true(vfs.delete_file("helpers.py"), "Should delete file")
	assert_false(vfs.file_exists("helpers.py"), "Deleted file should not exist")

	# Test 6: Create file with same name twice
	vfs.create_file("test.py", "content")
	assert_false(vfs.create_file("test.py", "content2"), "Should not create duplicate file")

	# Test 7: Read non-existent file
	var non_existent = vfs.read_file("nonexistent.py")
	assert_equal(non_existent, "", "Reading non-existent file should return empty string")

	# Test 8: Update non-existent file
	assert_false(vfs.update_file("nonexistent.py", "content"), "Should not update non-existent file")

	# Test 9: Delete non-existent file
	assert_false(vfs.delete_file("nonexistent.py"), "Should not delete non-existent file")

func test_directory_operations():
	print("\n--- Directory Operations Tests ---")

	var vfs = VirtualFileSystem.new()

	# Test 1: Create directory
	assert_true(vfs.create_directory("modules"), "Should create directory")
	assert_true(vfs.directory_exists("modules"), "Created directory should exist")

	# Test 2: Create nested directory
	assert_true(vfs.create_directory("modules/navigation"), "Should create nested directory")
	assert_true(vfs.directory_exists("modules/navigation"), "Nested directory should exist")

	# Test 3: Create file in directory
	assert_true(vfs.create_file("modules/helpers.py", "# Helpers"), "Should create file in directory")
	assert_true(vfs.file_exists("modules/helpers.py"), "File in directory should exist")

	# Test 4: List directory contents
	var items = vfs.list_directory("modules")
	assert_true(items.size() > 0, "Directory should have items")

	# Test 5: List root directory
	var root_items = vfs.list_directory("")
	assert_true(root_items.size() >= 2, "Root should have at least main.py and README.md")

	# Test 6: Create directory with auto-parent creation
	assert_true(vfs.create_file("deep/nested/file.py", "content"), "Should create file with nested parents")
	assert_true(vfs.directory_exists("deep"), "Parent directory should be auto-created")
	assert_true(vfs.directory_exists("deep/nested"), "Nested parent should be auto-created")

func test_path_validation():
	print("\n--- Path Validation Tests ---")

	var vfs = VirtualFileSystem.new()

	# Test 1: Path normalization (forward slashes)
	vfs.create_file("test/file.py", "content")
	assert_true(vfs.file_exists("test/file.py"), "Should handle forward slashes")

	# Test 2: Invalid file extension
	assert_false(vfs.create_file("test.exe", "content"), "Should reject invalid extension")
	assert_false(vfs.create_file("test", "content"), "Should reject no extension")

	# Test 3: Valid extensions
	assert_true(vfs.create_file("test.py", "content"), ".py should be valid")
	assert_true(vfs.create_file("notes.txt", "content"), ".txt should be valid")
	assert_true(vfs.create_file("docs.md", "content"), ".md should be valid")

	# Test 4: Empty path
	assert_false(vfs.create_file("", "content"), "Should reject empty path")

func test_reserved_files():
	print("\n--- Reserved Files Tests ---")

	var vfs = VirtualFileSystem.new()

	# Test 1: Cannot delete main.py
	assert_false(vfs.delete_file("main.py"), "Should not delete main.py")
	assert_true(vfs.file_exists("main.py"), "main.py should still exist")

	# Test 2: Cannot rename main.py
	assert_false(vfs.rename_file("main.py", "renamed.py"), "Should not rename main.py")
	assert_true(vfs.file_exists("main.py"), "main.py should still exist after rename attempt")

	# Test 3: Can update main.py
	assert_true(vfs.update_file("main.py", "# New content"), "Should be able to update main.py")

func test_file_tree():
	print("\n--- File Tree Tests ---")

	var vfs = VirtualFileSystem.new()

	# Create test structure
	vfs.create_directory("modules")
	vfs.create_file("modules/nav.py", "# Navigation")
	vfs.create_file("modules/helpers.py", "# Helpers")
	vfs.create_file("test.py", "# Test")

	# Test 1: Get file tree
	var tree = vfs.get_file_tree()
	assert_equal(tree["type"], "directory", "Root should be directory")
	assert_true(tree["children"].size() > 0, "Tree should have children")

	# Test 2: Get all files
	var all_files = vfs.get_all_files()
	assert_true(all_files.size() >= 4, "Should have at least 4 files (main.py, README.md, test.py, modules/nav.py)")

	# Test 3: Get all directories
	var all_dirs = vfs.get_all_directories()
	assert_true("modules" in all_dirs, "Should include modules directory")

func test_edge_cases():
	print("\n--- Edge Cases Tests ---")

	var vfs = VirtualFileSystem.new()

	# Test 1: Rename file
	vfs.create_file("old.py", "content")
	assert_true(vfs.rename_file("old.py", "new.py"), "Should rename file")
	assert_false(vfs.file_exists("old.py"), "Old file should not exist")
	assert_true(vfs.file_exists("new.py"), "New file should exist")
	assert_equal(vfs.read_file("new.py"), "content", "Content should be preserved")

	# Test 2: Rename to existing file
	vfs.create_file("existing.py", "content")
	assert_false(vfs.rename_file("new.py", "existing.py"), "Should not rename to existing file")

	# Test 3: Rename non-existent file
	assert_false(vfs.rename_file("nonexistent.py", "new.py"), "Should not rename non-existent file")

	# Test 4: Clear all
	vfs.clear_all()
	var files = vfs.get_all_files()
	assert_equal(files.size(), 2, "After clear, should only have main.py and README.md")

	# Test 5: List non-existent directory
	var items = vfs.list_directory("nonexistent")
	assert_equal(items.size(), 0, "Listing non-existent directory should return empty array")

# Test assertion helpers
func assert_true(condition: bool, message: String):
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s" % message)

func assert_false(condition: bool, message: String):
	assert_true(not condition, message)

func assert_equal(actual, expected, message: String):
	_test_count += 1
	if actual == expected:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (expected: %s, got: %s)" % [message, expected, actual])
