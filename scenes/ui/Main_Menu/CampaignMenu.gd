extends Control

## Campaign Menu - Map-based Level Selector
## Features:
## - 5 Map pins (Tutorial, Iloilo, Antique, Aklan, Capiz)
## - Clicking a pin shows map hover panel
## - Clicking pin again or Play opens level selector for that map
## - Levels load dynamically from levelmaps subfolder
## - Level unlock system (previous level must be beaten)

# ============================================
# Configuration
# ============================================

@export_group("Paths")
@export var levels_base_path: String = "res://scenes/levelmaps/"
@export var game_scene_path: String = "res://scenes/main_tilemap.tscn"

# Map folder names (must match folder names in levelmaps/)
const MAP_FOLDERS: Array[String] = [
	"01Tutorial",
	"02Iloilo",
	"03Antique",
	"04Aklan",
	"05Capiz"
]

# Map display names
const MAP_DISPLAY_NAMES: Dictionary = {
	"01Tutorial": "TUTORIAL",
	"02Iloilo": "ILOILO",
	"03Antique": "ANTIQUE",
	"04Aklan": "AKLAN",
	"05Capiz": "CAPIZ"
}

# Map descriptions
const MAP_DESCRIPTIONS: Dictionary = {
	"01Tutorial": "Learn the basics of controlling cars with Python code. Master movement, turning, and navigation.",
	"02Iloilo": "Navigate the busy streets of Iloilo City. Handle traffic lights and complex intersections.",
	"03Antique": "Coming Soon! Explore the scenic roads of Antique province.",
	"04Aklan": "Coming Soon! Drive through the beautiful landscapes of Aklan.",
	"05Capiz": "Coming Soon! Discover the unique roads of Capiz province."
}

# ============================================
# Node References
# ============================================

# Map Pins (set in _ready based on scene structure)
var map_pins: Array[TextureButton] = []
var current_selected_map: int = -1

# Panels
@onready var hover_panel: TextureRect = $HoverPanel
@onready var hover_title: Label = $HoverPanel/Logo
@onready var hover_difficulty: Label = $HoverPanel/Difficulty
@onready var hover_description: Label = $HoverPanel/Description
@onready var hover_status: Label = $HoverPanel/Status
@onready var hover_play_button: TextureButton = $HoverPanel/PlayButton

# Level Selector Panel
@onready var level_selector_panel: Control = $LevelSelectorPanel
@onready var level_selector_title: Label = $LevelSelectorPanel/PanelBG/Title
@onready var level_list_container: VBoxContainer = $LevelSelectorPanel/PanelBG/ScrollContainer/LevelList
@onready var level_selector_back: TextureButton = $LevelSelectorPanel/PanelBG/BackButton

# Level Hover Panel (when hovering a level in level selector)
@onready var level_hover_panel: Control = $LevelHoverPanel
@onready var level_hover_name: Label = $LevelHoverPanel/PanelBG/LevelName
@onready var level_hover_time: Label = $LevelHoverPanel/PanelBG/BestTime
@onready var level_hover_status: Label = $LevelHoverPanel/PanelBG/Status
@onready var level_hover_play: TextureButton = $LevelHoverPanel/PanelBG/PlayButton

# ============================================
# State
# ============================================

var map_levels_cache: Dictionary = {}  # map_folder -> Array of level data
var current_selected_level: Dictionary = {}
var level_buttons: Array[Button] = []

func _ready() -> void:
	# Lower music volume for campaign menu
	if MusicManager:
		MusicManager.lower_volume()

	_collect_map_pins()
	_setup_map_pins()
	_cache_all_levels()
	_hide_all_panels()

	# Connect level selector back button
	if level_selector_back:
		level_selector_back.pressed.connect(_on_level_selector_back)

	# Connect hover panel play button
	if hover_play_button:
		hover_play_button.pressed.connect(_on_hover_play_pressed)

	# Connect level hover play button
	if level_hover_play:
		level_hover_play.pressed.connect(_on_level_hover_play_pressed)


## Collect map pin nodes (MapPin_1 to MapPin_5)
func _collect_map_pins() -> void:
	var map_island = $CM_CampaignMenu/MapAspect/MapIsland
	if not map_island:
		push_warning("MapIsland node not found!")
		return

	for i in range(1, 6):
		var pin_name = "MapPin_%d" % i
		var pin = map_island.get_node_or_null(pin_name)
		if pin and pin is TextureButton:
			map_pins.append(pin)
		else:
			# Fallback: try Level_X naming
			pin_name = "Level_%d" % i
			pin = map_island.get_node_or_null(pin_name)
			if pin and pin is TextureButton:
				map_pins.append(pin)


## Setup map pin connections
func _setup_map_pins() -> void:
	for i in range(map_pins.size()):
		var pin = map_pins[i]

		# Update label with map number
		var label = pin.get_node_or_null("Label")
		if label:
			label.text = str(i + 1)

		# Connect pressed signal
		if not pin.pressed.is_connected(_on_map_pin_pressed):
			pin.pressed.connect(_on_map_pin_pressed.bind(i))


## Cache levels from all map folders
func _cache_all_levels() -> void:
	for folder in MAP_FOLDERS:
		var folder_path = levels_base_path + folder + "/"
		var levels = _scan_folder_for_levels(folder_path)
		map_levels_cache[folder] = levels


## Scan a folder for level files
func _scan_folder_for_levels(folder_path: String) -> Array:
	var levels: Array = []

	var dir = DirAccess.open(folder_path)
	if dir == null:
		return levels

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			var level_path = folder_path + file_name
			var level_id = file_name.get_basename()
			var display_name = _get_level_display_name(level_path, level_id)

			levels.append({
				"id": level_id,
				"path": level_path,
				"display_name": display_name
			})
		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort by filename (alphabetically/numerically)
	levels.sort_custom(func(a, b): return a["id"] < b["id"])
	return levels


## Get level display name from scene or format from id
func _get_level_display_name(level_path: String, level_id: String) -> String:
	# Try to load scene and read LevelSettings
	var scene = load(level_path)
	if scene:
		var instance = scene.instantiate()
		var display_name = ""

		# Try new LevelSettings system
		var settings_node = instance.get_node_or_null("LevelSettings")
		if settings_node:
			# Check for LevelName label (backward compat)
			var name_label = settings_node.get_node_or_null("LevelName")
			if name_label and name_label is Label:
				display_name = name_label.text.strip_edges()

		instance.queue_free()

		if not display_name.is_empty():
			return display_name

	# Fallback: format level_id nicely
	return _format_level_name(level_id)


## Format level name from filename
func _format_level_name(level_id: String) -> String:
	var display_name = level_id.replace("_", " ")
	display_name = display_name.capitalize()
	return display_name


## Hide all popup panels
func _hide_all_panels() -> void:
	if hover_panel:
		hover_panel.modulate.a = 0.0
		hover_panel.visible = false
	if level_selector_panel:
		level_selector_panel.visible = false
	if level_hover_panel:
		level_hover_panel.visible = false


# ============================================
# Map Pin Events
# ============================================

## Called when a map pin is clicked
func _on_map_pin_pressed(map_index: int) -> void:
	if map_index < 0 or map_index >= MAP_FOLDERS.size():
		return

	# If same pin clicked twice, open level selector
	if current_selected_map == map_index and hover_panel and hover_panel.visible:
		_open_level_selector(map_index)
		return

	current_selected_map = map_index
	_show_map_hover(map_index)


## Show map hover panel
func _show_map_hover(map_index: int) -> void:
	var folder = MAP_FOLDERS[map_index]
	var display_name = MAP_DISPLAY_NAMES.get(folder, folder)
	var description = MAP_DESCRIPTIONS.get(folder, "")
	var levels = map_levels_cache.get(folder, [])

	# Check if map is locked
	var is_locked = _is_map_locked(map_index)
	var is_coming_soon = levels.size() == 0

	# Update hover panel content
	if hover_title:
		hover_title.text = "* " + display_name

	if hover_difficulty:
		var num_levels = levels.size()
		var completed = _count_completed_levels(folder)
		if is_coming_soon:
			hover_difficulty.text = "Coming Soon"
		else:
			hover_difficulty.text = "Progress: %d / %d levels" % [completed, num_levels]

	if hover_description:
		hover_description.text = description

	if hover_status:
		if is_coming_soon:
			hover_status.text = "This region is not yet available."
			hover_status.visible = true
		elif is_locked:
			hover_status.text = "Complete all Tutorial levels to unlock!"
			hover_status.visible = true
		else:
			hover_status.visible = false

	if hover_play_button:
		# Disable play button if locked or coming soon
		hover_play_button.disabled = is_locked or is_coming_soon
		var play_label = hover_play_button.get_node_or_null("Button/Logo")
		if play_label:
			if is_coming_soon:
				play_label.text = "SOON"
			elif is_locked:
				play_label.text = "LOCKED"
			else:
				play_label.text = "PLAY"

	# Animate panel in
	if hover_panel:
		hover_panel.visible = true
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(hover_panel, "modulate:a", 1.0, 0.2)


## Check if a map is locked
func _is_map_locked(map_index: int) -> bool:
	# Tutorial (index 0) is always unlocked
	if map_index == 0:
		return false

	# Other maps require completing all levels of Tutorial
	var tutorial_levels = map_levels_cache.get("01Tutorial", [])
	for level_data in tutorial_levels:
		if not GameData.is_level_completed(level_data["id"]):
			return true

	return false


## Count completed levels in a map
func _count_completed_levels(folder: String) -> int:
	var levels = map_levels_cache.get(folder, [])
	var count = 0
	for level_data in levels:
		if GameData.is_level_completed(level_data["id"]):
			count += 1
	return count


## Hover panel play button pressed
func _on_hover_play_pressed() -> void:
	if current_selected_map >= 0:
		_open_level_selector(current_selected_map)


# ============================================
# Level Selector
# ============================================

## Open the level selector for a map
func _open_level_selector(map_index: int) -> void:
	if map_index < 0 or map_index >= MAP_FOLDERS.size():
		return

	var folder = MAP_FOLDERS[map_index]
	var display_name = MAP_DISPLAY_NAMES.get(folder, folder)
	var levels = map_levels_cache.get(folder, [])

	# Hide hover panel
	if hover_panel:
		var tween = create_tween()
		tween.tween_property(hover_panel, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): hover_panel.visible = false)

	# Update level selector title
	if level_selector_title:
		level_selector_title.text = display_name + " LEVELS"

	# Clear existing level buttons
	_clear_level_buttons()

	# Create level buttons
	for i in range(levels.size()):
		var level_data = levels[i]
		_create_level_button(level_data, i, folder)

	# Show level selector panel with animation
	if level_selector_panel:
		level_selector_panel.visible = true
		level_selector_panel.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(level_selector_panel, "modulate:a", 1.0, 0.2)

	# Hide level hover panel
	if level_hover_panel:
		level_hover_panel.visible = false


## Clear level buttons
func _clear_level_buttons() -> void:
	for btn in level_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	level_buttons.clear()


## Create a level button
func _create_level_button(level_data: Dictionary, index: int, map_folder: String) -> void:
	if not level_list_container:
		return

	var btn = Button.new()
	btn.name = "LevelBtn_" + level_data["id"]
	btn.custom_minimum_size = Vector2(400, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Check if level is unlocked
	var is_unlocked = _is_level_unlocked(map_folder, index)
	var is_completed = GameData.is_level_completed(level_data["id"])

	# Set button text
	var text = "%d. %s" % [index + 1, level_data["display_name"]]
	if is_completed:
		text += " [Completed]"
	elif not is_unlocked:
		text += " [Locked]"
	btn.text = text

	# Style the button
	btn.disabled = not is_unlocked

	# Connect signals
	btn.pressed.connect(_on_level_button_pressed.bind(level_data))
	btn.mouse_entered.connect(_on_level_button_hover.bind(level_data, is_unlocked))
	btn.mouse_exited.connect(_on_level_button_hover_end)

	level_list_container.add_child(btn)
	level_buttons.append(btn)


## Check if a level is unlocked
func _is_level_unlocked(map_folder: String, level_index: int) -> bool:
	# First level is always unlocked
	if level_index == 0:
		return true

	# Check if previous level is completed
	var levels = map_levels_cache.get(map_folder, [])
	if level_index > 0 and level_index <= levels.size():
		var prev_level = levels[level_index - 1]
		return GameData.is_level_completed(prev_level["id"])

	return false


## Level button pressed - show level hover or play if already selected
func _on_level_button_pressed(level_data: Dictionary) -> void:
	if current_selected_level.get("id", "") == level_data.get("id", ""):
		# Same level clicked twice, play it
		_play_level(level_data)
	else:
		current_selected_level = level_data
		_show_level_hover(level_data, true)


## Show level hover panel
func _on_level_button_hover(level_data: Dictionary, is_unlocked: bool) -> void:
	_show_level_hover(level_data, is_unlocked)


## Hide level hover panel
func _on_level_button_hover_end() -> void:
	# Don't hide if we have a selected level
	if current_selected_level.is_empty():
		if level_hover_panel:
			level_hover_panel.visible = false


## Show level hover info
func _show_level_hover(level_data: Dictionary, is_unlocked: bool) -> void:
	if not level_hover_panel:
		return

	if level_hover_name:
		level_hover_name.text = level_data.get("display_name", "Unknown")

	if level_hover_time:
		var level_id = level_data.get("id", "")
		if GameData.has_best_time(level_id):
			var best = GameData.get_best_time(level_id)
			level_hover_time.text = "Best Time: " + _format_time(best)
		else:
			level_hover_time.text = "Best Time: --:--.--"

	if level_hover_status:
		if not is_unlocked:
			level_hover_status.text = "Complete the previous level to unlock!"
			level_hover_status.visible = true
		elif GameData.is_level_completed(level_data.get("id", "")):
			level_hover_status.text = "Completed!"
			level_hover_status.visible = true
		else:
			level_hover_status.visible = false

	if level_hover_play:
		level_hover_play.disabled = not is_unlocked
		var play_label = level_hover_play.get_node_or_null("Label")
		if play_label:
			play_label.text = "LOCKED" if not is_unlocked else "PLAY"

	level_hover_panel.visible = true


## Level hover play button pressed
func _on_level_hover_play_pressed() -> void:
	if not current_selected_level.is_empty():
		_play_level(current_selected_level)


## Play a level
func _play_level(level_data: Dictionary) -> void:
	var level_id = level_data.get("id", "")
	var level_path = level_data.get("path", "")

	if level_id.is_empty() or level_path.is_empty():
		push_warning("Invalid level data!")
		return

	print("Playing level: %s (%s)" % [level_id, level_path])

	# Store in GameState
	GameState.selected_level_id = level_id
	GameState.selected_level_path = level_path

	# Change to game scene
	get_tree().change_scene_to_file(game_scene_path)


## Back button from level selector
func _on_level_selector_back() -> void:
	# Hide level selector
	if level_selector_panel:
		var tween = create_tween()
		tween.tween_property(level_selector_panel, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func(): level_selector_panel.visible = false)

	# Hide level hover
	if level_hover_panel:
		level_hover_panel.visible = false

	current_selected_level = {}

	# Show map hover again
	if current_selected_map >= 0:
		_show_map_hover(current_selected_map)


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
