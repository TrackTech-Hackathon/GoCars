## Unit tests for Toolbar
## Tests button creation and signal emission

extends SceneTree

const Toolbar = preload("res://scripts/ui/toolbar.gd")

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0

func _init():
	print("=".repeat(70))
	print("Running Toolbar Tests")
	print("=".repeat(70))

	# Test groups
	test_toolbar_creation()
	test_button_signals()

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

func test_toolbar_creation():
	print("\n--- Toolbar Creation Tests ---")

	var toolbar = Toolbar.new()
	toolbar._ready()  # Setup structure

	# Test 1: Toolbar created
	assert_not_null(toolbar, "Toolbar should be created")

	# Test 2: Code editor button exists
	assert_not_null(toolbar.code_editor_button, "Code editor button should exist")
	assert_equal(toolbar.code_editor_button.text, "[+]", "Code editor button text should be [+]")

	# Test 3: README button exists
	assert_not_null(toolbar.readme_button, "README button should exist")
	assert_equal(toolbar.readme_button.text, "[i]", "README button text should be [i]")

	# Test 4: Skill tree button exists
	assert_not_null(toolbar.skill_tree_button, "Skill tree button should exist")
	assert_equal(toolbar.skill_tree_button.text, "[🌳]", "Skill tree button text should be [🌳]")

	toolbar.free()

func test_button_signals():
	print("\n--- Button Signal Tests ---")

	var toolbar = Toolbar.new()
	toolbar._ready()  # Setup structure

	# Test 1: Toolbar has code_editor_requested signal
	assert_true(toolbar.has_signal("code_editor_requested"), "Toolbar should have code_editor_requested signal")

	# Test 2: Toolbar has readme_requested signal
	assert_true(toolbar.has_signal("readme_requested"), "Toolbar should have readme_requested signal")

	# Test 3: Toolbar has skill_tree_requested signal
	assert_true(toolbar.has_signal("skill_tree_requested"), "Toolbar should have skill_tree_requested signal")

	toolbar.free()

# Test assertion helpers
func assert_true(condition: bool, message: String):
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s" % message)

func assert_equal(actual, expected, message: String):
	_test_count += 1
	if actual == expected:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (expected: %s, got: %s)" % [message, expected, actual])

func assert_not_null(value, message: String):
	_test_count += 1
	if value != null:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (value was null)" % message)
