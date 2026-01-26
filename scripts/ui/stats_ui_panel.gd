extends CanvasLayer
class_name StatsUIPanel

## UI Panel that follows the mouse and displays stats for hovered vehicles
## Reads stats from vehicle's StatsNode labels

@onready var panel: Panel = $Panel
@onready var type_label: Label = $Panel/VBoxContainer/TypeLabel
@onready var color_label: Label = $Panel/VBoxContainer/ColorLabel
@onready var group_label: Label = $Panel/VBoxContainer/GroupLabel
@onready var speed_label: Label = $Panel/VBoxContainer/SpeedLabel
@onready var facing_label: Label = $Panel/VBoxContainer/FacingLabel
@onready var state_label: Label = $Panel/VBoxContainer/StateLabel

# Currently hovered vehicle
var _hovered_vehicle: Node2D = null

# Panel offset from mouse
const PANEL_OFFSET: Vector2 = Vector2(15, 15)


func _ready() -> void:
	# Start hidden
	panel.visible = false


func _process(_delta: float) -> void:
	# Update panel position to follow mouse
	if panel.visible:
		var mouse_pos = get_viewport().get_mouse_position()
		var viewport_size = get_viewport().get_visible_rect().size

		# Calculate panel position with offset
		var panel_pos = mouse_pos + PANEL_OFFSET

		# Keep panel within viewport bounds
		if panel_pos.x + panel.size.x > viewport_size.x:
			panel_pos.x = mouse_pos.x - panel.size.x - PANEL_OFFSET.x
		if panel_pos.y + panel.size.y > viewport_size.y:
			panel_pos.y = mouse_pos.y - panel.size.y - PANEL_OFFSET.y

		panel.position = panel_pos

		# Update stats from hovered vehicle
		if _hovered_vehicle and is_instance_valid(_hovered_vehicle):
			_update_stats_from_vehicle(_hovered_vehicle)
		else:
			hide_panel()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_check_vehicle_hover()


## Check if mouse is hovering over any vehicle
func _check_vehicle_hover() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	# Convert screen position to world position using the main camera
	var camera = get_viewport().get_camera_2d()
	var world_mouse_pos = mouse_pos
	if camera:
		world_mouse_pos = camera.get_global_mouse_position()

	# Get all vehicles
	var vehicles = get_tree().get_nodes_in_group("vehicles")
	var found_vehicle: Node2D = null

	for vehicle in vehicles:
		if not is_instance_valid(vehicle):
			continue

		# Get local position relative to vehicle
		var local_pos = vehicle.to_local(world_mouse_pos)

		# Get vehicle size multiplier
		var size_mult = 1.0
		if vehicle.has_method("get") and "type_size_mult" in vehicle:
			size_mult = vehicle.type_size_mult

		# Use a bounding box for hover detection (48x96 is base car sprite size)
		var half_width = 24.0 * size_mult
		var half_height = 48.0 * size_mult

		if abs(local_pos.x) < half_width and abs(local_pos.y) < half_height:
			found_vehicle = vehicle
			break

	if found_vehicle:
		if found_vehicle != _hovered_vehicle:
			_hovered_vehicle = found_vehicle
			show_panel()
	else:
		if _hovered_vehicle != null:
			_hovered_vehicle = null
			hide_panel()


## Show the panel and update stats
func show_panel() -> void:
	panel.visible = true
	if _hovered_vehicle:
		_update_stats_from_vehicle(_hovered_vehicle)


## Hide the panel
func hide_panel() -> void:
	panel.visible = false
	_hovered_vehicle = null


## Update stats labels from vehicle's StatsNode
func _update_stats_from_vehicle(vehicle: Node2D) -> void:
	var stats_node = vehicle.get_node_or_null("StatsNode")

	if stats_node:
		# Read from vehicle's stats labels
		var type_lbl = stats_node.get_node_or_null("TypeLabel")
		var color_lbl = stats_node.get_node_or_null("ColorLabel")
		var group_lbl = stats_node.get_node_or_null("GroupLabel")
		var speed_lbl = stats_node.get_node_or_null("SpeedLabel")
		var facing_lbl = stats_node.get_node_or_null("FacingLabel")
		var state_lbl = stats_node.get_node_or_null("StateLabel")

		if type_lbl:
			type_label.text = "Type: %s" % type_lbl.text
		if color_lbl:
			color_label.text = "Color: %s" % color_lbl.text
		if group_lbl:
			group_label.text = "Group: %s" % group_lbl.text
		if speed_lbl:
			speed_label.text = "Speed: %s" % speed_lbl.text
		if facing_lbl:
			facing_label.text = "Facing: %s" % facing_lbl.text
		if state_lbl:
			state_label.text = "State: %s" % state_lbl.text
	else:
		# Fallback: Read directly from vehicle methods if no StatsNode
		if vehicle.has_method("get_vehicle_type_name"):
			type_label.text = "Type: %s" % vehicle.get_vehicle_type_name()
		if vehicle.has_method("get_color_name"):
			color_label.text = "Color: %s" % vehicle.get_color_name()
		if vehicle.has_method("get_spawn_group_name"):
			group_label.text = "Group: %s" % vehicle.get_spawn_group_name()
		if "speed" in vehicle and "speed_multiplier" in vehicle and "type_speed_mult" in vehicle:
			var effective_speed = vehicle.speed * vehicle.speed_multiplier * vehicle.type_speed_mult
			speed_label.text = "Speed: %.1f" % effective_speed
		if vehicle.has_method("get_facing_direction_name"):
			facing_label.text = "Facing: %s" % vehicle.get_facing_direction_name()
		if vehicle.has_method("get_state_name"):
			state_label.text = "State: %s" % vehicle.get_state_name()
