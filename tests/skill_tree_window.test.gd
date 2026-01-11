## Unit tests for SkillTreeWindow
## Tests placeholder window creation

extends SceneTree

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0

func _init():
	print("=".repeat(70))
	print("Running SkillTreeWindow Tests")
	print("=".repeat(70))

	# Test groups
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

func test_script_exists():
	print("\n--- Skill Tree Window Tests ---")

	# Test 1: Script exists
	assert_true(FileAccess.file_exists("res://scripts/ui/skill_tree_window.gd"), "SkillTreeWindow script should exist")

	# Test 2: Check for "Coming Soon" content
	var file = FileAccess.open("res://scripts/ui/skill_tree_window.gd", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()

		assert_true(content.contains("Coming Soon"), "Should have 'Coming Soon' message")
		assert_true(content.contains("Skill Tree"), "Should mention Skill Tree")
	else:
		assert_true(false, "Could not read SkillTreeWindow script")

	# Test 3: All UI windows exist
	assert_true(FileAccess.file_exists("res://scripts/ui/floating_window.gd"), "FloatingWindow should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/toolbar.gd"), "Toolbar should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/code_editor_window.gd"), "CodeEditorWindow should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/file_explorer.gd"), "FileExplorer should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/readme_window.gd"), "ReadmeWindow should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/skill_tree_window.gd"), "SkillTreeWindow should exist")

# Test assertion helpers
func assert_true(condition: bool, message: String):
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s" % message)
