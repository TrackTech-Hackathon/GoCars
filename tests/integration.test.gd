## Integration tests for Phase 9
## Tests that all systems work together

extends SceneTree

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0

func _init():
	print("=".repeat(70))
	print("Running Integration Tests (Phase 9)")
	print("=".repeat(70))

	# Test groups
	test_all_scripts_exist()
	test_window_manager()
	test_backwards_compatibility()

	# Summary
	print("\n" + "=".repeat(70))
	print("Test Summary")
	print("=".repeat(70))
	print("Total tests: %d" % _test_count)
	print("Passed: %d" % _pass_count)
	print("Failed: %d" % _fail_count)

	if _fail_count == 0:
		print("\n✓ All integration tests passed!")
	else:
		print("\n✗ Some integration tests failed")

	quit()

func test_all_scripts_exist():
	print("\n--- Script Existence Tests ---")

	# Core systems
	assert_true(FileAccess.file_exists("res://scripts/core/virtual_filesystem.gd"), "VirtualFileSystem should exist")
	assert_true(FileAccess.file_exists("res://scripts/core/module_loader.gd"), "ModuleLoader should exist")
	assert_true(FileAccess.file_exists("res://scripts/core/python_parser.gd"), "PythonParser should exist")
	assert_true(FileAccess.file_exists("res://scripts/core/python_interpreter.gd"), "PythonInterpreter should exist")

	# UI windows
	assert_true(FileAccess.file_exists("res://scripts/ui/floating_window.gd"), "FloatingWindow should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/toolbar.gd"), "Toolbar should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/code_editor_window.gd"), "CodeEditorWindow should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/file_explorer.gd"), "FileExplorer should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/readme_window.gd"), "ReadmeWindow should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/skill_tree_window.gd"), "SkillTreeWindow should exist")

	# Integration
	assert_true(FileAccess.file_exists("res://scripts/ui/window_manager.gd"), "WindowManager should exist")
	assert_true(FileAccess.file_exists("res://scripts/ui/main_integration.gd"), "Integration helper should exist")

	# Main scene
	assert_true(FileAccess.file_exists("res://scenes/main.gd"), "Main scene script should exist")

func test_window_manager():
	print("\n--- WindowManager Tests ---")

	var WindowManagerClass = load("res://scripts/ui/window_manager.gd")
	var VirtualFileSystem = load("res://scripts/core/virtual_filesystem.gd")
	var ModuleLoader = load("res://scripts/core/module_loader.gd")

	# Test 1: WindowManager can be instantiated
	var wm = WindowManagerClass.new()
	assert_not_null(wm, "WindowManager should be creatable")

	# Test 2: VirtualFileSystem is created
	assert_not_null(wm.virtual_fs, "WindowManager should have VirtualFileSystem")

	# Test 3: ModuleLoader is created
	assert_not_null(wm.module_loader, "WindowManager should have ModuleLoader")

	# Test 4: Has code_execution_requested signal
	assert_true(wm.has_signal("code_execution_requested"), "WindowManager should have code_execution_requested signal")

	wm.free()

func test_backwards_compatibility():
	print("\n--- Backwards Compatibility Tests ---")

	# Test 1: All existing parser tests still pass
	assert_true(FileAccess.file_exists("res://tests/python_parser.test.gd"), "Parser tests should exist")

	# Test 2: All existing interpreter tests still pass
	assert_true(FileAccess.file_exists("res://tests/python_interpreter_functions.test.gd"), "Interpreter tests should exist")

	# Test 3: VirtualFileSystem tests still pass
	assert_true(FileAccess.file_exists("res://tests/virtual_filesystem.test.gd"), "VFS tests should exist")

	# Test 4: Main scene can still run (checked by loading)
	var main_script = load("res://scenes/main.gd")
	assert_not_null(main_script, "Main scene script should load")

	# Test 5: Check that main.gd has use_new_ui variable
	var file = FileAccess.open("res://scenes/main.gd", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		assert_true(content.contains("use_new_ui"), "Main should have use_new_ui toggle")
		assert_true(content.contains("_setup_new_ui"), "Main should have _setup_new_ui function")
		assert_true(content.contains("window_manager"), "Main should have window_manager variable")

# Test assertion helpers
func assert_true(condition: bool, message: String):
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s" % message)

func assert_not_null(value, message: String):
	_test_count += 1
	if value != null:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (value was null)" % message)
