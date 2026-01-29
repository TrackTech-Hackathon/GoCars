extends Control

## Level Selector Scene
## Full-screen menu for selecting which level to play
## Dynamically loads levels from the levelmaps folder

# Preload LevelManifest for exported builds (DirAccess doesn't work with packed resources)
const LevelManifestClass = preload("res://scripts/core/level_manifest.gd")

# ============================================
# Configuration (exported for easy editing)
# ============================================

@export_group("Paths")
@export var levels_path: String = "res://scenes/levelmaps/"
@export var game_scene_path: String = "res://scenes/main_tilemap.tscn"

@export_group("Text")
@export var best_time_format: String = " [Best: %s]"

# ============================================
# Node References (from scene tree)
# ============================================
@onready var background: ColorRect = $Background
@onready var center_container: CenterContainer = $CenterContainer
@onready var main_panel: Panel = $CenterContainer/MainPanel
@onready var content_vbox: VBoxContainer = $CenterContainer/MainPanel/ContentMargin/ContentVBox
@onready var title_label: Label = $CenterContainer/MainPanel/ContentMargin/ContentVBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/MainPanel/ContentMargin/ContentVBox/SubtitleLabel
@onready var level_buttons_container: VBoxContainer = $CenterContainer/MainPanel/ContentMargin/ContentVBox/LevelButtonsContainer
@onready var button_template: Button = $CenterContainer/MainPanel/ContentMargin/ContentVBox/LevelButtonsContainer/LevelButtonTemplate

var level_buttons: Array[Button] = []

func _ready() -> void:
	# Lower music volume for level selector
	if MusicManager:
		MusicManager.lower_volume()

	_populate_levels()


## Populate level buttons dynamically
func _populate_levels() -> void:
	var level_paths = _scan_levels_folder()

	for level_path in level_paths:
		var level_id = level_path.get_file().get_basename()
		var level_display_name = _get_level_display_name(level_path)
		var btn = _create_level_button(level_id, level_display_name)
		level_buttons_container.add_child(btn)
		level_buttons.append(btn)


## Create a styled level button by duplicating the template
func _create_level_button(level_id: String, display_name: String) -> Button:
	var btn = button_template.duplicate()
	btn.name = "LevelButton_" + level_id
	btn.visible = true

	# Show best time if available
	var btn_text = display_name
	if GameData and GameData.has_best_time(level_id):
		var best_time = GameData.get_best_time(level_id)
		btn_text += best_time_format % _format_time(best_time)
	btn.text = btn_text

	btn.pressed.connect(_on_level_pressed.bind(level_id))
	return btn


# ============================================
# Level Loading
# ============================================

## Scan the levelmaps folder for .tscn files
## Uses DirAccess in editor, falls back to LevelManifest in exported builds
func _scan_levels_folder() -> Array[String]:
	var level_paths: Array[String] = []

	# Try DirAccess first (works in editor)
	var dir = DirAccess.open(levels_path)
	if dir != null:
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

	# Fallback to LevelManifest for exported builds
	push_warning("DirAccess failed, using LevelManifest fallback for: %s" % levels_path)
	var root_levels = LevelManifestClass.get_root_levels()
	for level_path in root_levels:
		level_paths.append(level_path)
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


# ============================================
# Event Handlers
# ============================================

func _on_level_pressed(level_id: String) -> void:
	# Store selected level in GameState autoload
	GameState.selected_level_id = level_id

	# All levels in levelmaps folder use the TileMap system (async to prevent freezing)
	SceneLoader.load_scene_async(game_scene_path)


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
# Public API for runtime customization
# ============================================

## Update title text at runtime
func set_title(new_title: String) -> void:
	if title_label:
		title_label.text = new_title


## Update subtitle text at runtime
func set_subtitle(new_subtitle: String) -> void:
	if subtitle_label:
		subtitle_label.text = new_subtitle


## Update background color at runtime
func set_background_color(color: Color) -> void:
	if background:
		background.color = color


## Refresh the level list (call after adding new levels)
func refresh_levels() -> void:
	# Remove existing level buttons
	for btn in level_buttons:
		btn.queue_free()
	level_buttons.clear()
	
	# Re-populate
	_populate_levels()
