extends Control

## Campaign Menu - Main Level Selector
## Uses the island map visual with clickable level markers
## Dynamically loads levels from levelmaps folder and assigns to markers

# ============================================
# Configuration
# ============================================

@export_group("Paths")
@export var levels_path: String = "res://scenes/levelmaps/"
@export var game_scene_path: String = "res://scenes/main_tilemap.tscn"

@export_group("Level Markers")
@export var level_markers: Array[NodePath] = []

# Node references
var level_marker_buttons: Array[TextureButton] = []
var level_data: Array[Dictionary] = []

# Hover info panel references
@onready var hover_panel: TextureRect = $HoverIloilo
@onready var hover_title: Label = $HoverIloilo/Logo
@onready var hover_objective: Label = $HoverIloilo/Objective
@onready var hover_difficulty: Label = $HoverIloilo/Difficulty
@onready var hover_description: Label = $HoverIloilo/Description
@onready var hover_play_button: TextureButton = $HoverIloilo/TextureButton

var current_hover_level_id: String = ""

func _ready() -> void:
	# Lower music volume for campaign menu
	if MusicManager:
		MusicManager.lower_volume()
	
	# Debug print all label properties at runtime
	print("=== RUNTIME LABEL DEBUG ===")
	if hover_title:
		print("Title visible: ", hover_title.visible, " modulate: ", hover_title.modulate, " is_visible_in_tree: ", hover_title.is_visible_in_tree())
		print("Title position: ", hover_title.position, " size: ", hover_title.size, " z_index: ", hover_title.z_index)
		print("Title text: '", hover_title.text, "'")
	if hover_difficulty:
		print("Difficulty visible: ", hover_difficulty.visible, " modulate: ", hover_difficulty.modulate)
	if hover_objective:
		print("Objective visible: ", hover_objective.visible, " modulate: ", hover_objective.modulate)
	if hover_description:
		print("Description visible: ", hover_description.visible, " modulate: ", hover_description.modulate)
	if hover_panel:
		print("Panel modulate: ", hover_panel.modulate, " visible: ", hover_panel.visible)
	print("=========================")
	
	# Initialize hover panel - start hidden with correct alpha
	if hover_panel:
		hover_panel.modulate.a = 1.0  # Set to full opacity (labels will inherit this)
		hover_panel.visible = false  # But keep hidden until hover
	
	# Connect play button in hover panel
	if hover_play_button:
		hover_play_button.pressed.connect(_on_hover_play_pressed)
	
	_collect_level_markers()
	_load_level_data()
	_setup_level_markers()


## Collect all level marker buttons from the scene
func _collect_level_markers() -> void:
	# Find all Level_X buttons in MapIsland
	var map_island = $CM_CampaignMenu/MapAspect/MapIsland
	if map_island:
		for child in map_island.get_children():
			if child is TextureButton and child.name.begins_with("Level_"):
				level_marker_buttons.append(child)
	
	# Sort by name to ensure Level_1, Level_2, etc.
	level_marker_buttons.sort_custom(func(a, b): return a.name < b.name)


## Load level data from levelmaps folder
func _load_level_data() -> void:
	var level_paths = _scan_levels_folder()
	
	for level_path in level_paths:
		var level_id = level_path.get_file().get_basename()
		var level_display_name = _format_level_name(level_id)
		
		level_data.append({
			"id": level_id,
			"path": level_path,
			"display_name": level_display_name
		})


## Setup level markers with level data
func _setup_level_markers() -> void:
	print("Setting up %d level markers with %d level data entries" % [level_marker_buttons.size(), level_data.size()])
	
	for i in range(min(level_marker_buttons.size(), level_data.size())):
		var marker = level_marker_buttons[i]
		var data = level_data[i]
		
		print("  Marker %d (%s): level_id='%s', path='%s'" % [i, marker.name, data["id"], data["path"]])
		
		# Update the label text with level number
		var label = marker.get_node_or_null("Label")
		if label:
			label.text = str(i + 1)
		
		# Connect to level selection
		if not marker.pressed.is_connected(_on_level_marker_pressed):
			marker.pressed.connect(_on_level_marker_pressed.bind(data["id"]))
			print("    Connected marker to level_id: %s" % data["id"])
		
		# Connect hover events
		if not marker.mouse_entered.is_connected(_on_marker_hover_start):
			marker.mouse_entered.connect(_on_marker_hover_start.bind(i))
		if not marker.mouse_exited.is_connected(_on_marker_hover_end):
			marker.mouse_exited.connect(_on_marker_hover_end)
	
	# Hide markers that don't have levels
	for i in range(level_data.size(), level_marker_buttons.size()):
		level_marker_buttons[i].visible = false
		print("  Hiding marker %d (no level data)" % i)


## Show hover panel with level info
func _on_marker_hover_start(marker_index: int) -> void:
	print("HOVER START - Marker index: %d" % marker_index)
	
	if marker_index < 0 or marker_index >= level_data.size():
		print("  ERROR: Invalid marker_index")
		return
	
	var data = level_data[marker_index]
	current_hover_level_id = data["id"]
	print("  Level ID: %s, Display Name: %s" % [data["id"], data["display_name"]])
	
	# Update panel content
	if hover_title:
		hover_title.text = "• LEVEL %d" % (marker_index + 1)
		print("  Set title to: %s" % hover_title.text)
	else:
		print("  ERROR: hover_title is null!")
	
	if hover_difficulty:
		# Show difficulty with stars and best time if available
		var num_stars = min(marker_index + 1, 5)
		var num_empty = 5 - num_stars
		var stars = ""
		var empty = ""
		for i in range(num_stars):
			stars += "★"
		for i in range(num_empty):
			empty += "☆"
		hover_difficulty.text = "Difficulty: " + stars + empty
		print("  Set difficulty to: %s" % hover_difficulty.text)
	else:
		print("  ERROR: hover_difficulty is null!")
	
	if hover_objective:
		# Show level name and best time
		var obj_text = data["display_name"]
		if GameData and GameData.has_best_time(data["id"]):
			var best_time = GameData.get_best_time(data["id"])
			obj_text += "\nBest Time: " + _format_time(best_time)
		else:
			obj_text += "\nBest Time: --:--"
		hover_objective.text = obj_text
		print("  Set objective to: %s" % hover_objective.text)
	else:
		print("  ERROR: hover_objective is null!")
	
	if hover_description:
		hover_description.text = "Navigate your car through the roads and reach the goal. Use Python code to control your vehicle."
		print("  Set description to: %s" % hover_description.text)
	else:
		print("  ERROR: hover_description is null!")
	
	# Show panel with fade-in
	if hover_panel:
		hover_panel.visible = true
		var tween = create_tween()
		tween.tween_property(hover_panel, "modulate:a", 1.0, 0.2)
		print("  Panel shown")
	else:
		print("  ERROR: hover_panel is null!")


## Hide hover panel
func _on_marker_hover_end() -> void:
	if hover_panel:
		var tween = create_tween()
		tween.tween_property(hover_panel, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): hover_panel.visible = false)


## Play button in hover panel clicked
func _on_hover_play_pressed() -> void:
	if current_hover_level_id != "":
		_on_level_marker_pressed(current_hover_level_id)


# ============================================
# Level Loading
# ============================================
# ============================================

## Scan the levelmaps folder for .tscn files
func _scan_levels_folder() -> Array[String]:
	var level_paths: Array[String] = []
	
	var dir = DirAccess.open(levels_path)
	if dir == null:
		push_warning("Could not open levels folder: %s" % levels_path)
		return level_paths
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			level_paths.append(levels_path + file_name)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort alphabetically/numerically
	level_paths.sort()
	return level_paths


## Format level name from filename
func _format_level_name(level_id: String) -> String:
	# Convert filename to nice display name
	# e.g., "level_01" -> "Level 1", "tutorial_intro" -> "Tutorial Intro"
	var display_name = level_id.replace("_", " ")
	display_name = display_name.capitalize()
	return display_name


# ============================================
# Event Handlers
# ============================================

func _on_level_marker_pressed(level_id: String) -> void:
	print("Level marker pressed! Level ID: %s" % level_id)
	
	# Store selected level in GameState autoload
	GameState.selected_level_id = level_id
	print("Set GameState.selected_level_id to: %s" % GameState.selected_level_id)
	
	# All levels in levelmaps folder use the TileMap system
	print("Changing scene to: %s" % game_scene_path)
	get_tree().change_scene_to_file(game_scene_path)


# ============================================
# Utilities
# ============================================

## Format time as MM:SS.ms
func _format_time(time: float) -> String:
	if time < 0:
		return "--:--.--"
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


# ============================================
# Public API
# ============================================

## Get level data for a specific marker index
func get_level_data_for_marker(marker_index: int) -> Dictionary:
	if marker_index >= 0 and marker_index < level_data.size():
		return level_data[marker_index]
	return {}


## Refresh the level markers (call after adding new levels)
func refresh_levels() -> void:
	level_data.clear()
	_load_level_data()
	_setup_level_markers()
