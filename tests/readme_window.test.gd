## Unit tests for ReadmeWindow
## Tests documentation window creation and content

extends SceneTree

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0

func _init():
	print("=".repeat(70))
	print("Running ReadmeWindow Tests")
	print("=".repeat(70))

	# Test groups
	test_window_structure()
	test_script_exists()

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

func test_window_structure():
	print("\n--- Window Structure Tests ---")

	# Test 1: Script exists
	assert_true(FileAccess.file_exists("res://scripts/ui/readme_window.gd"), "ReadmeWindow script should exist")

	# Test 2: README content check (via reading script file)
	var file = FileAccess.open("res://scripts/ui/readme_window.gd", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()

		# Check for key documentation sections
		assert_true(content.contains("Car Commands"), "Should have Car Commands section")
		assert_true(content.contains("Stoplight Commands"), "Should have Stoplight Commands section")
		assert_true(content.contains("Import System"), "Should have Import System section")
		assert_true(content.contains("Tips & Tricks"), "Should have Tips & Tricks section")
	else:
		assert_true(false, "Could not read README window script")

func test_script_exists():
	print("\n--- Script Existence Tests ---")

	# Test 1: All UI scripts exist
	assert_true(FileAccess.file_exists("res://scripts/ui/floating_window.gd"), "FloatingWindow script should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/toolbar.gd"), "Toolbar script should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/code_editor_window.gd"), "CodeEditorWindow script should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/file_explorer.gd"), "FileExplorer script should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/readme_window.gd"), "ReadmeWindow script should exist")

# Test assertion helpers
func assert_true(condition: bool, message: String):
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s" % message)
