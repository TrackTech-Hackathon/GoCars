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

# References to connection sprites (4 cardinal directions)
@onready var connection_sprites: Dictionary = {
	"top": $ConnectionSprites/Top,
	"left": $ConnectionSprites/Left,
	"right": $ConnectionSprites/Right,
	"bottom": $ConnectionSprites/Bottom
}

@onready var main_sprite: Sprite2D = $MainSprite

# Manual connections - which directions this tile is connected to
# Unlike neighbors, connections are explicitly set (not auto-detected)
var connections: Dictionary = {
	"top": false,
	"left": false,
	"right": false,
	"bottom": false
}

# Extended connection state for 2-step visibility rules
var extended_connections: Dictionary = {
	"top_top": false,
	"bottom_bottom": false,
	"left_left": false,
	"right_right": false
}

# Preview mode - tile shows at 50% opacity
var is_preview: bool = false

# Debug mode - show guideline paths visually
var show_guidelines: bool = false

# Lazy path calculation flag - paths recalculated on first access
var _paths_dirty: bool = true


func _ready() -> void:
	update_connection_sprites()
	_update_opacity()
	# Don't call _update_through_paths() here - global_position may not be set yet
	# Paths will be calculated when add_connection() is called


func _draw() -> void:
	if not show_guidelines:
		return

	# Ensure paths are calculated before drawing
	if _paths_dirty:
		_update_through_paths()
		_paths_dirty = false

	# Draw all through-paths for debugging
	for entry_dir in through_paths:
		for exit_dir in through_paths[entry_dir]:
			var path = through_paths[entry_dir][exit_dir]
			if path.size() >= 2:
				# Convert world positions to local for drawing
				var local_path: Array = []
				for point in path:
					local_path.append(point - global_position)

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
		# Cardinals
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

	# Cardinal sprites - check adjacent and 2-step cardinal
	connection_sprites["top"].visible = _should_show_cardinal(
		connections["top"],
		connections["left"], connections["right"],
		extended_connections["top_top"]
	)

	connection_sprites["bottom"].visible = _should_show_cardinal(
		connections["bottom"],
		connections["left"], connections["right"],
		extended_connections["bottom_bottom"]
	)

	connection_sprites["left"].visible = _should_show_cardinal(
		connections["left"],
		connections["top"], connections["bottom"],
		extended_connections["left_left"]
	)

	connection_sprites["right"].visible = _should_show_cardinal(
		connections["right"],
		connections["top"], connections["bottom"],
		extended_connections["right_right"]
	)


func _should_show_cardinal(has_connection: bool, _adjacent1: bool, _adjacent2: bool, _has_2step: bool) -> bool:
	# Simplified: just show the connection if it exists
	# The complex rules were for auto-tiling, but we use manual connections now
	return has_connection


# Add a connection in a specific direction
func add_connection(direction: String) -> void:
	if connections.has(direction):
		connections[direction] = true
		update_connection_sprites()
		_paths_dirty = true  # Mark for lazy recalculation
		queue_redraw()  # Redraw guidelines


# Remove a connection in a specific direction
func remove_connection(direction: String) -> void:
	if connections.has(direction):
		connections[direction] = false
		update_connection_sprites()
		_paths_dirty = true  # Mark for lazy recalculation
		queue_redraw()  # Redraw guidelines


# Mark paths as dirty (forces recalculation on next access)
func mark_paths_dirty() -> void:
	_paths_dirty = true
	queue_redraw()


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
	_paths_dirty = true  # Mark for lazy recalculation
	queue_redraw()  # Redraw guidelines


# Get opposite direction for bidirectional connections
static func get_opposite_direction(direction: String) -> String:
	match direction:
		"top": return "bottom"
		"bottom": return "top"
		"left": return "right"
		"right": return "left"
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
	if _paths_dirty:
		_update_through_paths()
		_paths_dirty = false
	if entry_dir in through_paths:
		return through_paths[entry_dir].keys()
	return []


## Get the waypoint path for a specific entry -> exit traversal
## Returns world positions (not relative to tile)
func get_guideline_path(entry_dir: String, exit_dir: String) -> Array:
	if _paths_dirty:
		_update_through_paths()
		_paths_dirty = false
	if entry_dir in through_paths and exit_dir in through_paths[entry_dir]:
		return through_paths[entry_dir][exit_dir]
	return []


## Update through-paths when connections change
func _update_through_paths() -> void:
	through_paths.clear()

	# Get all active connections (cardinals AND diagonals)
	var active_connections: Array = []
	for dir in connections:
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
## Waypoints are in world coordinates (based on tile global position)
func _calculate_path_waypoints(entry: String, exit_dir: String) -> Array:
	var points: Array = []
	# Use global_position to ensure waypoints are in world coordinates
	# (position is local to parent, which may have an offset)
	var tile_center = global_position + Vector2(HALF_TILE, HALF_TILE)

	# Check if this is a straight path or a turn
	var is_straight = _get_axis(entry) == _get_axis(exit_dir)

	if is_straight:
		# Straight path - both points have SAME lane offset for straight travel
		var lane_offset = _get_straight_lane_offset(entry, exit_dir)
		var entry_point = _get_edge_center(entry, tile_center) + lane_offset
		var exit_point = _get_edge_center(exit_dir, tile_center) + lane_offset
		points.append(entry_point)
		points.append(exit_point)
	else:
		# Turn - need different lane offsets and a corner point
		var entry_point = _get_turn_edge_point(entry, exit_dir, tile_center, true)
		var corner = _get_corner_point(entry, exit_dir, tile_center)
		var exit_point = _get_turn_edge_point(entry, exit_dir, tile_center, false)
		points.append(entry_point)
		points.append(corner)
		points.append(exit_point)

	return points


## Get the center of an edge (no lane offset)
func _get_edge_center(dir: String, tile_center: Vector2) -> Vector2:
	match dir:
		# Cardinals - edge centers
		"top": return tile_center + Vector2(0, -HALF_TILE)
		"bottom": return tile_center + Vector2(0, HALF_TILE)
		"left": return tile_center + Vector2(-HALF_TILE, 0)
		"right": return tile_center + Vector2(HALF_TILE, 0)
	return tile_center


## Get lane offset for straight paths based on travel direction
func _get_straight_lane_offset(entry: String, exit_dir: String) -> Vector2:
	# For straight paths, lane offset depends on direction of travel
	# Right-hand driving: offset to the RIGHT of travel direction (90° clockwise)
	match entry + "_" + exit_dir:
		# Cardinal straights
		"left_right":  # Traveling RIGHT -> right side is DOWN (+Y)
			return Vector2(0, LANE_OFFSET)
		"right_left":  # Traveling LEFT -> right side is UP (-Y)
			return Vector2(0, -LANE_OFFSET)
		"top_bottom":  # Traveling DOWN -> right side is LEFT (-X)
			return Vector2(-LANE_OFFSET, 0)
		"bottom_top":  # Traveling UP -> right side is RIGHT (+X)
			return Vector2(LANE_OFFSET, 0)
	return Vector2.ZERO


## Get edge point for turns (entry or exit)
func _get_turn_edge_point(entry: String, exit_dir: String, tile_center: Vector2, is_entry: bool) -> Vector2:
	var edge = entry if is_entry else exit_dir
	var edge_center = _get_edge_center(edge, tile_center)

	# For turns, calculate offset based on which part of the turn we're on
	# Right-hand driving: offset to the RIGHT of travel direction
	if is_entry:
		# Entry point - offset based on entry direction's travel
		var offset = _get_entry_lane_offset(entry)
		return edge_center + offset
	else:
		# Exit point - offset based on exit direction's travel
		var offset = _get_exit_lane_offset(exit_dir)
		return edge_center + offset


## Get corner waypoint for turns
## The corner connects the entry lane to the exit lane (lane-aware)
func _get_corner_point(entry: String, exit_dir: String, tile_center: Vector2) -> Vector2:
	# Get the lane offsets for entry and exit
	var entry_offset = _get_entry_lane_offset(entry)
	var exit_offset = _get_exit_lane_offset(exit_dir)

	var entry_axis = _get_axis(entry)
	var exit_axis = _get_axis(exit_dir)

	# Cardinal to cardinal turns
	if entry_axis <= 1 and exit_axis <= 1:
		match entry + "_" + exit_dir:
			# Entering horizontally (left/right), exiting vertically (top/bottom)
			"left_top", "left_bottom", "right_top", "right_bottom":
				return tile_center + Vector2(exit_offset.x, entry_offset.y)
			# Entering vertically (top/bottom), exiting horizontally (left/right)
			"top_left", "top_right", "bottom_left", "bottom_right":
				return tile_center + Vector2(entry_offset.x, exit_offset.y)

	# Fallback to center
	return tile_center


## Get lane offset for entry direction (where car enters the tile)
func _get_entry_lane_offset(entry: String) -> Vector2:
	# Right-hand driving: car is on RIGHT side of travel direction (90° clockwise)
	match entry:
		"left":   return Vector2(0, LANE_OFFSET)    # Traveling right, right side is DOWN (+Y)
		"right":  return Vector2(0, -LANE_OFFSET)   # Traveling left, right side is UP (-Y)
		"top":    return Vector2(-LANE_OFFSET, 0)   # Traveling down, right side is LEFT (-X)
		"bottom": return Vector2(LANE_OFFSET, 0)    # Traveling up, right side is RIGHT (+X)
	return Vector2.ZERO


## Get lane offset for exit direction (where car exits the tile)
func _get_exit_lane_offset(exit_dir: String) -> Vector2:
	# Right-hand driving: car is on RIGHT side of travel direction (90° clockwise)
	match exit_dir:
		"left":   return Vector2(0, -LANE_OFFSET)   # Traveling left, right side is UP (-Y)
		"right":  return Vector2(0, LANE_OFFSET)    # Traveling right, right side is DOWN (+Y)
		"top":    return Vector2(LANE_OFFSET, 0)    # Traveling up, right side is RIGHT (+X)
		"bottom": return Vector2(-LANE_OFFSET, 0)   # Traveling down, right side is LEFT (-X)
	return Vector2.ZERO


## Get axis for a direction (0 = horizontal, 1 = vertical)
func _get_axis(dir: String) -> int:
	match dir:
		"left", "right":
			return 0  # Horizontal
		"top", "bottom":
			return 1  # Vertical
	return -1


## Get the direction to the left of the given entry direction
static func get_left_of(entry: String) -> String:
	# When entering from a direction, left is relative to movement (turn left = 90° counter-clockwise)
	match entry:
		# Entry is where car CAME FROM, so travel direction is opposite
		"right": return "bottom" # Traveling left (west), turn left → go south
		"left": return "top"     # Traveling right (east), turn left → go north
		"top": return "right"    # Traveling down (south), turn left → go east
		"bottom": return "left"  # Traveling up (north), turn left → go west
	return ""


## Get the direction to the right of the given entry direction
static func get_right_of(entry: String) -> String:
	# When entering from a direction, right is relative to movement (turn right = 90° clockwise)
	match entry:
		# Entry is where car CAME FROM, so travel direction is opposite
		"right": return "top"    # Traveling left (west), turn right → go north
		"left": return "bottom"  # Traveling right (east), turn right → go south
		"top": return "left"     # Traveling down (south), turn right → go west
		"bottom": return "right" # Traveling up (north), turn right → go east
	return ""
