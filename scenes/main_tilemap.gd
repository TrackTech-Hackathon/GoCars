extends Node2D

## Main scene controller for TileMap-based levels
## Loads level scenes from scenes/levelmaps/ and manages gameplay

# Preload scripts
const RoadTileMapLayerScript = preload("res://scripts/map_editor/road_tilemap_layer.gd")
const LevelLoaderScript = preload("res://scripts/core/level_loader.gd")
const RoadTileProxy = preload("res://scripts/map_editor/road_tile_proxy.gd")

@onready var simulation_engine: SimulationEngine = $SimulationEngine
@onready var code_editor: TextEdit = $UI/CodeEditor
@onready var run_button: Button = $UI/RunButton
@onready var status_label: Label = $UI/StatusLabel
@onready var speed_label: Label = $UI/SpeedLabel
@onready var hearts_label: Label = $UI/HeartsLabel
@onready var road_cards_label: Label = $UI/RoadCardsLabel
# Stoplights are now spawned from stoplight tiles in levels
# Use _spawned_stoplights array to access them

# New UI system
var window_manager: Variant = null
var use_new_ui: bool = true

# Result popup elements
@onready var result_popup: Panel = $UI/ResultPopup
@onready var result_title: Label = $UI/ResultPopup/ResultTitle
@onready var result_message: Label = $UI/ResultPopup/ResultMessage
@onready var retry_button: Button = $UI/ResultPopup/RetryButton
@onready var next_button: Button = $UI/ResultPopup/NextButton
var menu_button: Button = null  # Created dynamically

# Help panel elements
@onready var help_panel: Panel = $UI/HelpPanel
@onready var toggle_help_button: Button = $UI/ToggleHelpButton
@onready var menu_button_ui: Button = $UI/MenuButton

# Menu panel (created dynamically)
var menu_panel: CanvasLayer = null

# Background audio
var background_audio: AudioStreamPlayer = null
var engine_audio: AudioStreamPlayer = null
var crash_audio: AudioStreamPlayer = null
var engine_loop_start: float = 0.05
var engine_loop_end: float = 1.9

# Current line highlighting
var _current_executing_line: int = -1

# Game state
var hearts: int = 10
var road_cards: int = 10
var initial_hearts: int = 10
var initial_road_cards: int = 10

# Level management
var level_loader: LevelLoader = null
var current_level_index: int = 0
var current_level_node: Node2D = null
var road_layer: RoadTileMapLayer = null

# Tile constants
const TILE_SIZE: int = 144
const LANE_OFFSET: float = 25.0

# Camera
const CAMERA_SPEED: float = 500.0
const CAMERA_SPEED_FAST: float = 1000.0  # Speed when holding shift
const ZOOM_MIN: float = 0.25  # Maximum zoom out (smaller = see more)
const ZOOM_MAX: float = 2.0   # Maximum zoom in (larger = see less)
const ZOOM_STEP: float = 0.1  # How much to zoom per scroll
@onready var camera: Camera2D = $GameWorld/Camera2D

# Camera bounds (will be calculated based on level's Camera Border or road layer)
var camera_bounds_min: Vector2 = Vector2.ZERO
var camera_bounds_max: Vector2 = Vector2(1440, 1008)  # Default 10x7 tiles

# Car spawning
var car_spawn_timer: float = 0.0
const CAR_SPAWN_INTERVAL: float = 15.0
var spawn_data: Array = []  # From road layer
var destination_data: Array = []  # From road layer
var is_spawning_cars: bool = false
var next_car_id: int = 1
var spawned_groups: Array = []  # Track which spawn groups have already spawned a car

# LevelCars configuration - parsed from LevelSettings/LevelCars label
# Format: "Group A - Type, Color, Type, Color\nGroup B - Random, Random"
var level_cars_config: Dictionary = {}  # group_name -> Array of {type, color} options

# Spawned stoplights (from stoplight tiles)
var _spawned_stoplights: Array = []

# Tile editing state
var is_editing_enabled: bool = true
var is_building_enabled: bool = false  # Whether building roads is enabled for this level
var selected_tile_pos: Vector2i = Vector2i(-1, -1)  # Currently selected tile (-1,-1 = none)
var preview_sprite: Sprite2D = null  # Preview sprite for new tile placement
var preview_grid_pos: Vector2i = Vector2i(-1, -1)  # Grid position of preview
var tileset_texture: Texture2D = null  # Cached tileset texture for preview

# Enable Building layer (for build permissions per tile)
var enable_building_layer: TileMapLayer = null

# Selection highlight
var selection_highlight: ColorRect = null

# Timer system
var level_timer: float = 0.0
var timer_running: bool = false
var level_won: bool = false
var code_is_running: bool = false  # True when code is executing (cars moving from code)
var current_level_id: String = ""
var current_level_display_name: String = ""

# Hearts UI (loaded from level)
var hearts_ui: Node = null

# Stats UI Panel (follows mouse, shows hovered car stats)
var stats_ui_panel: Node = null


func _ready() -> void:
	# Set music volume
	if MusicManager:
		MusicManager.set_game_volume()

	# Initialize level loader
	level_loader = LevelLoaderScript.new()

	# Create stats UI panel
	_setup_stats_ui_panel()

	# Connect UI signals
	run_button.pressed.connect(_on_run_button_pressed)

	# Connect simulation signals
	simulation_engine.simulation_started.connect(_on_simulation_started)
	simulation_engine.simulation_paused.connect(_on_simulation_paused)
	simulation_engine.simulation_ended.connect(_on_simulation_ended)
	simulation_engine.car_reached_destination.connect(_on_car_reached_destination)
	simulation_engine.car_crashed.connect(_on_car_crashed)
	simulation_engine.level_completed.connect(_on_level_completed)
	simulation_engine.level_failed.connect(_on_level_failed)
	simulation_engine.execution_line_changed.connect(_on_execution_line_changed)
	simulation_engine.execution_error_occurred.connect(_on_execution_error)

	# Set callback for checking if code editor is focused (to disable shortcuts while typing)
	simulation_engine.is_editor_focused_callback = _is_code_editor_focused

	# Connect result popup buttons
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)

	# Create menu button for result popup
	_create_menu_button()

	# Connect help panel button
	toggle_help_button.pressed.connect(_on_toggle_help_pressed)

	# Connect menu button
	menu_button_ui.pressed.connect(_on_menu_button_pressed)
	
	# Create menu panel
	_create_menu_panel()

	# Note: Stoplights are spawned from tiles when level is loaded

	# Set initial code
	code_editor.text = "car.go()"

	# Setup new UI system if enabled
	if use_new_ui:
		_setup_new_ui()

	# Setup audio
	_setup_audio()

	# Load level from GameState or default to first level
	if GameState.selected_level_id != "":
		# Try to find level by name
		_load_level_by_name(GameState.selected_level_id)
	else:
		# Load first available level
		_load_level(0)

	_update_speed_label()
	_update_hearts_label()
	_update_road_cards_label()


func _process(delta: float) -> void:
	# Loop background audio
	if background_audio and background_audio.playing:
		if background_audio.get_playback_position() >= 15.0:
			background_audio.play(1.0)

	# Manual seamless loop for engine audio
	if engine_audio and engine_audio.playing:
		if engine_audio.get_playback_position() >= engine_loop_end:
			engine_audio.play(engine_loop_start)

	# Handle camera movement (WASD or Arrow keys, Shift for 2x speed)
	# Skip if code editor is focused (player is typing)
	if camera and not _is_code_editor_focused():
		var camera_velocity = Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			camera_velocity.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			camera_velocity.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			camera_velocity.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			camera_velocity.x += 1

		if camera_velocity != Vector2.ZERO:
			var speed_val = CAMERA_SPEED_FAST if Input.is_key_pressed(KEY_SHIFT) else CAMERA_SPEED
			camera.position += camera_velocity.normalized() * speed_val * delta
			_clamp_camera_to_bounds()

	# Cars only spawn once per parking spot at level start
	# No continuous spawning during gameplay

	# Update level timer
	# Timer pauses when game is paused
	if timer_running and not level_won and not get_tree().paused:
		# Before code runs: timer always at 1x speed
		# After code runs (cars moving): timer matches game speed
		if code_is_running:
			# Code is running - timer matches game speed (use delta as-is)
			level_timer += delta
		else:
			# Code not running - timer always at 1x speed (unscale delta)
			var unscaled_delta = delta / Engine.time_scale if Engine.time_scale > 0 else delta
			level_timer += unscaled_delta
		_update_timer_label()

	# Update preview tile position
	_update_preview_tile()


func _update_preview_tile() -> void:
	# Only show preview when a tile is selected and editing is enabled
	if not is_editing_enabled or selected_tile_pos == Vector2i(-1, -1) or road_layer == null:
		_hide_preview()
		return

	var mouse_pos = get_global_mouse_position()
	var mouse_grid_pos = _get_grid_from_world(mouse_pos)

	# Hide preview if mouse is on the selected tile
	if mouse_grid_pos == selected_tile_pos:
		_hide_preview()
		return

	# Hide preview if not adjacent to selected tile
	if not _is_adjacent(selected_tile_pos, mouse_grid_pos):
		_hide_preview()
		return

	var offset = mouse_grid_pos - selected_tile_pos
	var direction = _get_direction_from_offset(offset)
	if direction == "":
		_hide_preview()
		return

	# Check if there's already a road there - show connection preview
	if road_layer.has_road_at(mouse_grid_pos):
		# Check if we can connect to this tile
		if _can_connect_tiles(selected_tile_pos, mouse_grid_pos, direction):
			# Show preview of selected tile with new connection
			_show_connection_preview(selected_tile_pos, direction)
		else:
			_hide_preview()
		return

	# Empty space - show preview of new tile at this position
	var connection_dir = _get_opposite_direction(direction)
	_show_preview(mouse_grid_pos, connection_dir)


func _setup_audio() -> void:
	# Background engine sound
	background_audio = AudioStreamPlayer.new()
	background_audio.stream = load("res://assets/audio/car-engine-running.mp3")
	background_audio.volume_db = -15.0
	add_child(background_audio)
	background_audio.play(1.0)

	# Car engine sound
	engine_audio = AudioStreamPlayer.new()
	engine_audio.stream = load("res://assets/audio/engine-6000.mp3")
	engine_audio.volume_db = -20.0
	add_child(engine_audio)

	# Crash sound
	crash_audio = AudioStreamPlayer.new()
	crash_audio.stream = load("res://assets/audio/car-crash-sound-376882.mp3")
	crash_audio.volume_db = -10.0
	add_child(crash_audio)


# ============================================
# Level Loading
# ============================================

func _load_level(index: int) -> void:
	current_level_index = index

	# Clear all existing cars first
	_clear_all_cars()
	next_car_id = 1
	is_spawning_cars = false

	# Clear previous level
	if current_level_node:
		current_level_node.queue_free()
		current_level_node = null
		road_layer = null
		hearts_ui = null

	# Load new level
	current_level_node = level_loader.load_level(index)
	if current_level_node == null:
		_update_status("Failed to load level %d" % index)
		return

	# Add to scene
	$GameWorld.add_child(current_level_node)

	# Find road layer
	road_layer = current_level_node.get_node_or_null("RoadLayer") as RoadTileMapLayer
	if road_layer == null:
		_update_status("Level has no RoadLayer!")
		return

	# Get spawn and destination data
	spawn_data = road_layer.get_spawn_data()
	destination_data = road_layer.get_destination_data()

	if spawn_data.is_empty():
		_update_status("Warning: No spawn points found!")
	if destination_data.is_empty():
		_update_status("Warning: No destination points found!")

	# Spawn stoplights from stoplight tiles
	_spawn_stoplights_from_tiles()

	var level_name = level_loader.get_level_filename(index)
	current_level_id = level_name
	current_level_display_name = level_loader.get_level_name_from_instance(current_level_node)
	_update_status("Loaded level: %s" % current_level_display_name)

	# Load hearts from level's HeartsUI node if present
	_load_level_hearts()

	# Load road building configuration
	_load_level_build_roads()

	# Reset timer for new level (timer starts when level loads)
	level_timer = 0.0
	timer_running = true  # Timer starts immediately on level load
	level_won = false
	code_is_running = false  # Code not running yet - timer at 1x speed
	_update_timer_label()

	# Calculate camera bounds and set initial position
	_calculate_camera_bounds()
	_set_initial_camera_position()
	_clamp_camera_to_bounds()

	# Load car spawning configuration
	_load_level_cars_config()

	# Spawn initial cars at game start (before player runs code)
	_spawn_initial_cars()

	# Start tutorial if this level has one
	_start_tutorial_if_available()


func _load_level_by_name(level_name: String) -> void:
	var paths = level_loader.get_level_paths()
	for i in range(paths.size()):
		# Match by filename (level_01, level_02, etc.)
		if level_loader.get_level_filename(i) == level_name:
			_load_level(i)
			return

	# Fallback to first level
	_load_level(0)


func _load_next_level() -> void:
	var next_index = current_level_index + 1
	if next_index < level_loader.get_level_count():
		_load_level(next_index)
	else:
		_update_status("All levels completed!")


# ============================================
# Road Checker Interface (for Vehicle)
# ============================================

## Check if there's a road at the given world position
func is_road_at_position(world_pos: Vector2) -> bool:
	if road_layer == null:
		return false
	return road_layer.is_road_at_position(world_pos)


## Check if road at from_grid has a connection in the specified direction
func is_road_connected(from_grid: Vector2i, connection_dir: String) -> bool:
	if road_layer == null:
		return false
	return road_layer.has_connection(from_grid, connection_dir)


## Get a tile proxy that provides the same interface as the old RoadTile class
## Vehicle code expects get_road_tile() to return something with get_available_exits() and get_guideline_path()
func get_road_tile(grid_pos: Vector2i) -> RoadTileProxy:
	if road_layer == null or not road_layer.has_road_at(grid_pos):
		return null
	return RoadTileProxy.new(road_layer, grid_pos)


## Get tile size
func get_tile_size() -> float:
	return float(TILE_SIZE)


# ============================================
# Car Spawning
# ============================================

func _spawn_initial_cars() -> void:
	# Reset spawned groups tracking
	spawned_groups.clear()

	# Spawn one car at each spawn point when level loads
	# This lets players see what cars they're dealing with before running code
	for spawn in spawn_data:
		var group = spawn.get("group", "")
		# Convert group to string if it's not already
		if typeof(group) != TYPE_STRING:
			group = str(group)
		# Only spawn if this group hasn't spawned yet (one car per parking spot)
		if group == "" or group not in spawned_groups:
			_spawn_car_at(spawn)
			if group != "":
				spawned_groups.append(group)


func _spawn_new_car() -> void:
	# Cars only spawn once per parking spot - no continuous spawning
	# This function is now only called for initial spawning or manual triggers
	if spawn_data.is_empty():
		_update_status("No spawn points available!")
		return

	# Find a spawn point that hasn't been used yet
	var available_spawns: Array = []
	for spawn in spawn_data:
		var group = spawn.get("group", "")
		# Convert group to string if it's not already
		if typeof(group) != TYPE_STRING:
			group = str(group)
		if group == "" or group not in spawned_groups:
			available_spawns.append(spawn)

	if available_spawns.is_empty():
		_update_status("All spawn points have been used!")
		return

	var spawn = available_spawns[randi() % available_spawns.size()]
	var car = _spawn_car_at(spawn)

	# Track that this group has spawned
	var group = spawn.get("group", "")
	# Convert group to string if it's not already
	if typeof(group) != TYPE_STRING:
		group = str(group)
	if group != "" and group not in spawned_groups:
		spawned_groups.append(group)

	# Execute current code on the new car
	if car and is_spawning_cars:
		var code = code_editor.text
		if window_manager:
			code = window_manager.get_current_code() if window_manager.has_method("get_current_code") else code_editor.text
		simulation_engine.execute_code_for_vehicle(code, car)


func _spawn_car_at(spawn: Dictionary) -> Vehicle:
	# Get spawn group for this spawn point
	var group_name = spawn.get("group", "")
	# Convert group_name to string if it's not already
	if typeof(group_name) != TYPE_STRING:
		group_name = str(group_name)

	# Get car configuration from LevelCars config
	var car_config = _get_car_config_for_group(group_name)
	var car_type = car_config.get("type", "Random")
	var car_color = car_config.get("color", "Random")

	# Determine which scene to load
	var vehicle_scene: Resource = null
	var scene_path = _get_scene_path_for_type(car_type)

	if scene_path != "":
		# Specific type requested
		vehicle_scene = load(scene_path)
	else:
		# Random type - pick from all available
		var car_scenes = [
			"res://scenes/entities/car_sedan.tscn",
			"res://scenes/entities/car_estate.tscn",
			"res://scenes/entities/car_sport.tscn",
			"res://scenes/entities/car_micro.tscn",
			"res://scenes/entities/car_pickup.tscn",
			"res://scenes/entities/car_jeepney.tscn",
			"res://scenes/entities/car_jeepney_2.tscn",
			"res://scenes/entities/car_bus.tscn"
		]
		var random_index = randi() % car_scenes.size()
		vehicle_scene = load(car_scenes[random_index])

	if vehicle_scene == null:
		_update_status("Error: Could not load vehicle scene")
		return null

	# Create vehicle
	var new_car = vehicle_scene.instantiate() as Vehicle
	new_car.vehicle_id = "car%d" % next_car_id
	next_car_id += 1

	# Set position and direction from spawn data
	new_car.global_position = spawn["position"]
	new_car.direction = spawn["direction"]
	new_car.rotation = spawn["rotation"]

	# Set spawn group if present
	if spawn.has("group"):
		new_car.set_spawn_group(spawn["group"])

	# Initialize navigation state for proper guideline following
	# The entry_dir tells us what direction the car will enter the NEXT tile from
	# So _last_exit_direction should be the opposite (the direction it's traveling)
	var exit_dir = _get_opposite_direction(spawn.get("entry_dir", ""))
	var entry_dir = spawn.get("entry_dir", "")
	if exit_dir != "":
		new_car._last_exit_direction = exit_dir
		new_car._current_tile = spawn.get("grid_pos", Vector2i(-1, -1))
		# Initialize locked entry direction for road detection (prevents dead_end() false positive)
		new_car._locked_entry_direction = entry_dir
		new_car._entry_direction = entry_dir

	# Set all destinations (car can reach ANY parking spot)
	if not destination_data.is_empty():
		new_car.set_all_destinations(destination_data)
		# Also set first one as fallback for backwards compatibility
		new_car.destination = destination_data[0]["position"]

	# Set color based on LevelCars config
	var color_index = _get_color_index_for_name(car_color)
	if color_index >= 0:
		# Specific color requested
		new_car.set_color_palette_index(color_index)
	else:
		# Random color - uses rarity system
		new_car.set_random_color()

	# Add to scene
	$GameWorld.add_child(new_car)

	# Set road checker reference (this scene implements the interface)
	new_car.set_road_checker(self)

	# Register with simulation engine
	simulation_engine.register_vehicle(new_car)

	# Connect signals
	new_car.reached_destination.connect(_on_car_reached_destination)
	new_car.crashed.connect(_on_car_crashed)
	new_car.off_road_crash.connect(_on_car_off_road)
	new_car.ran_red_light.connect(_on_car_ran_red_light)

	# Make aware of all spawned stoplights
	for stoplight in _spawned_stoplights:
		new_car.add_stoplight(stoplight)

	var group_str = new_car.get_spawn_group_name()
	var color_str = new_car.get_color_name() if new_car.has_method("get_color_name") else "?"
	_update_status("Spawned %s (%s): %s (Group %s)" % [new_car.get_vehicle_type_name(), color_str, new_car.vehicle_id, group_str])
	return new_car


## Get opposite direction string
func _get_opposite_direction(dir: String) -> String:
	match dir:
		"top": return "bottom"
		"bottom": return "top"
		"left": return "right"
		"right": return "left"
	return ""


func _clear_all_cars() -> void:
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		simulation_engine.unregister_vehicle(vehicle.vehicle_id)
		vehicle.queue_free()


func _clear_spawned_stoplights() -> void:
	for stoplight in _spawned_stoplights:
		if is_instance_valid(stoplight):
			simulation_engine.unregister_stoplight(stoplight.stoplight_id)
			stoplight.queue_free()
	_spawned_stoplights.clear()


## Spawn stoplights from stoplight tiles in the road layer
func _spawn_stoplights_from_tiles() -> void:
	# Clear any previously spawned stoplights
	_clear_spawned_stoplights()

	if road_layer == null:
		return

	# Get stoplight positions from road layer
	var stoplight_data = road_layer.get_stoplight_data()
	if stoplight_data.is_empty():
		return

	# Load stoplight scene
	var stoplight_scene = load("res://scenes/entities/stoplight.tscn")
	if stoplight_scene == null:
		_update_status("Error: Could not load stoplight scene")
		return

	# Spawn stoplights at each position
	var stoplight_id = 1
	for data in stoplight_data:
		var stoplight = stoplight_scene.instantiate() as Stoplight
		if stoplight == null:
			continue

		stoplight.stoplight_id = "stoplight%d" % stoplight_id
		stoplight_id += 1
		stoplight.global_position = data["position"]

		# Add to scene
		$GameWorld.add_child(stoplight)

		# Register with simulation engine
		simulation_engine.register_stoplight(stoplight)

		# Store reference
		_spawned_stoplights.append(stoplight)

	print("Spawned %d stoplights from tiles" % _spawned_stoplights.size())


# ============================================
# UI Handlers
# ============================================

func _on_run_button_pressed() -> void:
	var code = code_editor.text
	if window_manager:
		code = window_manager.get_current_code() if window_manager.has_method("get_current_code") else code_editor.text

	if code.strip_edges().is_empty():
		_update_status("Error: No code entered")
		return

	# Notify tutorial system that player pressed Run
	_notify_tutorial_action("run_code")

	# Mark paths dirty
	if road_layer:
		road_layer.mark_paths_dirty()

	# Get all existing vehicles
	var vehicles = get_tree().get_nodes_in_group("vehicles")

	# Spawn an initial car if there are no cars
	if vehicles.size() == 0:
		_spawn_new_car()
		vehicles = get_tree().get_nodes_in_group("vehicles")

	# Execute code on ALL existing cars (not just one)
	# The first call to execute_code will start the simulation
	var first_car = true
	for vehicle in vehicles:
		if vehicle.vehicle_state == 1:  # Only active (non-crashed) cars
			if first_car:
				# First car uses main execute_code which also starts simulation
				simulation_engine.execute_code(code)
				first_car = false
			else:
				# Subsequent cars use execute_code_for_vehicle
				simulation_engine.execute_code_for_vehicle(code, vehicle)


func _on_simulation_started() -> void:
	_update_status("Running...")
	run_button.disabled = true
	is_spawning_cars = true
	car_spawn_timer = 0.0

	# Code is now running - timer will match game speed
	code_is_running = true

	# Play engine sound
	var code = code_editor.text
	if window_manager:
		code = window_manager.get_current_code() if window_manager.has_method("get_current_code") else code_editor.text
	if "car.go" in code.to_lower() or "car.move" in code.to_lower():
		if engine_audio and not engine_audio.playing:
			engine_audio.play(engine_loop_start)
		if background_audio and background_audio.playing:
			background_audio.stop()


func _on_simulation_paused() -> void:
	_update_status("Paused (Press Space to resume)")
	if engine_audio and engine_audio.playing:
		engine_audio.stop()
	if background_audio and not background_audio.playing:
		background_audio.play(1.0)


func _on_simulation_ended(success: bool) -> void:
	run_button.disabled = false
	is_spawning_cars = false
	_current_executing_line = -1

	if engine_audio and engine_audio.playing:
		engine_audio.stop()
	if background_audio and not background_audio.playing:
		background_audio.play(1.0)

	if success:
		_update_status("Simulation complete!")
	else:
		_update_status("Simulation failed")


func _on_car_reached_destination(car_id: String) -> void:
	# Find the car that reached destination
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if vehicle.vehicle_id == car_id:
			# Check if car is at correct group destination
			if not vehicle.is_at_correct_destination():
				# Wrong destination - lose a heart but still count as parked
				_lose_heart()
				_update_status("Car '%s' parked at wrong destination! (-1 heart)" % car_id)
			else:
				_update_status("Car '%s' reached destination!" % car_id)
			return
	_update_status("Car '%s' reached destination!" % car_id)


func _on_car_crashed(car_id: String) -> void:
	_lose_heart()
	_update_status("Car '%s' crashed! Lost 1 heart" % car_id)
	if engine_audio and engine_audio.playing:
		engine_audio.stop()
	if crash_audio and not crash_audio.playing:
		crash_audio.play()


func _on_car_off_road(car_id: String) -> void:
	_lose_heart()
	_update_status("Car '%s' went off-road! Lost 1 heart" % car_id)
	if engine_audio and engine_audio.playing:
		engine_audio.stop()
	if crash_audio and not crash_audio.playing:
		crash_audio.play()


func _on_car_ran_red_light(vehicle_id: String, _stoplight_id: String) -> void:
	hearts -= 1
	_update_hearts_label()
	_update_status("%s ran a red light! (-1 heart)" % vehicle_id)
	if hearts <= 0:
		_update_status("GAME OVER - Press R to Reset")
		status_label.add_theme_color_override("font_color", Color.RED)


func _on_level_completed(stars: int) -> void:
	_update_status("Level Complete! Stars: %s" % stars)
	_show_victory_popup(stars)


func _on_level_failed(reason: String) -> void:
	_update_status("Level Failed: %s" % reason)
	_stop_all_cars()
	_show_failure_popup(reason)


## Stop all cars when level fails
func _stop_all_cars() -> void:
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		if is_instance_valid(vehicle) and vehicle.has_method("stop"):
			vehicle.stop()


func _on_execution_line_changed(line_number: int) -> void:
	if _current_executing_line > 0:
		var prev_line = _current_executing_line - 1
		if prev_line < code_editor.get_line_count():
			code_editor.set_line_background_color(prev_line, Color(0, 0, 0, 0))

	_current_executing_line = line_number

	if line_number > 0:
		var target_line = line_number - 1
		if target_line < code_editor.get_line_count():
			code_editor.set_line_background_color(target_line, Color(0.3, 0.3, 0.0, 0.5))
			code_editor.set_caret_line(target_line)


func _on_execution_error(error: String, line: int) -> void:
	_update_status("Error at line %d: %s" % [line, error])
	if _current_executing_line > 0:
		var prev_line = _current_executing_line - 1
		if prev_line < code_editor.get_line_count():
			code_editor.set_line_background_color(prev_line, Color(0, 0, 0, 0))
	if line > 0:
		var target_line = line - 1
		if target_line < code_editor.get_line_count():
			code_editor.set_line_background_color(target_line, Color(0.5, 0.0, 0.0, 0.5))
			code_editor.set_caret_line(target_line)


# ============================================
# Help Panel
# ============================================

func _on_toggle_help_pressed() -> void:
	help_panel.visible = not help_panel.visible


# ============================================
# Result Popups
# ============================================

func _show_victory_popup(stars: int) -> void:
	# Stop timer on win
	timer_running = false
	level_won = true

	# Save best time
	var is_new_best = false
	if GameData:
		is_new_best = GameData.save_best_time(current_level_id, level_timer)
		GameData.mark_level_completed(current_level_id)

	result_title.text = "%s\nCOMPLETE!" % current_level_display_name

	var star_display = ""
	for i in range(3):
		if i < stars:
			star_display += "[*]"
		else:
			star_display += "[ ]"

	var cars_completed = 0
	var total_cars = 0
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	for vehicle in vehicles:
		total_cars += 1
		if vehicle.at_end():
			cars_completed += 1

	var message_parts: Array = []
	message_parts.append("Stars: %s" % star_display)

	# Show time with best time
	var time_str = "Time: %s" % _format_time(level_timer)
	if is_new_best:
		time_str += " (NEW BEST!)"
	elif GameData and GameData.has_best_time(current_level_id):
		time_str += " (Best: %s)" % _format_time(GameData.get_best_time(current_level_id))
	message_parts.append(time_str)

	message_parts.append("Cars: %d/%d" % [cars_completed, total_cars])
	message_parts.append("Hearts remaining: %d" % hearts)

	result_message.text = "\n".join(message_parts)

	# Check if there's a next level
	var has_next_level = (current_level_index + 1) < level_loader.get_level_count()
	next_button.visible = has_next_level
	if menu_button:
		menu_button.visible = true

	result_popup.visible = true


func _show_failure_popup(reason: String) -> void:
	# Stop timer on failure (don't save time)
	timer_running = false

	result_title.text = "%s\nFAILED" % current_level_display_name

	var message_parts: Array = []
	message_parts.append(reason)
	message_parts.append("")

	if reason.find("hearts") >= 0 or reason.find("Hearts") >= 0:
		message_parts.append("Too many crashes!")
	elif reason.find("Time") >= 0 or reason.find("time") >= 0:
		message_parts.append("Try to be more efficient.")
	elif reason.find("infinite loop") >= 0:
		message_parts.append("Check your code for infinite loops.")
		message_parts.append("Use break or proper conditions.")
	elif reason.find("map") >= 0 or reason.find("boundary") >= 0:
		message_parts.append("Keep cars on the road!")
	elif reason.find("Error") >= 0 or reason.find("error") >= 0:
		message_parts.append("Check your Python syntax.")

	message_parts.append("")
	message_parts.append("Press R to retry")

	result_message.text = "\n".join(message_parts)
	next_button.visible = false
	if menu_button:
		menu_button.visible = true
	result_popup.visible = true


func _hide_result_popup() -> void:
	result_popup.visible = false


func _on_retry_pressed() -> void:
	_hide_result_popup()
	# Reset timer when pressing Retry from game over screen
	level_timer = 0.0
	timer_running = true
	_update_timer_label()
	_do_fast_retry()


func _on_next_pressed() -> void:
	_hide_result_popup()
	_load_next_level()


# ============================================
# Game State
# ============================================

func _update_status(message: String) -> void:
	status_label.text = "Status: %s" % message


func _update_speed_label() -> void:
	speed_label.text = "Speed: %.1fx" % simulation_engine.speed_multiplier


func _update_road_cards_label() -> void:
	road_cards_label.text = "Road Cards: %d" % road_cards


func _do_fast_retry() -> void:
	_hide_result_popup()
	simulation_engine.reset()
	is_spawning_cars = false
	_current_executing_line = -1

	if engine_audio and engine_audio.playing:
		engine_audio.stop()
	if background_audio and not background_audio.playing:
		background_audio.play(1.0)

	# Mark paths dirty
	if road_layer:
		road_layer.mark_paths_dirty()

	# Clear all cars
	_clear_all_cars()
	next_car_id = 1

	# Reset all spawned stoplights
	for stoplight in _spawned_stoplights:
		if is_instance_valid(stoplight) and stoplight.has_method("reset"):
			stoplight.reset()

	# Reset hearts
	hearts = initial_hearts
	if hearts_ui and hearts_ui.has_method("reset_hearts"):
		hearts_ui.reset_hearts()
	_update_hearts_label()

	# DO NOT reset timer on R key / restart button
	# Timer only resets from game over screen buttons (Retry/Next Level)
	# Timer keeps running (was started on level load)
	level_won = false

	# Code stopped running - timer goes back to 1x speed
	code_is_running = false

	_update_status("Reset - Ready")
	run_button.disabled = false

	# Spawn initial cars again
	_spawn_initial_cars()


# ============================================
# Input Handling
# ============================================

## Check if the code editor currently has focus (player is typing)
func _is_code_editor_focused() -> bool:
	# Check if the new UI code editor has focus
	if window_manager and window_manager.code_editor_window:
		var code_edit = window_manager.code_editor_window.get_node_or_null("VBoxContainer/ContentContainer/ContentVBox/MainVSplit/HSplit/CodeEdit")
		if code_edit and code_edit.has_focus():
			return true
	# Check if the old code editor has focus
	if code_editor and code_editor.has_focus():
		return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var ctrl_pressed = event.ctrl_pressed

		# Skip most shortcuts if the code editor is focused (player is typing)
		# This prevents WASD camera movement, R reset, Space pause, etc. from triggering while typing code
		var editor_focused = _is_code_editor_focused()

		# F5, Ctrl+Enter, F10, F1 are allowed even when editor is focused (they are editor commands)
		match event.keycode:
			KEY_F5:
				if not run_button.disabled:
					_on_run_button_pressed()
			KEY_ENTER:
				if ctrl_pressed and not run_button.disabled:
					_on_run_button_pressed()
			KEY_R:
				# R for reset - only when NOT in code editor
				if not editor_focused:
					_do_fast_retry()
			KEY_F10:
				simulation_engine.step()
				_update_status("Step executed")
			KEY_EQUAL, KEY_KP_ADD:
				# Speed up - only when NOT in code editor
				if not editor_focused:
					if ctrl_pressed:
						simulation_engine.set_speed(simulation_engine.SPEED_FASTER)
					else:
						simulation_engine.speed_up()
					call_deferred("_update_speed_label")
			KEY_MINUS, KEY_KP_SUBTRACT:
				# Slow down - only when NOT in code editor
				if not editor_focused:
					simulation_engine.slow_down()
					call_deferred("_update_speed_label")
			KEY_F1:
				if use_new_ui and window_manager:
					window_manager.call("_on_readme_requested")
				else:
					_on_toggle_help_pressed()


func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse clicks for tile editing
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_tile_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_tile_remove()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_handle_zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_handle_zoom_out()


# ============================================
# Camera Zoom System
# ============================================

## Handle zoom in (scroll up)
func _handle_zoom_in() -> void:
	if camera == null:
		return

	var new_zoom = camera.zoom.x + ZOOM_STEP
	new_zoom = clampf(new_zoom, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)
	_clamp_camera_to_bounds()


## Handle zoom out (scroll down)
func _handle_zoom_out() -> void:
	if camera == null:
		return

	# Calculate the minimum zoom level that keeps visible area within bounds
	var viewport_size = get_viewport().get_visible_rect().size
	var bounds_size = camera_bounds_max - camera_bounds_min

	# Calculate minimum zoom to fit bounds (if we zoom out more, visible area exceeds bounds)
	var min_zoom_x = viewport_size.x / bounds_size.x if bounds_size.x > 0 else ZOOM_MIN
	var min_zoom_y = viewport_size.y / bounds_size.y if bounds_size.y > 0 else ZOOM_MIN
	var min_zoom_for_bounds = maxf(min_zoom_x, min_zoom_y)

	# Use the larger of ZOOM_MIN and the calculated minimum
	var effective_min_zoom = maxf(ZOOM_MIN, min_zoom_for_bounds)

	var new_zoom = camera.zoom.x - ZOOM_STEP
	new_zoom = clampf(new_zoom, effective_min_zoom, ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)
	_clamp_camera_to_bounds()


## Calculate camera bounds based on level's Camera Border node or road layer
func _calculate_camera_bounds() -> void:
	# First, try to find a "Camera Border" node in the level
	if current_level_node:
		var camera_border = current_level_node.get_node_or_null("Camera Border")

		# Handle CollisionShape2D with RectangleShape2D
		if camera_border and camera_border is CollisionShape2D:
			var shape = camera_border.shape
			if shape and shape is RectangleShape2D:
				var rect_size = shape.size
				var center = camera_border.global_position
				# Rectangle is centered on the node position
				camera_bounds_min = center - rect_size / 2.0
				camera_bounds_max = center + rect_size / 2.0
				return

		# Handle CollisionPolygon2D (fallback for polygon borders)
		if camera_border and camera_border is CollisionPolygon2D:
			var polygon = camera_border.polygon
			if polygon.size() > 0:
				# Calculate bounding box from polygon points
				var min_x = polygon[0].x
				var max_x = polygon[0].x
				var min_y = polygon[0].y
				var max_y = polygon[0].y

				for point in polygon:
					min_x = minf(min_x, point.x)
					max_x = maxf(max_x, point.x)
					min_y = minf(min_y, point.y)
					max_y = maxf(max_y, point.y)

				# Apply the node's global position offset
				var global_offset = camera_border.global_position
				camera_bounds_min = Vector2(min_x, min_y) + global_offset
				camera_bounds_max = Vector2(max_x, max_y) + global_offset
				return

	# Fallback: calculate from road layer
	if road_layer == null:
		# Use default bounds
		camera_bounds_min = Vector2(-TILE_SIZE, -TILE_SIZE)
		camera_bounds_max = Vector2(TILE_SIZE * 10, TILE_SIZE * 7)
		return

	# Get used rect from road layer
	var used_rect = road_layer.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		# No tiles - use default bounds
		camera_bounds_min = Vector2(-TILE_SIZE, -TILE_SIZE)
		camera_bounds_max = Vector2(TILE_SIZE * 10, TILE_SIZE * 7)
		return

	# Add padding around the level (2 tiles on each side)
	var padding = 2
	camera_bounds_min = Vector2(
		(used_rect.position.x - padding) * TILE_SIZE,
		(used_rect.position.y - padding) * TILE_SIZE
	)
	camera_bounds_max = Vector2(
		(used_rect.position.x + used_rect.size.x + padding) * TILE_SIZE,
		(used_rect.position.y + used_rect.size.y + padding) * TILE_SIZE
	)


## Set initial camera position from level's "Camera Start" node or keep current position
func _set_initial_camera_position() -> void:
	if camera == null:
		return

	# Look for a "Camera Start" node in the level to override the camera position
	if current_level_node:
		var camera_start = current_level_node.get_node_or_null("Camera Start")
		if camera_start:
			# Use the Camera Start node's position
			camera.position = camera_start.global_position
			return

	# No Camera Start node - keep the camera's current position from the scene
	# This allows devs to set the default camera position in main_tilemap.tscn


## Clamp camera position to stay within bounds
## Ensures the visible area (all 4 corners) stays inside the camera border
func _clamp_camera_to_bounds() -> void:
	if camera == null:
		return

	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size

	# Calculate visible half-size based on zoom
	var visible_half_size = viewport_size / (2.0 * camera.zoom)

	# Calculate camera position limits so visible area stays within bounds
	# Camera can move from (bounds_min + half_visible) to (bounds_max - half_visible)
	var min_cam_x = camera_bounds_min.x + visible_half_size.x
	var max_cam_x = camera_bounds_max.x - visible_half_size.x
	var min_cam_y = camera_bounds_min.y + visible_half_size.y
	var max_cam_y = camera_bounds_max.y - visible_half_size.y

	# Clamp camera position - if visible area is larger than bounds, center it
	if min_cam_x >= max_cam_x:
		camera.position.x = (camera_bounds_min.x + camera_bounds_max.x) / 2.0
	else:
		camera.position.x = clampf(camera.position.x, min_cam_x, max_cam_x)

	if min_cam_y >= max_cam_y:
		camera.position.y = (camera_bounds_min.y + camera_bounds_max.y) / 2.0
	else:
		camera.position.y = clampf(camera.position.y, min_cam_y, max_cam_y)


# ============================================
# Tile Editing System
# ============================================

## Get grid position from world position
## Uses floor division to properly handle negative coordinates
func _get_grid_from_world(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / TILE_SIZE)), int(floor(world_pos.y / TILE_SIZE)))


## Get world position (top-left) from grid position
func _get_world_from_grid(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)


## Check if two grid positions are adjacent (not diagonal)
func _is_adjacent(pos1: Vector2i, pos2: Vector2i) -> bool:
	var diff = pos2 - pos1
	return (abs(diff.x) == 1 and diff.y == 0) or (diff.x == 0 and abs(diff.y) == 1)


## Get direction string from offset vector
func _get_direction_from_offset(offset: Vector2i) -> String:
	if offset == Vector2i(1, 0): return "right"
	if offset == Vector2i(-1, 0): return "left"
	if offset == Vector2i(0, 1): return "bottom"
	if offset == Vector2i(0, -1): return "top"
	return ""


## Handle left click for tile selection and placement
func _handle_tile_click() -> void:
	if not is_editing_enabled or road_layer == null:
		return

	var mouse_pos = get_global_mouse_position()
	var grid_pos = _get_grid_from_world(mouse_pos)

	# Case 1: No tile selected - click on existing road to select it
	if selected_tile_pos == Vector2i(-1, -1):
		if road_layer.has_road_at(grid_pos):
			# Check if we can select this tile (permission 1 or 2)
			if not _can_select_tile(grid_pos):
				_update_status("Cannot select this tile")
				return
			_select_tile(grid_pos)
		return

	# Case 2: Clicked on the same selected tile - deselect
	if grid_pos == selected_tile_pos:
		_deselect_tile()
		return

	# Case 3: Clicked on another existing road
	if road_layer.has_road_at(grid_pos):
		# Check if it's adjacent - try to connect
		if _is_adjacent(selected_tile_pos, grid_pos):
			var offset = grid_pos - selected_tile_pos
			var direction = _get_direction_from_offset(offset)
			if direction != "" and _can_connect_tiles(selected_tile_pos, grid_pos, direction):
				# Connect the two tiles (FREE - no card cost)
				_connect_two_tiles(selected_tile_pos, grid_pos, direction)
				_update_status("Roads connected at %s (FREE)" % grid_pos)
				_hide_preview()
				# Make the target tile the new selected tile
				_select_tile(grid_pos)
				return

		# Not adjacent or can't connect - select the new tile instead
		if not _can_select_tile(grid_pos):
			_update_status("Cannot select this tile")
			return
		_select_tile(grid_pos)
		return

	# Case 4: Clicked on empty space adjacent to selected - place new road
	if _is_adjacent(selected_tile_pos, grid_pos):
		# Check if building is enabled for this level
		if not is_building_enabled:
			_update_status("Road building is disabled for this level")
			return

		if road_cards <= 0:
			_update_status("No road cards left!")
			return

		# Check if we can build at this position (permission 2 for empty tiles)
		var build_permission = _get_build_permission(grid_pos)
		if build_permission < 2:
			_update_status("Cannot build here")
			return

		# Place new road tile with connection to selected tile
		var offset = grid_pos - selected_tile_pos
		var direction = _get_direction_from_offset(offset)
		if direction != "":
			_place_connected_tile(grid_pos, direction)
			road_cards -= 1
			_update_road_cards_label()
			_update_status("Road placed at %s (-1 card)" % grid_pos)
			# Move selection to the new tile
			_select_tile(grid_pos)


## Handle right click to remove tiles
func _handle_tile_remove() -> void:
	if not is_editing_enabled or road_layer == null:
		return

	# Check if building/removing is enabled for this level
	if not is_building_enabled:
		_update_status("Road editing is disabled for this level")
		return

	var mouse_pos = get_global_mouse_position()
	var grid_pos = _get_grid_from_world(mouse_pos)

	# Check if tile exists
	if not road_layer.has_road_at(grid_pos):
		return

	# Check if we can remove at this position (permission 2 required)
	if not _can_remove_tile(grid_pos):
		_update_status("Cannot remove this tile")
		return

	# Check if it's a protected tile (spawn or destination parking)
	var tile_type = road_layer.get_tile_type_at(grid_pos)
	if _is_parking_tile(tile_type):
		_update_status("Cannot remove parking tiles!")
		return

	# If removing the selected tile, deselect first
	if grid_pos == selected_tile_pos:
		_deselect_tile()

	# Update neighboring tiles first (remove their connections to this tile)
	_update_neighbors_after_removal(grid_pos)

	# Remove tile and gain a card back
	road_layer.erase_cell(grid_pos)
	road_layer.mark_paths_dirty()
	road_layer._scan_for_parking_tiles()  # Rescan in case parking tiles changed
	road_cards += 1
	_update_road_cards_label()
	_update_status("Road removed at %s (+1 card)" % grid_pos)


## Check if a tile type is a parking tile (spawn or destination)
func _is_parking_tile(tile_type) -> bool:
	return tile_type in RoadTileMapLayer.SPAWN_PARKING_TILES or tile_type in RoadTileMapLayer.DEST_PARKING_TILES


## Select a tile for editing
func _select_tile(grid_pos: Vector2i) -> void:
	# Deselect previous
	_hide_selection_highlight()
	_hide_preview()

	selected_tile_pos = grid_pos
	_show_selection_highlight(grid_pos)
	_update_status("Road selected at %s - Click adjacent empty space to place" % grid_pos)


## Deselect current tile
func _deselect_tile() -> void:
	_hide_selection_highlight()
	_hide_preview()
	selected_tile_pos = Vector2i(-1, -1)
	_update_status("Deselected")


## Show selection highlight on a tile
func _show_selection_highlight(grid_pos: Vector2i) -> void:
	if selection_highlight == null:
		selection_highlight = ColorRect.new()
		selection_highlight.color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow highlight
		selection_highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
		selection_highlight.z_index = 5
		selection_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events
		$GameWorld.add_child(selection_highlight)

	selection_highlight.position = _get_world_from_grid(grid_pos)
	selection_highlight.visible = true


## Hide selection highlight
func _hide_selection_highlight() -> void:
	if selection_highlight != null:
		selection_highlight.visible = false


## Place a tile that connects to the selected tile
func _place_connected_tile(grid_pos: Vector2i, from_direction: String) -> void:
	if road_layer == null:
		return

	# Determine which tile type to place based on the connection direction
	# from_direction is the direction FROM selected TO new tile
	# So new tile needs connection in the OPPOSITE direction
	var connection_dir = _get_opposite_direction(from_direction)

	# Find the appropriate tile atlas coords for a tile with that connection
	var atlas_coords = _get_tile_for_connection(connection_dir)
	if atlas_coords == Vector2i(-1, -1):
		_update_status("No tile found for connection!")
		return

	# Place the tile
	road_layer.set_cell(grid_pos, 0, atlas_coords)
	road_layer.mark_paths_dirty()
	road_layer._scan_for_parking_tiles()  # Rescan in case parking tiles added

	# Also update the selected tile to add connection to new tile
	_add_connection_to_tile(selected_tile_pos, from_direction)


## Get tile atlas coords for a tile with a specific connection
func _get_tile_for_connection(connection: String) -> Vector2i:
	# Return the simplest tile that has the required connection
	match connection:
		"right": return Vector2i(1, 0)   # ROAD_E
		"left": return Vector2i(3, 0)    # ROAD_W
		"bottom": return Vector2i(0, 1)  # ROAD_S
		"top": return Vector2i(0, 3)     # ROAD_N
	return Vector2i(-1, -1)


## Connect two adjacent tiles bidirectionally
func _connect_two_tiles(tile1_pos: Vector2i, tile2_pos: Vector2i, direction: String) -> void:
	if road_layer == null:
		return

	# Add connection from tile1 to tile2
	_add_connection_to_tile(tile1_pos, direction)

	# Add connection from tile2 to tile1 (opposite direction)
	var opposite = _get_opposite_direction(direction)
	_add_connection_to_tile(tile2_pos, opposite)


## Add a connection to an existing tile by upgrading it
func _add_connection_to_tile(grid_pos: Vector2i, new_connection: String) -> void:
	if road_layer == null:
		return

	# Don't modify Build Tile 2 (permission 1) tiles - they are fixed
	var permission = _get_build_permission(grid_pos)
	if permission == 1:
		return

	# Get current tile type
	var current_type = road_layer.get_tile_type_at(grid_pos)
	if current_type == RoadTileMapLayer.TileType.NONE:
		return

	# Skip parking and stoplight tiles - they shouldn't be modified
	if current_type in RoadTileMapLayer.SPAWN_PARKING_TILES:
		return
	if current_type in RoadTileMapLayer.DEST_PARKING_TILES:
		return
	if current_type in RoadTileMapLayer.STOPLIGHT_TILES:
		return

	# Get current connections
	var current_connections = RoadTileMapLayer.TILE_CONNECTIONS.get(current_type, []).duplicate()
	if new_connection in current_connections:
		return  # Already has this connection

	# Add new connection
	current_connections.append(new_connection)

	# Find tile type that matches these connections
	var new_atlas = _find_tile_with_connections(current_connections)
	if new_atlas != Vector2i(-1, -1):
		road_layer.set_cell(grid_pos, 0, new_atlas)
		road_layer.mark_paths_dirty()


## Find a tile atlas coords that has all the specified connections
func _find_tile_with_connections(connections: Array) -> Vector2i:
	# Sort connections for consistent comparison
	var sorted_connections = connections.duplicate()
	sorted_connections.sort()

	# Check each tile type
	for atlas_coords in RoadTileMapLayer.TILE_COORDS_TO_TYPE:
		var tile_type = RoadTileMapLayer.TILE_COORDS_TO_TYPE[atlas_coords]

		# Skip parking tiles and stoplight tiles
		if tile_type in RoadTileMapLayer.SPAWN_PARKING_TILES:
			continue
		if tile_type in RoadTileMapLayer.DEST_PARKING_TILES:
			continue
		if tile_type in RoadTileMapLayer.STOPLIGHT_TILES:
			continue

		var tile_connections = RoadTileMapLayer.TILE_CONNECTIONS.get(tile_type, []).duplicate()
		tile_connections.sort()

		if tile_connections == sorted_connections:
			return atlas_coords

	return Vector2i(-1, -1)


## Show preview tile at adjacent position
func _show_preview(grid_pos: Vector2i, connection_dir: String) -> void:
	if preview_sprite == null:
		preview_sprite = Sprite2D.new()
		preview_sprite.z_index = 4
		preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)  # Semi-transparent
		$GameWorld.add_child(preview_sprite)

		# Load tileset texture
		if tileset_texture == null:
			tileset_texture = load("res://assets/tiles/gocarstilesSheet.png")
		preview_sprite.texture = tileset_texture
		preview_sprite.region_enabled = true
		preview_sprite.centered = false

	# Get atlas coords for preview tile
	var atlas_coords = _get_tile_for_connection(connection_dir)
	if atlas_coords == Vector2i(-1, -1):
		_hide_preview()
		return

	# Set the region to show the correct tile
	preview_sprite.region_rect = Rect2(atlas_coords.x * TILE_SIZE, atlas_coords.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	preview_sprite.position = _get_world_from_grid(grid_pos)
	preview_sprite.visible = true
	preview_grid_pos = grid_pos


## Hide preview tile
func _hide_preview() -> void:
	if preview_sprite != null:
		preview_sprite.visible = false
	preview_grid_pos = Vector2i(-1, -1)


## Check if we can connect selected tile to target tile
## direction is from selected to target
func _can_connect_tiles(selected_pos: Vector2i, target_pos: Vector2i, direction: String) -> bool:
	if road_layer == null:
		return false

	# Check if selected tile is a Build Tile 2 (protected) - can only connect in its connection direction
	var selected_permission = _get_build_permission(selected_pos)
	if selected_permission == 1:
		# Build Tile 2 can only connect in directions it already has
		var selected_connections = road_layer.get_connections_at(selected_pos)
		if direction not in selected_connections:
			return false

	# Check if target tile is a Build Tile 2 (protected)
	var target_permission = _get_build_permission(target_pos)
	if target_permission == 1:
		# Target's connection must match the opposite direction
		var opposite = _get_opposite_direction(direction)
		var target_connections = road_layer.get_connections_at(target_pos)
		if opposite not in target_connections:
			return false

	# Check if selected tile already has this connection
	var selected_connections = road_layer.get_connections_at(selected_pos)
	if direction in selected_connections:
		return false  # Already connected

	return true


## Show preview of selected tile with added connection
func _show_connection_preview(grid_pos: Vector2i, new_connection: String) -> void:
	if preview_sprite == null:
		preview_sprite = Sprite2D.new()
		preview_sprite.z_index = 4
		preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)  # Semi-transparent
		$GameWorld.add_child(preview_sprite)

		# Load tileset texture
		if tileset_texture == null:
			tileset_texture = load("res://assets/tiles/gocarstilesSheet.png")
		preview_sprite.texture = tileset_texture
		preview_sprite.region_enabled = true
		preview_sprite.centered = false

	# Get current connections and add new one
	var current_type = road_layer.get_tile_type_at(grid_pos)
	var current_connections = RoadTileMapLayer.TILE_CONNECTIONS.get(current_type, []).duplicate()
	if new_connection not in current_connections:
		current_connections.append(new_connection)

	# Find tile with these connections
	var atlas_coords = _find_tile_with_connections(current_connections)
	if atlas_coords == Vector2i(-1, -1):
		_hide_preview()
		return

	# Set the region to show the correct tile
	preview_sprite.region_rect = Rect2(atlas_coords.x * TILE_SIZE, atlas_coords.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	preview_sprite.position = _get_world_from_grid(grid_pos)
	preview_sprite.visible = true
	preview_grid_pos = grid_pos


## Remove a connection from a tile by downgrading it
func _remove_connection_from_tile(grid_pos: Vector2i, connection_to_remove: String) -> void:
	if road_layer == null:
		return

	# Don't update Build Tile 2 (permission 1) tiles
	var permission = _get_build_permission(grid_pos)
	if permission == 1:
		return

	# Get current tile type
	var current_type = road_layer.get_tile_type_at(grid_pos)
	if current_type == RoadTileMapLayer.TileType.NONE:
		return

	# Skip parking and stoplight tiles
	if current_type in RoadTileMapLayer.SPAWN_PARKING_TILES:
		return
	if current_type in RoadTileMapLayer.DEST_PARKING_TILES:
		return
	if current_type in RoadTileMapLayer.STOPLIGHT_TILES:
		return

	# Get current connections
	var current_connections = RoadTileMapLayer.TILE_CONNECTIONS.get(current_type, []).duplicate()
	if connection_to_remove not in current_connections:
		return  # Doesn't have this connection

	# Remove the connection
	current_connections.erase(connection_to_remove)

	# If no connections left, set to r0/c0 (ROAD_NONE) instead of deleting
	if current_connections.is_empty():
		road_layer.set_cell(grid_pos, 0, Vector2i(0, 0))  # r0/c0 = ROAD_NONE
		road_layer.mark_paths_dirty()
		return

	# Find tile type that matches remaining connections
	var new_atlas = _find_tile_with_connections(current_connections)
	if new_atlas != Vector2i(-1, -1):
		road_layer.set_cell(grid_pos, 0, new_atlas)
		road_layer.mark_paths_dirty()


## Update all neighbors when a tile is removed
func _update_neighbors_after_removal(removed_pos: Vector2i) -> void:
	# Check all 4 adjacent positions
	var neighbors = [
		Vector2i(removed_pos.x + 1, removed_pos.y),  # right
		Vector2i(removed_pos.x - 1, removed_pos.y),  # left
		Vector2i(removed_pos.x, removed_pos.y + 1),  # bottom
		Vector2i(removed_pos.x, removed_pos.y - 1)   # top
	]
	var directions = ["left", "right", "top", "bottom"]  # opposite directions

	for i in range(neighbors.size()):
		var neighbor_pos = neighbors[i]
		var connection_to_remove = directions[i]

		if road_layer.has_road_at(neighbor_pos):
			_remove_connection_from_tile(neighbor_pos, connection_to_remove)


# ============================================
# Stats UI Panel
# ============================================

func _setup_stats_ui_panel() -> void:
	var stats_panel_scene = load("res://scenes/ui/stats_ui_panel.tscn")
	if stats_panel_scene:
		stats_ui_panel = stats_panel_scene.instantiate()
		add_child(stats_ui_panel)
	else:
		push_warning("Could not load StatsUIPanel scene")


# ============================================
# New UI System
# ============================================

func _setup_new_ui() -> void:
	var WindowManagerClass = load("res://scripts/ui/window_manager.gd")
	window_manager = WindowManagerClass.new()
	window_manager.name = "WindowManager"
	add_child(window_manager)
	window_manager.setup($UI)
	window_manager.code_execution_requested.connect(_on_window_manager_code_run)
	window_manager.pause_requested.connect(_on_window_manager_pause)
	window_manager.reset_requested.connect(_on_window_manager_reset)
	window_manager.speed_changed.connect(_on_window_manager_speed_changed)

	var module_loader = window_manager.get_module_loader()
	if simulation_engine and simulation_engine._python_interpreter:
		simulation_engine._python_interpreter.call("set_module_loader", module_loader)

	var code_editor_window = window_manager.code_editor_window
	if code_editor_window and simulation_engine:
		code_editor_window.connect_to_simulation(simulation_engine)

	if code_editor and is_instance_valid(code_editor):
		code_editor.visible = false
	if run_button and is_instance_valid(run_button):
		run_button.visible = false
	var instructions_label = $UI.get_node_or_null("InstructionsLabel")
	if instructions_label:
		instructions_label.visible = false
	if help_panel and is_instance_valid(help_panel):
		help_panel.visible = false
	var toggle_help_btn = $UI.get_node_or_null("ToggleHelpButton")
	if toggle_help_btn:
		toggle_help_btn.visible = false

	print("New UI system enabled")


func _on_window_manager_code_run(code: String) -> void:
	if code.strip_edges().is_empty():
		_update_status("Error: No code entered")
		return
	
	# Notify tutorial system
	_notify_tutorial_action("run_code")

	if road_layer:
		road_layer.mark_paths_dirty()

	var vehicles = get_tree().get_nodes_in_group("vehicles")
	if vehicles.size() == 0:
		_spawn_new_car()
		vehicles = get_tree().get_nodes_in_group("vehicles")

	# Execute code on ALL existing cars (not just one)
	var first_car = true
	for vehicle in vehicles:
		if vehicle.vehicle_state == 1:  # Only active (non-crashed) cars
			if first_car:
				simulation_engine.execute_code(code)
				first_car = false
			else:
				simulation_engine.execute_code_for_vehicle(code, vehicle)


func _on_window_manager_pause() -> void:
	simulation_engine.toggle_pause()


func _on_window_manager_reset() -> void:
	_do_fast_retry()


func _on_window_manager_speed_changed(speed_val: float) -> void:
	simulation_engine.speed_multiplier = speed_val
	Engine.time_scale = speed_val
	_update_speed_label()


func _exit_tree() -> void:
	if background_audio:
		background_audio.stop()
		background_audio.queue_free()
	if engine_audio:
		engine_audio.stop()
		engine_audio.queue_free()
	if crash_audio:
		crash_audio.stop()
		crash_audio.queue_free()


# ============================================
# Timer and Best Times
# ============================================

## Format time as MM:SS.ms
func _format_time(time: float) -> String:
	if time < 0:
		return "--:--.--"
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]


## Update timer display
func _update_timer_label() -> void:
	# Find or create timer label
	var timer_label = $UI.get_node_or_null("TimerLabel")
	if timer_label == null:
		timer_label = Label.new()
		timer_label.name = "TimerLabel"
		timer_label.offset_left = 500
		timer_label.offset_top = 10
		timer_label.offset_right = 700
		timer_label.offset_bottom = 40
		timer_label.add_theme_font_size_override("font_size", 24)
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		$UI.add_child(timer_label)

	timer_label.text = _format_time(level_timer)

	# Show best time below if available
	if GameData and GameData.has_best_time(current_level_id):
		var best = GameData.get_best_time(current_level_id)
		timer_label.text += "\nBest: %s" % _format_time(best)


# ============================================
# Menu Button
# ============================================

## Create menu button in result popup
func _create_menu_button() -> void:
	if menu_button != null:
		return

	menu_button = Button.new()
	menu_button.name = "MenuButton"
	menu_button.text = "Menu"
	menu_button.offset_left = 135
	menu_button.offset_top = 170
	menu_button.offset_right = 265
	menu_button.offset_bottom = 210
	menu_button.pressed.connect(_on_menu_pressed)
	result_popup.add_child(menu_button)


## Return to main menu
func _on_menu_pressed() -> void:
	_hide_result_popup()
	get_tree().change_scene_to_file("res://scenes/ui/Main_Menu/CampaignMenu.tscn")


# ============================================
# Menu Panel
# ============================================

## Create the menu panel with options
func _create_menu_panel() -> void:
	# Load and instantiate the menu panel scene
	var menu_panel_scene = load("res://scenes/ui/menu_panel.tscn")
	if menu_panel_scene:
		menu_panel = menu_panel_scene.instantiate()
		$UI.add_child(menu_panel)
		
		# Connect signals
		menu_panel.back_to_levels_pressed.connect(_on_menu_back_to_levels)
		menu_panel.reset_windows_pressed.connect(_on_menu_reset_windows)
		menu_panel.close_pressed.connect(_on_menu_close)
		
		print("Menu panel loaded from scene")
	else:
		push_error("Failed to load menu panel scene")

## Open the menu panel
func _on_menu_button_pressed() -> void:
	if menu_panel and menu_panel.has_method("toggle"):
		menu_panel.toggle()

## Back to levels
func _on_menu_back_to_levels() -> void:
	if menu_panel:
		menu_panel.hide_panel()
	get_tree().change_scene_to_file("res://scenes/ui/Main_Menu/CampaignMenu.tscn")

## Reset window positions
func _on_menu_reset_windows() -> void:
	if menu_panel:
		menu_panel.hide_panel()
	
	# Reset windows via window manager if using new UI
	if window_manager and window_manager.has_method("reset_all_window_positions"):
		window_manager.reset_all_window_positions()
		print("Window positions reset")
	elif window_manager:
		# Manual reset for individual windows
		if window_manager.code_editor_window:
			window_manager.code_editor_window.position = Vector2(50, 50)
		if window_manager.file_explorer:
			window_manager.file_explorer.position = Vector2(50, 200)
		if window_manager.readme_window:
			window_manager.readme_window.position = Vector2(500, 50)
		if window_manager.skill_tree_window:
			window_manager.skill_tree_window.position = Vector2(500, 300)
		print("Window positions manually reset")

## Close menu panel
func _on_menu_close() -> void:
	if menu_panel:
		menu_panel.hide_panel()


# ============================================
# Level Hearts Loading
# ============================================

## Load hearts configuration from level's HeartsUI node
func _load_level_hearts() -> void:
	if current_level_node == null:
		return

	# Look for HeartsUI node in level
	hearts_ui = current_level_node.get_node_or_null("HeartsUI")
	if hearts_ui == null:
		# Try to find it as a child of any node
		for child in current_level_node.get_children():
			var found = child.get_node_or_null("HeartsUI")
			if found:
				hearts_ui = found
				break

	if hearts_ui:
		# HeartsUI found - use its configuration
		if hearts_ui.has_method("get_max_hearts"):
			initial_hearts = hearts_ui.get_max_hearts()
			hearts = initial_hearts
		elif hearts_ui.has_method("set_max_hearts"):
			# Already initialized from label
			initial_hearts = hearts_ui.max_hearts if "max_hearts" in hearts_ui else 3
			hearts = initial_hearts

		# Move hearts UI to our UI layer
		hearts_ui.get_parent().remove_child(hearts_ui)
		$UI.add_child(hearts_ui)
		hearts_ui.position = Vector2(20, 20)

		# Connect signals
		if hearts_ui.has_signal("hearts_depleted"):
			hearts_ui.hearts_depleted.connect(_on_hearts_depleted)

		# Hide old hearts label
		if hearts_label:
			hearts_label.visible = false
	else:
		# No HeartsUI found - use default
		initial_hearts = 10
		hearts = initial_hearts
		if hearts_label:
			hearts_label.visible = true


## Called when hearts UI reports all hearts lost
func _on_hearts_depleted() -> void:
	_show_failure_popup("Out of hearts!")


## Override lose_heart to use HeartsUI if available
func _lose_heart() -> void:
	if hearts_ui and hearts_ui.has_method("lose_heart"):
		hearts_ui.lose_heart()
		hearts = hearts_ui.get_hearts() if hearts_ui.has_method("get_hearts") else hearts - 1
	else:
		hearts -= 1

	_update_hearts_label()

	if hearts <= 0:
		_show_failure_popup("Out of hearts!")


## Update hearts label (fallback when no HeartsUI)
func _update_hearts_label() -> void:
	if hearts_label and hearts_label.visible:
		hearts_label.text = "Hearts: %d" % hearts


# ============================================
# Level Build Roads Loading
# ============================================

## Load road building configuration from level's LevelSettings/LevelBuildRoads node
func _load_level_build_roads() -> void:
	if current_level_node == null:
		return

	# Look for LevelSettings/LevelBuildRoads label
	var level_settings = current_level_node.get_node_or_null("LevelSettings")
	if level_settings == null:
		# No settings node - disable building by default
		is_building_enabled = false
		road_cards = 0
		initial_road_cards = 0
		_update_road_cards_label()
		return

	var build_roads_label = level_settings.get_node_or_null("LevelBuildRoads")
	if build_roads_label and build_roads_label is Label:
		var build_roads_text = build_roads_label.text.strip_edges()
		var build_roads_count = int(build_roads_text)

		if build_roads_count <= 0:
			# 0 = Building disabled, no roads UI
			is_building_enabled = false
			road_cards = 0
			initial_road_cards = 0
			if road_cards_label:
				road_cards_label.visible = false
		else:
			# 1+ = Building enabled with specified count
			is_building_enabled = true
			road_cards = build_roads_count
			initial_road_cards = build_roads_count
			if road_cards_label:
				road_cards_label.visible = true
	else:
		# No LevelBuildRoads label found - disable building
		is_building_enabled = false
		road_cards = 0
		initial_road_cards = 0
		if road_cards_label:
			road_cards_label.visible = false

	_update_road_cards_label()

	# Look for EnableBuilding layer in level
	enable_building_layer = current_level_node.get_node_or_null("EnableBuildingLayer") as TileMapLayer
	if enable_building_layer:
		print("EnableBuildingLayer found in level")
	else:
		enable_building_layer = null


## Check if building is allowed at a specific grid position
## Uses EnableBuilding layer if present, otherwise allows all if building is enabled
## Returns: 0 = cannot select/build/remove, 1 = can select/build but not remove, 2 = can select/build/remove
func _get_build_permission(grid_pos: Vector2i) -> int:
	if not is_building_enabled:
		return 0  # Building disabled for this level

	if enable_building_layer == null:
		return 2  # No restriction layer - full permissions if building enabled

	# Check the EnableBuilding layer at this position
	var atlas_coords = enable_building_layer.get_cell_atlas_coords(grid_pos)
	if atlas_coords == Vector2i(-1, -1):
		return 2  # No tile at this position = full permissions (default)

	# Tile 0 (0,0) = Disable all, Tile 1 (1,0) = Build only, Tile 2 (2,0) = Full permissions
	if atlas_coords.x == 0:
		return 0  # Tile 0: Cannot select/build/remove
	elif atlas_coords.x == 1:
		return 1  # Tile 1: Can select/build, cannot remove
	elif atlas_coords.x == 2:
		return 2  # Tile 2: Full permissions

	return 2  # Default: full permissions


## Check if a tile can be selected for editing
func _can_select_tile(grid_pos: Vector2i) -> bool:
	var permission = _get_build_permission(grid_pos)
	return permission >= 1  # Permission 1 or 2 allows selection


## Check if a road can be removed at a position
func _can_remove_tile(grid_pos: Vector2i) -> bool:
	var permission = _get_build_permission(grid_pos)
	return permission >= 2  # Only permission 2 allows removal


# ============================================
# Level Cars Configuration
# ============================================

## Load car spawning configuration from level's LevelSettings/LevelCars label
## Format: "Group A - Type, Color, Type, Color\nGroup B - Random, Random"
## Default: Each group gets "Random, Random"
func _load_level_cars_config() -> void:
	level_cars_config.clear()

	# Set default config for all groups (Random, Random)
	level_cars_config["A"] = [{"type": "Random", "color": "Random"}]
	level_cars_config["B"] = [{"type": "Random", "color": "Random"}]
	level_cars_config["C"] = [{"type": "Random", "color": "Random"}]
	level_cars_config["D"] = [{"type": "Random", "color": "Random"}]

	if current_level_node == null:
		return

	# Look for LevelSettings/LevelCars label
	var level_settings = current_level_node.get_node_or_null("LevelSettings")
	if level_settings == null:
		return

	var level_cars_label = level_settings.get_node_or_null("LevelCars")
	if level_cars_label == null or not level_cars_label is Label:
		return

	# Parse the label text
	var config_text = level_cars_label.text.strip_edges()
	var lines = config_text.split("\n")

	for line in lines:
		line = line.strip_edges()
		if line.is_empty():
			continue

		# Parse "Group X - Type, Color, Type, Color, ..."
		var parts = line.split(" - ")
		if parts.size() < 2:
			continue

		# Extract group letter (e.g., "Group A" -> "A")
		var group_part = parts[0].strip_edges()
		var group_name = ""
		if group_part.begins_with("Group "):
			group_name = group_part.substr(6).strip_edges().to_upper()
		else:
			continue

		if not group_name in ["A", "B", "C", "D"]:
			continue

		# Parse type/color pairs
		var items_part = parts[1].strip_edges()
		var items = items_part.split(",")
		var car_options: Array = []

		var i = 0
		while i < items.size():
			var car_type = items[i].strip_edges() if i < items.size() else "Random"
			var car_color = items[i + 1].strip_edges() if i + 1 < items.size() else "Random"
			car_options.append({"type": car_type, "color": car_color})
			i += 2

		if car_options.size() > 0:
			level_cars_config[group_name] = car_options

	print("Loaded LevelCars config: %s" % str(level_cars_config))


## Get a random car configuration for a spawn group
## Returns {type: String, color: String}
func _get_car_config_for_group(group_name: String) -> Dictionary:
	var options = level_cars_config.get(group_name, [{"type": "Random", "color": "Random"}])
	if options.size() == 0:
		return {"type": "Random", "color": "Random"}
	return options[randi() % options.size()]


## Convert type string to scene path
func _get_scene_path_for_type(type_name: String) -> String:
	match type_name.to_lower():
		"sedan": return "res://scenes/entities/car_sedan.tscn"
		"estate": return "res://scenes/entities/car_estate.tscn"
		"sport": return "res://scenes/entities/car_sport.tscn"
		"micro": return "res://scenes/entities/car_micro.tscn"
		"pickup": return "res://scenes/entities/car_pickup.tscn"
		"jeepney": return "res://scenes/entities/car_jeepney.tscn"
		"jeepney2", "jeepney_2": return "res://scenes/entities/car_jeepney_2.tscn"
		"bus": return "res://scenes/entities/car_bus.tscn"
		_: return ""  # Random or unknown


## Convert color string to VehicleColor enum index
## Returns -1 for Random (use set_random_color instead)
func _get_color_index_for_name(color_name: String) -> int:
	match color_name.to_lower():
		"white": return 0
		"gray": return 1
		"black": return 2
		"red": return 3
		"beige": return 4
		"green": return 5
		"blue": return 6
		"cyan": return 7
		"orange": return 8
		"brown": return 9
		"lime": return 10
		"magenta": return 11
		"pink": return 12
		"purple": return 13
		"yellow": return 14
		_: return -1  # Random or unknown


# ============================================
# Tutorial System Integration
# ============================================

## Start tutorial if this level has one
func _start_tutorial_if_available() -> void:
	if not TutorialManager:
		print("TutorialManager not found")
		return

	# Get level name from current_level_id (e.g., "level_00", "level_01")
	var level_name = current_level_id
	if level_name.is_empty():
		return

	# Check if this level has a tutorial
	if TutorialManager.has_tutorial(level_name):
		print("Starting tutorial for level: %s" % level_name)

		# Connect to TutorialManager signals if not already connected
		_connect_tutorial_signals()

		# Start the tutorial - pass self as parent for dialogue box
		TutorialManager.start_tutorial(level_name, self)
	else:
		print("No tutorial for level: %s" % level_name)

## Connect to TutorialManager signals
func _connect_tutorial_signals() -> void:
	if not TutorialManager:
		return

	# Disconnect first to avoid duplicate connections
	if TutorialManager.wait_for_action.is_connected(_on_tutorial_wait_for_action):
		TutorialManager.wait_for_action.disconnect(_on_tutorial_wait_for_action)
	if TutorialManager.force_event.is_connected(_on_tutorial_force_event):
		TutorialManager.force_event.disconnect(_on_tutorial_force_event)
	if TutorialManager.highlight_requested.is_connected(_on_tutorial_highlight_requested):
		TutorialManager.highlight_requested.disconnect(_on_tutorial_highlight_requested)
	if TutorialManager.highlight_cleared.is_connected(_on_tutorial_highlight_cleared):
		TutorialManager.highlight_cleared.disconnect(_on_tutorial_highlight_cleared)
	if TutorialManager.tutorial_completed.is_connected(_on_tutorial_completed):
		TutorialManager.tutorial_completed.disconnect(_on_tutorial_completed)

	# Connect signals
	TutorialManager.wait_for_action.connect(_on_tutorial_wait_for_action)
	TutorialManager.force_event.connect(_on_tutorial_force_event)
	TutorialManager.highlight_requested.connect(_on_tutorial_highlight_requested)
	TutorialManager.highlight_cleared.connect(_on_tutorial_highlight_cleared)
	TutorialManager.tutorial_completed.connect(_on_tutorial_completed)

## Called when tutorial is waiting for a player action
func _on_tutorial_wait_for_action(action_type: String) -> void:
	print("Tutorial waiting for action: %s" % action_type)
	# The tutorial will wait until we call TutorialManager.notify_action()

## Called when tutorial wants to force an event (like a crash demo)
func _on_tutorial_force_event(event_type: String) -> void:
	print("Tutorial forcing event: %s" % event_type)
	# Handle forced events like crash demos
	match event_type.to_lower():
		"crash", "car crashes":
			# Force a crash on the current car for demo purposes
			var vehicles = get_tree().get_nodes_in_group("vehicles")
			if vehicles.size() > 0:
				var vehicle = vehicles[0]
				if vehicle.has_method("crash"):
					vehicle.crash()
		"red light violation":
			# Force a red light violation demo
			pass

## Called when tutorial wants to highlight a UI element
func _on_tutorial_highlight_requested(target: String) -> void:
	print("Tutorial highlight requested: %s" % target)
	# TODO: Implement highlighting system
	# For now, just log the request

## Called when tutorial highlight should be cleared
func _on_tutorial_highlight_cleared() -> void:
	print("Tutorial highlight cleared")
	# TODO: Clear any active highlights

## Called when tutorial is completed
func _on_tutorial_completed(level_id: String) -> void:
	print("Tutorial completed: %s" % level_id)

## Notify TutorialManager of player actions
func _notify_tutorial_action(action: String) -> void:
	print("Main: _notify_tutorial_action called with: %s" % action)
	if TutorialManager and TutorialManager.is_active():
		print("Main: TutorialManager is active, calling notify_action")
		TutorialManager.notify_action(action)
	else:
		if not TutorialManager:
			print("Main: TutorialManager not found")
		elif not TutorialManager.is_active():
			print("Main: TutorialManager not active")
