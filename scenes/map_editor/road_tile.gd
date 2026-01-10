extends Area2D
class_name RoadTile

## A single road tile with connection sprites behind it
##
## Structure:
## - MainSprite: 144x144 road tile at center
## - ConnectionSprites: 8 Sprite2D children (432x432 each) for neighbor connections
##
## Connections are stored manually - roads only connect when explicitly linked
## Preview mode shows the tile at 50% opacity

# References to connection sprites (8 directions)
@onready var connection_sprites: Dictionary = {
	"top_left": $ConnectionSprites/TopLeft,
	"top": $ConnectionSprites/Top,
	"top_right": $ConnectionSprites/TopRight,
	"left": $ConnectionSprites/Left,
	"right": $ConnectionSprites/Right,
	"bottom_left": $ConnectionSprites/BottomLeft,
	"bottom": $ConnectionSprites/Bottom,
	"bottom_right": $ConnectionSprites/BottomRight
}

@onready var main_sprite: Sprite2D = $MainSprite

# Manual connections - which directions this tile is connected to
# Unlike neighbors, connections are explicitly set (not auto-detected)
var connections: Dictionary = {
	"top_left": false,
	"top": false,
	"top_right": false,
	"left": false,
	"right": false,
	"bottom_left": false,
	"bottom": false,
	"bottom_right": false
}

# Extended connection state for 2-step visibility rules
var extended_connections: Dictionary = {
	"top_top": false,
	"bottom_bottom": false,
	"left_left": false,
	"right_right": false,
	"top_left_top_left": false,
	"top_right_top_right": false,
	"bottom_left_bottom_left": false,
	"bottom_right_bottom_right": false
}

# Preview mode - tile shows at 50% opacity
var is_preview: bool = false

# Debug mode - show guideline paths visually
var show_guidelines: bool = true  # Set to true for testing


func _ready() -> void:
	update_connection_sprites()
	_update_opacity()
	_update_through_paths()  # Generate initial paths


func _draw() -> void:
	if not show_guidelines:
		return

	# Draw all through-paths for debugging
	for entry_dir in through_paths:
		for exit_dir in through_paths[entry_dir]:
			var path = through_paths[entry_dir][exit_dir]
			if path.size() >= 2:
				# Convert world positions to local
				var local_path: Array = []
				for point in path:
					local_path.append(point - position)

				# Draw path segments
				for i in range(local_path.size() - 1):
					var from = local_path[i]
					var to = local_path[i + 1]
					# Color based on direction
					var color = _get_path_color(entry_dir)
					draw_line(from, to, color, 3.0)

				# Draw waypoint dots
				for point in local_path:
					draw_circle(point, 5.0, Color.WHITE)


## Get color for drawing path based on entry direction
func _get_path_color(entry_dir: String) -> Color:
	match entry_dir:
		"top": return Color(0.2, 0.8, 0.2, 0.8)     # Green
		"bottom": return Color(0.8, 0.2, 0.2, 0.8)  # Red
		"left": return Color(0.2, 0.2, 0.8, 0.8)    # Blue
		"right": return Color(0.8, 0.8, 0.2, 0.8)   # Yellow
	return Color.WHITE


func set_preview(preview: bool) -> void:
	is_preview = preview
	_update_opacity()
	# Disable collision in preview mode
	if is_preview:
		collision_layer = 0
		collision_mask = 0
	else:
		collision_layer = 2
		collision_mask = 0


func _update_opacity() -> void:
	var alpha = 0.5 if is_preview else 1.0
	modulate.a = alpha


func update_connection_sprites() -> void:
	# Apply visibility rules for each sprite

	# Cardinal sprites - check adjacent diagonals and 2-step cardinal
	connection_sprites["top"].visible = _should_show_cardinal(
		connections["top"],
		connections["top_left"], connections["top_right"],
		extended_connections["top_top"]
	)

	connection_sprites["bottom"].visible = _should_show_cardinal(
		connections["bottom"],
		connections["bottom_left"], connections["bottom_right"],
		extended_connections["bottom_bottom"]
	)

	connection_sprites["left"].visible = _should_show_cardinal(
		connections["left"],
		connections["top_left"], connections["bottom_left"],
		extended_connections["left_left"]
	)

	connection_sprites["right"].visible = _should_show_cardinal(
		connections["right"],
		connections["top_right"], connections["bottom_right"],
		extended_connections["right_right"]
	)

	# Diagonal sprites - check adjacent cardinals and 2-step diagonal
	connection_sprites["top_left"].visible = _should_show_diagonal(
		connections["top_left"],
		connections["top"], connections["left"],
		extended_connections["top_left_top_left"]
	)

	connection_sprites["top_right"].visible = _should_show_diagonal(
		connections["top_right"],
		connections["top"], connections["right"],
		extended_connections["top_right_top_right"]
	)

	connection_sprites["bottom_left"].visible = _should_show_diagonal(
		connections["bottom_left"],
		connections["bottom"], connections["left"],
		extended_connections["bottom_left_bottom_left"]
	)

	connection_sprites["bottom_right"].visible = _should_show_diagonal(
		connections["bottom_right"],
		connections["bottom"], connections["right"],
		extended_connections["bottom_right_bottom_right"]
	)


func _should_show_cardinal(has_connection: bool, adjacent1: bool, adjacent2: bool, has_2step: bool) -> bool:
	# Simplified: just show the connection if it exists
	# The complex rules were for auto-tiling, but we use manual connections now
	return has_connection


func _should_show_diagonal(has_connection: bool, adjacent1: bool, adjacent2: bool, has_2step: bool) -> bool:
	# Simplified: just show the connection if it exists
	# The complex rules were for auto-tiling, but we use manual connections now
	return has_connection


# Add a connection in a specific direction
func add_connection(direction: String) -> void:
	if connections.has(direction):
		connections[direction] = true
		update_connection_sprites()
		_update_through_paths()
		queue_redraw()  # Redraw guidelines


# Remove a connection in a specific direction
func remove_connection(direction: String) -> void:
	if connections.has(direction):
		connections[direction] = false
		update_connection_sprites()
		_update_through_paths()
		queue_redraw()  # Redraw guidelines


# Check if connected in a direction
func has_connection(direction: String) -> bool:
	return connections.get(direction, false)


# Set extended connection (for 2-step visibility rules)
func set_extended_connection(direction: String, value: bool) -> void:
	if extended_connections.has(direction):
		extended_connections[direction] = value
		update_connection_sprites()


# Set all connections at once
func set_all_connections(conn_dict: Dictionary, extended_dict: Dictionary = {}) -> void:
	for dir in conn_dict:
		if connections.has(dir):
			connections[dir] = conn_dict[dir]
	for dir in extended_dict:
		if extended_connections.has(dir):
			extended_connections[dir] = extended_dict[dir]
	update_connection_sprites()
	_update_through_paths()
	queue_redraw()  # Redraw guidelines


# Get opposite direction for bidirectional connections
static func get_opposite_direction(direction: String) -> String:
	match direction:
		"top": return "bottom"
		"bottom": return "top"
		"left": return "right"
		"right": return "left"
		"top_left": return "bottom_right"
		"top_right": return "bottom_left"
		"bottom_left": return "top_right"
		"bottom_right": return "top_left"
	return ""


# ============================================
# Guideline System - Through-Path Navigation
# ============================================

# Through-paths define how vehicles traverse this tile
# Key: entry_direction, Value: Dictionary of exit_direction -> Array of waypoints (world positions)
var through_paths: Dictionary = {}

# Tile constants for path calculation
const TILE_SIZE: float = 144.0
const HALF_TILE: float = 72.0
const LANE_OFFSET: float = 25.0  # Offset from center for lane driving


## Get available exit directions when entering from a given direction
func get_available_exits(entry_dir: String) -> Array:
	if entry_dir in through_paths:
		return through_paths[entry_dir].keys()
	return []


## Get the waypoint path for a specific entry -> exit traversal
## Returns world positions (not relative to tile)
func get_guideline_path(entry_dir: String, exit_dir: String) -> Array:
	if entry_dir in through_paths and exit_dir in through_paths[entry_dir]:
		return through_paths[entry_dir][exit_dir]
	return []


## Update through-paths when connections change
func _update_through_paths() -> void:
	through_paths.clear()

	# Get all active cardinal connections (vehicles only use cardinal directions)
	var active_connections: Array = []
	for dir in ["top", "bottom", "left", "right"]:
		if connections[dir]:
			active_connections.append(dir)

	# For each possible entry direction, calculate valid exits
	for entry in active_connections:
		through_paths[entry] = {}

		for exit_dir in active_connections:
			if exit_dir != entry:  # Can't exit where you entered
				var path = _calculate_path_waypoints(entry, exit_dir)
				through_paths[entry][exit_dir] = path


## Calculate waypoint path from entry to exit direction
## Waypoints are in world coordinates (based on tile position)
func _calculate_path_waypoints(entry: String, exit_dir: String) -> Array:
	var points: Array = []
	var tile_center = position + Vector2(HALF_TILE, HALF_TILE)

	# Entry point (at edge of tile, offset for lane)
	var entry_point = _get_edge_point(entry, tile_center)
	points.append(entry_point)

	# Check if turning (entry and exit on different axes)
	var entry_axis = _get_axis(entry)
	var exit_axis = _get_axis(exit_dir)

	if entry_axis != exit_axis:  # Turning
		# Add corner waypoint for smooth curve
		var corner = _get_corner_point(entry, exit_dir, tile_center)
		points.append(corner)

	# Exit point (at edge of tile, offset for lane)
	var exit_point = _get_edge_point(exit_dir, tile_center)
	points.append(exit_point)

	return points


## Get edge point with lane offset for a direction
func _get_edge_point(dir: String, tile_center: Vector2) -> Vector2:
	# Lane offset is perpendicular to movement direction
	# For cars moving RIGHT, offset is UP (negative Y) - driving on the left
	# For cars moving LEFT, offset is DOWN (positive Y)
	# etc.

	match dir:
		"top":
			# Entering/exiting from top, car moves vertically
			# Lane offset: left side of road = negative X
			return tile_center + Vector2(-LANE_OFFSET, -HALF_TILE)
		"bottom":
			# Lane offset: right side when going down = positive X
			return tile_center + Vector2(LANE_OFFSET, HALF_TILE)
		"left":
			# Lane offset: top side when going left = negative Y
			return tile_center + Vector2(-HALF_TILE, -LANE_OFFSET)
		"right":
			# Lane offset: bottom side when going right = positive Y
			return tile_center + Vector2(HALF_TILE, LANE_OFFSET)

	return tile_center


## Get corner waypoint for turns
func _get_corner_point(entry: String, exit_dir: String, tile_center: Vector2) -> Vector2:
	# Corner point is near the intersection of entry and exit paths
	# Offset inward from the corner for smooth curve

	var corner_offset = LANE_OFFSET * 0.7  # Slightly inside the lane

	# Determine which corner based on entry/exit combination
	match entry + "_" + exit_dir:
		"right_top", "bottom_left":
			# Top-left area of tile
			return tile_center + Vector2(-corner_offset, -corner_offset)
		"right_bottom", "top_left":
			# Bottom-left area
			return tile_center + Vector2(-corner_offset, corner_offset)
		"left_top", "bottom_right":
			# Top-right area
			return tile_center + Vector2(corner_offset, -corner_offset)
		"left_bottom", "top_right":
			# Bottom-right area
			return tile_center + Vector2(corner_offset, corner_offset)

	# Fallback to center
	return tile_center


## Get axis for a direction (0 = horizontal, 1 = vertical)
func _get_axis(dir: String) -> int:
	if dir == "left" or dir == "right":
		return 0  # Horizontal
	return 1  # Vertical


## Get the direction to the left of the given entry direction
static func get_left_of(entry: String) -> String:
	# When entering from a direction, left is relative to movement
	match entry:
		"right": return "top"    # Moving left, left is up
		"left": return "bottom"  # Moving right, left is down
		"top": return "left"     # Moving down, left is left
		"bottom": return "right" # Moving up, left is right
	return ""


## Get the direction to the right of the given entry direction
static func get_right_of(entry: String) -> String:
	# When entering from a direction, right is relative to movement
	match entry:
		"right": return "bottom" # Moving left, right is down
		"left": return "top"     # Moving right, right is up
		"top": return "right"    # Moving down, right is right
		"bottom": return "left"  # Moving up, right is left
	return ""
