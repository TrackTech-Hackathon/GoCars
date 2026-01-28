## Completion Summary UI Component
## Displays level completion results with stars, stats, and feedback
extends Control
class_name CompletionSummary

## Signals
signal retry_pressed
signal next_level_pressed
signal menu_pressed

## Inspector-editable properties
@export_group("Styling")
@export var title_font_size: int = 32
@export var stats_font_size: int = 20
@export var show_overlay: bool = true
@export var overlay_color: Color = Color(0, 0, 0, 0.7)

@export_group("Star Icons")
@export var star_filled_texture: Texture2D
@export var star_empty_texture: Texture2D
@export var animate_stars: bool = true

@export_group("Content")
@export var victory_messages: Array[String] = [
	"Perfect! Excellent driving!",
	"Great job! Well done!",
	"Good effort! You completed it!"
]
@export var failure_messages: Array[String] = [
	"Don't give up! Try again!",
	"You can do it! Keep trying!",
	"Almost there! One more try!"
]

## Node references
@onready var title_label: Label = $Panel/VBox/Title
@onready var star_container: HBoxContainer = $Panel/VBox/Stars
@onready var stats_container: VBoxContainer = $Panel/VBox/Stats
@onready var time_label: Label = $Panel/VBox/Stats/TimeLabel
@onready var cars_label: Label = $Panel/VBox/Stats/CarsLabel
@onready var hearts_label: Label = $Panel/VBox/Stats/HeartsLabel
@onready var feedback_label: RichTextLabel = $Panel/VBox/Feedback
@onready var tips_label: Label = $Panel/VBox/Tips
@onready var retry_button: Button = $Panel/VBox/Buttons/RetryButton
@onready var menu_button: Button = $Panel/VBox/Buttons/MenuButton
@onready var next_button: Button = $Panel/VBox/Buttons/NextButton
@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	# Set a high z-index to ensure this UI appears on top of other controls
	z_index = 20

	# Connect button signals
	if retry_button:
		retry_button.pressed.connect(func(): retry_pressed.emit())
	if menu_button:
		menu_button.pressed.connect(func(): menu_pressed.emit())
	if next_button:
		next_button.pressed.connect(func(): next_level_pressed.emit())

	# Apply Inspector settings
	if overlay:
		overlay.visible = show_overlay
		overlay.color = overlay_color
		# Block mouse input from passing through to elements below
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Connect to visibility changes to re-enable code editor when hidden
	visibility_changed.connect(_on_visibility_changed)

	hide()

## Handle visibility changes to manage code editor state
func _on_visibility_changed() -> void:
	if not visible:
		_enable_code_editor()

## Show victory screen
func show_victory(level_name: String, stars: int, time: float, best_time: float,
				  cars_completed: int, total_cars: int, hearts: int, max_hearts: int,
				  has_next_level: bool) -> void:

	# Set title
	if title_label:
		title_label.text = "%s\nCOMPLETE!" % level_name

	# Display stars
	_display_stars(stars)

	# Display stats
	if time_label:
		var time_str = _format_time(time)
		var best_str = _format_time(best_time)
		var new_best = ""
		if time < best_time || best_time == 0.0:
			new_best = " [color=green]NEW BEST![/color]"
		time_label.text = "Time: %s (Best: %s)%s" % [time_str, best_str, new_best]

	if cars_label:
		cars_label.text = "Cars: %d/%d" % [cars_completed, total_cars]

	if hearts_label:
		hearts_label.text = "Hearts: %s" % _format_hearts(hearts, max_hearts)

	# Show stats container
	if stats_container:
		stats_container.visible = true

	# Feedback message based on stars
	if feedback_label:
		var message = victory_messages[clampi(stars - 1, 0, victory_messages.size() - 1)]
		feedback_label.text = "[center]%s[/center]" % message

	# Hide tips for victory
	if tips_label:
		tips_label.visible = false

	# Show/hide Next button
	if next_button:
		next_button.visible = has_next_level

	# Disable code editor to prevent input conflicts
	_disable_code_editor()

	show()

## Show failure screen
func show_failure(level_name: String, reason: String, hint: String) -> void:
	# Set title
	if title_label:
		title_label.text = "%s\nFAILED" % level_name

	# Hide stars
	if star_container:
		star_container.visible = false

	# Hide stats
	if stats_container:
		stats_container.visible = false

	# Show failure reason and hint
	if feedback_label:
		feedback_label.text = "[center][color=red]%s[/color][/center]" % reason

	if tips_label:
		tips_label.visible = true
		tips_label.text = hint

	# Hide Next button
	if next_button:
		next_button.visible = false

	# Disable code editor to prevent input conflicts
	_disable_code_editor()

	show()

## Display star rating with optional animation
func _display_stars(count: int) -> void:
	if not star_container:
		return

	star_container.visible = true

	# Clear existing stars
	for child in star_container.get_children():
		child.queue_free()

	# Create 3 stars
	for i in range(3):
		var star = TextureRect.new()
		star.custom_minimum_size = Vector2(40, 40)
		star.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		if i < count && star_filled_texture:
			star.texture = star_filled_texture

			# Animate if enabled
			if animate_stars:
				star.scale = Vector2.ZERO
				var tween = create_tween()
				tween.tween_property(star, "scale", Vector2.ONE, 0.3).set_delay(i * 0.2)
				tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		elif star_empty_texture:
			star.texture = star_empty_texture
		else:
			# Fallback: use text if no textures
			star.queue_free()
			var label = Label.new()
			label.text = "★" if i < count else "☆"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 40)
			star_container.add_child(label)
			continue

		star_container.add_child(star)

## Format time as MM:SS.s
func _format_time(seconds: float) -> String:
	var mins = int(seconds / 60)
	var secs = fmod(seconds, 60.0)
	return "%02d:%04.1f" % [mins, secs]

## Format hearts as emoji string
func _format_hearts(current: int, maximum: int) -> String:
	var result = ""
	for i in range(maximum):
		result += "❤" if i < current else "○"
	return result

## Disable code editor to prevent input conflicts
func _disable_code_editor() -> void:
	var code_editor = get_tree().get_root().find_child("CodeEditor", true, false)
	if code_editor:
		code_editor.editable = false
		code_editor.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Re-enable code editor when panel is hidden
func _enable_code_editor() -> void:
	var code_editor = get_tree().get_root().find_child("CodeEditor", true, false)
	if code_editor:
		code_editor.editable = true
		code_editor.mouse_filter = Control.MOUSE_FILTER_STOP
