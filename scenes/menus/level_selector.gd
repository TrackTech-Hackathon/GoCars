extends Control

## Level Selector Scene
## Full-screen menu for selecting which level to play

func _ready() -> void:
	# Lower music volume for level selector
	if MusicManager:
		MusicManager.lower_volume()
	
	# Set to full screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Create dark background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Create centered container
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	# Main panel
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(500, 750)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.18, 0.98)
	panel_style.border_color = Color(0.3, 0.3, 0.35, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 30
	vbox.offset_bottom = -30
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "GoCars"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Select a Level"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(subtitle)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# Level data: [id, name, description]
	# Levels with [BUILD] have road editing enabled
	var levels = [
		["T1", "First Drive", "Learn car.go()"],
		["T2", "Stop Sign", "Learn car.stop()"],
		["T3", "Turn Ahead", "Turns [BUILD]"],
		["T5", "Traffic Jam", "Multi-car [BUILD]"],
		["C1", "Smallville", "Variables"],
		["C2", "Red Light", "If statements"],
		["C3", "Jaro Crossroads", "elif/else [BUILD]"],
		["C5", "Molo Mansion", "Comparisons [BUILD]"],
		["W1", "Ferry Dock", "While loops"],
		["W3", "Fort San Pedro", "For loops [BUILD]"],
		["W5", "Guimaras Ferry", "Break [BUILD]"]
	]

	# Create buttons for each level
	for level_data in levels:
		var level_id = level_data[0]
		var level_name = level_data[1]
		var level_desc = level_data[2]

		var btn = Button.new()
		btn.text = "%s: %s - %s" % [level_id, level_name, level_desc]
		btn.custom_minimum_size = Vector2(0, 55)
		btn.add_theme_font_size_override("font_size", 18)

		# Normal style
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.2, 0.24, 1.0)
		btn_style.border_color = Color(0.3, 0.3, 0.35, 1.0)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(8)
		btn_style.content_margin_left = 20
		btn_style.content_margin_right = 20
		btn.add_theme_stylebox_override("normal", btn_style)

		# Hover style
		var btn_hover = StyleBoxFlat.new()
		btn_hover.bg_color = Color(0.28, 0.28, 0.32, 1.0)
		btn_hover.border_color = Color(0.4, 0.5, 0.6, 1.0)
		btn_hover.set_border_width_all(2)
		btn_hover.set_corner_radius_all(8)
		btn_hover.content_margin_left = 20
		btn_hover.content_margin_right = 20
		btn.add_theme_stylebox_override("hover", btn_hover)

		# Pressed style
		var btn_pressed = StyleBoxFlat.new()
		btn_pressed.bg_color = Color(0.15, 0.15, 0.18, 1.0)
		btn_pressed.border_color = Color(0.3, 0.4, 0.5, 1.0)
		btn_pressed.set_border_width_all(2)
		btn_pressed.set_corner_radius_all(8)
		btn_pressed.content_margin_left = 20
		btn_pressed.content_margin_right = 20
		btn.add_theme_stylebox_override("pressed", btn_pressed)

		btn.pressed.connect(_on_level_pressed.bind(level_id))
		vbox.add_child(btn)


func _on_level_pressed(level_id: String) -> void:
	# Store selected level in GameState autoload
	GameState.selected_level_id = level_id

	# Change to main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")
