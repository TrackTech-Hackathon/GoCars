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


func _ready() -> void:
	update_connection_sprites()
	_update_opacity()


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
	if not has_connection:
		return false
	if not adjacent1 and not adjacent2:
		return true
	if (adjacent1 or adjacent2) and has_2step:
		return true
	return false


func _should_show_diagonal(has_connection: bool, adjacent1: bool, adjacent2: bool, has_2step: bool) -> bool:
	if not has_connection:
		return false
	if not adjacent1 and not adjacent2:
		return true
	if (adjacent1 or adjacent2) and has_2step:
		return true
	return false


# Add a connection in a specific direction
func add_connection(direction: String) -> void:
	if connections.has(direction):
		connections[direction] = true
		update_connection_sprites()


# Remove a connection in a specific direction
func remove_connection(direction: String) -> void:
	if connections.has(direction):
		connections[direction] = false
		update_connection_sprites()


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
