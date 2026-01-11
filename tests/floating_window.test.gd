## Unit tests for FloatingWindow
## Tests window creation, dragging, resizing, minimize/close

extends SceneTree

const FloatingWindow = preload("res://scripts/ui/floating_window.gd")

var _test_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0

func _init():
	print("=".repeat(70))
	print("Running FloatingWindow Tests")
	print("=".repeat(70))

	# Test groups
	test_window_creation()
	test_window_title()
	test_window_size_constraints()
	test_minimize_restore()
	test_window_visibility()

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

func test_window_creation():
	print("\n--- Window Creation Tests ---")

	# Test 1: Create window
	var window = FloatingWindow.new()
	window._ready()  # Manually call _ready to setup structure
	assert_not_null(window, "Window should be created")

	# Test 2: Window has title bar
	assert_not_null(window.title_bar, "Window should have title bar")

	# Test 3: Window has minimize button
	assert_not_null(window.minimize_button, "Window should have minimize button")

	# Test 4: Window has close button
	assert_not_null(window.close_button, "Window should have close button")

	# Test 5: Window has content container
	assert_not_null(window.content_container, "Window should have content container")

	window.free()

func test_window_title():
	print("\n--- Window Title Tests ---")

	var window = FloatingWindow.new()
	window._ready()  # Setup structure

	# Test 1: Default title
	assert_equal(window.window_title, "Window", "Default title should be 'Window'")

	# Test 2: Set title
	window.set_window_title("Test Window")
	assert_equal(window.window_title, "Test Window", "Title should be updated")

	window.free()

func test_window_size_constraints():
	print("\n--- Window Size Constraints Tests ---")

	var window = FloatingWindow.new()
	window._ready()  # Setup structure

	# Test 1: Default min size
	assert_equal(window.min_size, Vector2(300, 200), "Default min size should be 300x200")

	# Test 2: Default max size
	assert_equal(window.max_size, Vector2(1200, 800), "Default max size should be 1200x800")

	# Test 3: Set window size within constraints
	window.set_window_size(Vector2(500, 400))
	assert_equal(window.size, Vector2(500, 400), "Window size should be 500x400")

	# Test 4: Set window size below min (should clamp)
	window.set_window_size(Vector2(100, 100))
	assert_equal(window.size, Vector2(300, 200), "Window size should clamp to min size")

	# Test 5: Set window size above max (should clamp)
	window.set_window_size(Vector2(2000, 2000))
	assert_equal(window.size, Vector2(1200, 800), "Window size should clamp to max size")

	window.free()

func test_minimize_restore():
	print("\n--- Minimize/Restore Tests ---")

	var window = FloatingWindow.new()
	window._ready()  # Setup structure

	# Test 1: Window starts not minimized
	assert_false(window.is_minimized, "Window should start not minimized")

	# Test 2: Minimize window
	window.minimize()
	assert_true(window.is_minimized, "Window should be minimized")
	assert_false(window.content_container.visible, "Content should be hidden when minimized")

	# Test 3: Restore window
	window.restore()
	assert_false(window.is_minimized, "Window should be restored")
	assert_true(window.content_container.visible, "Content should be visible when restored")

	window.free()

func test_window_visibility():
	print("\n--- Window Visibility Tests ---")

	var window = FloatingWindow.new()
	window._ready()  # Setup structure

	# Test 1: Window starts visible
	assert_true(window.visible, "Window should start visible")

	# Test 2: Close window
	window.close()
	assert_false(window.visible, "Window should be hidden after close")

	# Test 3: Open window
	window.open()
	assert_true(window.visible, "Window should be visible after open")

	window.free()

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

func assert_not_null(value, message: String):
	_test_count += 1
	if value != null:
		_pass_count += 1
		print("  ✓ %s" % message)
	else:
		_fail_count += 1
		print("  ✗ FAILED: %s (value was null)" % message)
