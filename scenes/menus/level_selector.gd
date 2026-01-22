extends Control

## Level Selector Scene
## Full-screen menu for selecting which level to play
## Dynamically loads levels from the levelmaps folder

const LEVELS_PATH: String = "res://scenes/levelmaps/"

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

	# Dynamically load levels from levelmaps folder
	var level_paths = _scan_levels_folder()

	# Create buttons for each level
	for level_path in level_paths:
		var level_id = level_path.get_file().get_basename()
		var level_display_name = _get_level_display_name(level_path)

		var btn = Button.new()

		# Show best time if available
		var btn_text = level_display_name
		if GameData and GameData.has_best_time(level_id):
			var best_time = GameData.get_best_time(level_id)
			btn_text += " [Best: %s]" % _format_time(best_time)
		btn.text = btn_text
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


## Scan the levelmaps folder for .tscn files
func _scan_levels_folder() -> Array[String]:
	var level_paths: Array[String] = []

	var dir = DirAccess.open(LEVELS_PATH)
	if dir == null:
		push_warning("Could not open levels folder: %s" % LEVELS_PATH)
		return level_paths

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			level_paths.append(LEVELS_PATH + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort alphabetically/numerically
	level_paths.sort()
	return level_paths


## Get level display name from the LevelName label in the scene
func _get_level_display_name(level_path: String) -> String:
	var scene = load(level_path)
	if scene == null:
		return level_path.get_file().get_basename()

	var instance = scene.instantiate()
	var display_name = ""

	# Look for LevelInfo/LevelName label
	var level_info = instance.get_node_or_null("LevelInfo")
	if level_info:
		var level_name_label = level_info.get_node_or_null("LevelName")
		if level_name_label and level_name_label is Label:
			display_name = level_name_label.text.strip_edges()

	instance.queue_free()

	if display_name.is_empty():
		return level_path.get_file().get_basename()
	return display_name


func _on_level_pressed(level_id: String) -> void:
	# Store selected level in GameState autoload
	GameState.selected_level_id = level_id

	# All levels in levelmaps folder use the TileMap system
	get_tree().change_scene_to_file("res://scenes/main_tilemap.tscn")


## Format time as MM:SS.ms
func _format_time(time: float) -> String:
	if time < 0:
		return "--:--.--"
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
