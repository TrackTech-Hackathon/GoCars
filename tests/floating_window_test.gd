## Manual test for FloatingWindow
## Run this scene to test window dragging, resizing, minimize/close
## Author: Claude Code

extends Node2D

var window1: Variant = null
var window2: Variant = null

func _ready() -> void:
	print("=".repeat(70))
	print("FloatingWindow Manual Test")
	print("=".repeat(70))
	print("Instructions:")
	print("  - Drag windows by title bar")
	print("  - Resize windows by dragging edges/corners")
	print("  - Click [−] to minimize/restore")
	print("  - Click [×] to close")
	print("  - Press '1' to reopen Window 1")
	print("  - Press '2' to reopen Window 2")
	print("  - Press ESC to quit")
	print("=".repeat(70))

	# Create CanvasLayer for UI
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	# Create window 1
	var FloatingWindowClass = load("res://scripts/ui/floating_window.gd")
	window1 = FloatingWindowClass.new()
	window1.window_title = "Test Window 1"
	window1.default_position = Vector2(100, 100)
	window1.default_size = Vector2(400, 300)
	canvas_layer.add_child(window1)

	# Add some content to window 1
	var label1 = Label.new()
	label1.text = "This is a test window.\nYou can drag me by the title bar.\nYou can resize me by dragging edges/corners.\nClick [−] to minimize.\nClick [×] to close."
	window1.get_content_container().add_child(label1)

	# Create window 2
	window2 = FloatingWindowClass.new()
	window2.window_title = "Test Window 2"
	window2.default_position = Vector2(200, 200)
	window2.default_size = Vector2(350, 250)
	canvas_layer.add_child(window2)

	# Add some content to window 2
	var label2 = Label.new()
	label2.text = "This is another test window.\nTry clicking on me to bring me to front.\nTry overlapping windows!"
	window2.get_content_container().add_child(label2)

	# Connect signals
	window1.window_closed.connect(func(): print("Window 1 closed"))
	window1.window_minimized.connect(func(): print("Window 1 minimized"))
	window1.window_restored.connect(func(): print("Window 1 restored"))
	window1.window_focused.connect(func(): print("Window 1 focused"))

	window2.window_closed.connect(func(): print("Window 2 closed"))
	window2.window_minimized.connect(func(): print("Window 2 minimized"))
	window2.window_restored.connect(func(): print("Window 2 restored"))
	window2.window_focused.connect(func(): print("Window 2 focused"))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if window1:
					window1.open()
					print("Reopened Window 1")
			KEY_2:
				if window2:
					window2.open()
					print("Reopened Window 2")
			KEY_ESCAPE:
				print("Test complete!")
				get_tree().quit()
