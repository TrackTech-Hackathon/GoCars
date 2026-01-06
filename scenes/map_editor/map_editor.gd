extends Node2D
class_name MapEditor

## Map Editor for creating GoCars levels using RoadTile instances
##
## Selection-Based Road Placement:
## - Click empty area: Place isolated road, becomes selected
## - Click existing road: Select that road
## - Selected road shows 8 preview tiles for neighbors
## - Click preview: Place/connect road there, new road becomes selected
## - Click outside previews: Deselect
## - Right-click: Delete road

signal tile_placed(position: Vector2i, is_road: bool)
signal road_tool_toggled(enabled: bool)
signal road_selected(position: Vector2i)
signal road_deselected()

# Direction vectors for checking all 8 neighbors (1 step)
const DIRECTIONS = {
	"top_left": Vector2i(-1, -1),
	"top": Vector2i(0, -1),
	"top_right": Vector2i(1, -1),
	"left": Vector2i(-1, 0),
	"right": Vector2i(1, 0),
	"bottom_left": Vector2i(-1, 1),
	"bottom": Vector2i(0, 1),
	"bottom_right": Vector2i(1, 1)
}

# Extended direction vectors for 2-step neighbors
const EXTENDED_DIRECTIONS = {
	"top_top": Vector2i(0, -2),
	"bottom_bottom": Vector2i(0, 2),
	"left_left": Vector2i(-2, 0),
	"right_right": Vector2i(2, 0),
	"top_left_top_left": Vector2i(-2, -2),
	"top_right_top_right": Vector2i(2, -2),
	"bottom_left_bottom_left": Vector2i(-2, 2),
	"bottom_right_bottom_right": Vector2i(2, 2)
}

# References
var road_tiles_container: Node2D
var camera: Camera2D
var road_tool_button: Button

# Preload the RoadTile scene
var road_tile_scene: PackedScene = preload("res://scenes/map_editor/road_tile.tscn")

# Dictionary to track placed road tiles by grid position
var road_tiles: Dictionary = {}  # Vector2i -> RoadTile instance

# Preview tiles (8 for each neighbor direction)
var preview_tiles: Dictionary = {}  # direction_name -> RoadTile instance

# Selection state
var selected_pos: Vector2i = Vector2i(-9999, -9999)  # Currently selected road position
var has_selection: bool = false

# Road tool state
var road_tool_enabled: bool = true
var is_erasing: bool = false

# Camera settings
const CAMERA_SPEED: float = 400.0
const ZOOM_SPEED: float = 0.1
const MIN_ZOOM: float = 0.25
const MAX_ZOOM: float = 3.0

# Tile size for positioning (3x larger: 144x144 main tiles)
const TILE_SIZE: int = 144


func _ready() -> void:
	road_tiles_container = $RoadTiles
	camera = $Camera2D

	# Get road tool button if it exists
	road_tool_button = get_node_or_null("UI/TopBar/RoadToolButton")
	if road_tool_button:
		road_tool_button.toggled.connect(_on_road_tool_toggled)
		road_tool_button.button_pressed = road_tool_enabled

	# Get clear button if it exists
	var clear_button = get_node_or_null("UI/TopBar/ClearButton")
	if clear_button:
		clear_button.pressed.connect(clear_map)

	# Create 8 preview tiles (one for each direction)
	_create_preview_tiles()


func _create_preview_tiles() -> void:
	for dir_name in DIRECTIONS:
		var preview = road_tile_scene.instantiate()
		preview.set_preview(true)
		preview.visible = false
		add_child(preview)
		preview_tiles[dir_name] = preview


func _process(delta: float) -> void:
	_handle_camera_movement(delta)
	_update_previews()


func _handle_camera_movement(delta: float) -> void:
	var move_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_direction.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_direction.x += 1

	if move_direction != Vector2.ZERO:
		move_direction = move_direction.normalized()
		var adjusted_speed = CAMERA_SPEED / camera.zoom.x
		camera.position += move_direction * adjusted_speed * delta


func _update_previews() -> void:
	if not road_tool_enabled or not has_selection:
		_hide_all_previews()
		return

	# Get mouse position and find closest preview direction
	var mouse_pos = get_global_mouse_position()
	var selected_world_center = _tile_to_world(selected_pos) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	var direction_to_mouse = mouse_pos - selected_world_center

	# Find the direction that best matches where mouse is pointing
	var best_dir = _get_closest_direction(direction_to_mouse)

	# Hide all previews first
	_hide_all_previews()

	# If no valid direction found, return
	if best_dir == "":
		return

	# Show only the preview in the best direction
	var preview = preview_tiles[best_dir]
	var neighbor_pos = selected_pos + DIRECTIONS[best_dir]

	# Position the preview
	preview.position = _tile_to_world(neighbor_pos)

	# Calculate connection (pointing back to selected road)
	var preview_connections = {}
	for d in DIRECTIONS:
		preview_connections[d] = false

	var opposite_dir = RoadTile.get_opposite_direction(best_dir)
	preview_connections[opposite_dir] = true

	# If there's already a road at neighbor, show it connecting
	if road_tiles.has(neighbor_pos):
		# Copy existing connections and add the new one
		var existing_tile = road_tiles[neighbor_pos]
		for d in DIRECTIONS:
			preview_connections[d] = existing_tile.has_connection(d) or (d == opposite_dir)

	# Calculate extended connections for preview
	var extended = _calculate_extended_connections_for_preview(neighbor_pos, preview_connections)
	preview.set_all_connections(preview_connections, extended)
	preview.visible = true


## Get the direction that best matches a vector from center to mouse
func _get_closest_direction(direction_vec: Vector2) -> String:
	if direction_vec.length() < 10.0:
		return ""  # Mouse too close to center

	# Normalize to compare angles
	var normalized = direction_vec.normalized()

	# Define direction vectors for each of the 8 directions
	var dir_vectors = {
		"top": Vector2(0, -1),
		"bottom": Vector2(0, 1),
		"left": Vector2(-1, 0),
		"right": Vector2(1, 0),
		"top_left": Vector2(-1, -1).normalized(),
		"top_right": Vector2(1, -1).normalized(),
		"bottom_left": Vector2(-1, 1).normalized(),
		"bottom_right": Vector2(1, 1).normalized()
	}

	var best_dir = ""
	var best_dot = -2.0

	for dir_name in dir_vectors:
		var dot = normalized.dot(dir_vectors[dir_name])
		if dot > best_dot:
			best_dot = dot
			best_dir = dir_name

	return best_dir


func _calculate_extended_connections_for_preview(pos: Vector2i, connections: Dictionary) -> Dictionary:
	var extended = {}

	for ext_dir in EXTENDED_DIRECTIONS:
		extended[ext_dir] = false

		var base_dir = ""
		match ext_dir:
			"top_top": base_dir = "top"
			"bottom_bottom": base_dir = "bottom"
			"left_left": base_dir = "left"
			"right_right": base_dir = "right"
			"top_left_top_left": base_dir = "top_left"
			"top_right_top_right": base_dir = "top_right"
			"bottom_left_bottom_left": base_dir = "bottom_left"
			"bottom_right_bottom_right": base_dir = "bottom_right"

		if base_dir == "":
			continue

		if not connections.get(base_dir, false):
			continue

		var neighbor_pos = pos + DIRECTIONS[base_dir]
		var neighbor = road_tiles.get(neighbor_pos)
		if neighbor and neighbor.has_connection(base_dir):
			extended[ext_dir] = true

	return extended


func _hide_all_previews() -> void:
	for dir_name in preview_tiles:
		preview_tiles[dir_name].visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(-ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_erasing = false
			_handle_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_erasing = true
				_erase_at_mouse_position()
			else:
				is_erasing = false

	elif event is InputEventMouseMotion:
		if is_erasing and road_tool_enabled:
			_erase_at_mouse_position()


func _handle_click() -> void:
	if not road_tool_enabled:
		return

	var mouse_pos = get_global_mouse_position()
	var tile_pos = _world_to_tile(mouse_pos)

	# Check if clicked on a preview position (neighbor of selected)
	if has_selection:
		var clicked_preview_dir = _get_clicked_preview_direction(tile_pos)

		if clicked_preview_dir != "":
			# Clicked on a preview - place/connect road there
			_place_or_connect_at_preview(clicked_preview_dir)
			return
		elif tile_pos == selected_pos:
			# Clicked on the selected road itself - do nothing or deselect
			return

	# Check if clicked on existing road
	if road_tiles.has(tile_pos):
		# Select this road
		_select_road(tile_pos)
	else:
		# Clicked on empty space
		if has_selection:
			# Check if it's a neighbor of selected
			var dir = _get_direction_between(selected_pos, tile_pos)
			if dir != "":
				# It's a neighbor - place and connect
				_place_road(tile_pos)
				_connect_tiles(selected_pos, tile_pos, dir)
				_select_road(tile_pos)
			else:
				# Not a neighbor - deselect and place isolated road
				_deselect_road()
				_place_road(tile_pos)
				_select_road(tile_pos)
		else:
			# No selection - place isolated road and select it
			_place_road(tile_pos)
			_select_road(tile_pos)


func _get_clicked_preview_direction(tile_pos: Vector2i) -> String:
	if not has_selection:
		return ""

	for dir_name in DIRECTIONS:
		var preview_pos = selected_pos + DIRECTIONS[dir_name]
		if tile_pos == preview_pos:
			return dir_name

	return ""


func _place_or_connect_at_preview(direction: String) -> void:
	var target_pos = selected_pos + DIRECTIONS[direction]

	if road_tiles.has(target_pos):
		# Connect to existing road
		_connect_tiles(selected_pos, target_pos, direction)
		_select_road(target_pos)
	else:
		# Place new road and connect
		_place_road(target_pos)
		_connect_tiles(selected_pos, target_pos, direction)
		_select_road(target_pos)


func _select_road(pos: Vector2i) -> void:
	# Deselect previous if any
	if has_selection and road_tiles.has(selected_pos):
		var prev_tile = road_tiles[selected_pos]
		prev_tile.modulate = Color.WHITE  # Reset color

	selected_pos = pos
	has_selection = true

	# Highlight selected road
	if road_tiles.has(pos):
		var tile = road_tiles[pos]
		tile.modulate = Color(1.2, 1.2, 1.0)  # Slight yellow tint

	road_selected.emit(pos)


func _deselect_road() -> void:
	if has_selection and road_tiles.has(selected_pos):
		var prev_tile = road_tiles[selected_pos]
		prev_tile.modulate = Color.WHITE  # Reset color

	has_selection = false
	selected_pos = Vector2i(-9999, -9999)
	_hide_all_previews()
	road_deselected.emit()


func _zoom_camera(zoom_change: float) -> void:
	var new_zoom = camera.zoom.x + zoom_change
	new_zoom = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(new_zoom, new_zoom)


func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / TILE_SIZE), floor(world_pos.y / TILE_SIZE))


func _tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)


func _get_direction_between(from_pos: Vector2i, to_pos: Vector2i) -> String:
	var diff = to_pos - from_pos
	for dir_name in DIRECTIONS:
		if DIRECTIONS[dir_name] == diff:
			return dir_name
	return ""  # Not neighbors


func _place_road(pos: Vector2i) -> void:
	# Don't place if already exists
	if road_tiles.has(pos):
		return

	# Create new RoadTile instance
	var road_tile = road_tile_scene.instantiate()
	road_tile.position = _tile_to_world(pos)
	road_tiles_container.add_child(road_tile)
	road_tiles[pos] = road_tile

	# No auto-connections - tile starts isolated
	tile_placed.emit(pos, true)


func _connect_tiles(pos_a: Vector2i, pos_b: Vector2i, direction: String) -> void:
	# Connect two tiles bidirectionally
	var tile_a = road_tiles.get(pos_a)
	var tile_b = road_tiles.get(pos_b)

	if tile_a and tile_b:
		var opposite = RoadTile.get_opposite_direction(direction)
		tile_a.add_connection(direction)
		tile_b.add_connection(opposite)

		# Update extended connections for both tiles and their neighbors
		_update_extended_connections(pos_a)
		_update_extended_connections(pos_b)

		# Update 2-step neighbors that might be affected
		for dir_name in EXTENDED_DIRECTIONS:
			var neighbor_pos = pos_a + EXTENDED_DIRECTIONS[dir_name]
			_update_extended_connections(neighbor_pos)
			neighbor_pos = pos_b + EXTENDED_DIRECTIONS[dir_name]
			_update_extended_connections(neighbor_pos)


func _disconnect_tile(pos: Vector2i) -> void:
	# Remove all connections from a tile and update neighbors
	var tile = road_tiles.get(pos)
	if not tile:
		return

	# Remove connections from neighbors pointing to this tile
	for dir_name in DIRECTIONS:
		if tile.has_connection(dir_name):
			var neighbor_pos = pos + DIRECTIONS[dir_name]
			var neighbor = road_tiles.get(neighbor_pos)
			if neighbor:
				var opposite = RoadTile.get_opposite_direction(dir_name)
				neighbor.remove_connection(opposite)
				_update_extended_connections(neighbor_pos)


func _update_extended_connections(pos: Vector2i) -> void:
	var tile = road_tiles.get(pos)
	if not tile:
		return

	var extended = _calculate_extended_connections(pos, tile.connections)
	for dir in extended:
		tile.set_extended_connection(dir, extended[dir])


func _calculate_extended_connections(pos: Vector2i, connections: Dictionary) -> Dictionary:
	var extended = {}

	# For each extended direction, check if there's a chain of connections
	# top_top: need connection to top, and top tile has connection to its top
	for ext_dir in EXTENDED_DIRECTIONS:
		extended[ext_dir] = false

		# Parse the direction (e.g., "top_top" -> check "top" twice)
		var base_dir = ""
		match ext_dir:
			"top_top": base_dir = "top"
			"bottom_bottom": base_dir = "bottom"
			"left_left": base_dir = "left"
			"right_right": base_dir = "right"
			"top_left_top_left": base_dir = "top_left"
			"top_right_top_right": base_dir = "top_right"
			"bottom_left_bottom_left": base_dir = "bottom_left"
			"bottom_right_bottom_right": base_dir = "bottom_right"

		if base_dir == "":
			continue

		# Check if this tile is connected in base_dir
		if not connections.get(base_dir, false):
			continue

		# Check if the neighbor in base_dir is connected further in base_dir
		var neighbor_pos = pos + DIRECTIONS[base_dir]
		var neighbor = road_tiles.get(neighbor_pos)
		if neighbor and neighbor.has_connection(base_dir):
			extended[ext_dir] = true

	return extended


func _erase_at_mouse_position() -> void:
	if not road_tool_enabled:
		return

	var mouse_pos = get_global_mouse_position()
	var tile_pos = _world_to_tile(mouse_pos)
	_remove_road(tile_pos)


func _remove_road(pos: Vector2i) -> void:
	if not road_tiles.has(pos):
		return

	# If deleting selected road, deselect first
	if has_selection and pos == selected_pos:
		_deselect_road()

	# Disconnect from all neighbors first
	_disconnect_tile(pos)

	# Remove the RoadTile instance
	var road_tile = road_tiles[pos]
	road_tile.queue_free()
	road_tiles.erase(pos)

	# Update extended connections for nearby tiles
	for dir_name in DIRECTIONS:
		var neighbor_pos = pos + DIRECTIONS[dir_name]
		_update_extended_connections(neighbor_pos)
	for dir_name in EXTENDED_DIRECTIONS:
		var neighbor_pos = pos + EXTENDED_DIRECTIONS[dir_name]
		_update_extended_connections(neighbor_pos)

	tile_placed.emit(pos, false)


func _on_road_tool_toggled(pressed: bool) -> void:
	road_tool_enabled = pressed
	if not pressed:
		_deselect_road()
	road_tool_toggled.emit(pressed)


func set_road_tool_enabled(enabled: bool) -> void:
	road_tool_enabled = enabled
	if road_tool_button:
		road_tool_button.button_pressed = enabled
	if not enabled:
		_deselect_road()


func clear_map() -> void:
	_deselect_road()
	for pos in road_tiles:
		var road_tile = road_tiles[pos]
		road_tile.queue_free()
	road_tiles.clear()


func is_road_at(pos: Vector2i) -> bool:
	return road_tiles.has(pos)


func get_all_road_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for pos in road_tiles:
		positions.append(pos)
	return positions
