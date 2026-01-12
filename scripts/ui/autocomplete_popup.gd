## VSCode-style Autocomplete Popup for GoCars Code Editor
## Author: Claude Code
## Date: January 2026

extends Control
class_name AutocompletePopup

signal suggestion_selected(text: String)

var panel: PanelContainer
var item_list: ItemList

var suggestions: Array[Dictionary] = []
var filtered_suggestions: Array[Dictionary] = []
var current_prefix: String = ""
var selected_index: int = 0

func _init() -> void:
	# Don't use anchors - we'll position manually
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = Vector2(300, 200)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	visible = false

func _ready() -> void:
	# Create panel container
	panel = PanelContainer.new()
	panel.position = Vector2.ZERO
	panel.size = Vector2(300, 200)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	# Create item list inside panel
	item_list = ItemList.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.allow_reselect = true
	item_list.focus_mode = Control.FOCUS_NONE
	item_list.add_theme_constant_override("v_separation", 2)
	panel.add_child(item_list)

	# Connect signals
	item_list.item_selected.connect(_on_item_clicked)
	item_list.item_activated.connect(_on_item_clicked)

func show_suggestions(items: Array[Dictionary], prefix: String, global_pos: Vector2) -> void:
	suggestions = items
	current_prefix = prefix

	# Filter suggestions
	_filter_suggestions()

	if filtered_suggestions.is_empty():
		hide()
		return

	# Populate list
	item_list.clear()
	for suggestion in filtered_suggestions:
		var icon = _get_icon(suggestion.type)
		var display = icon + " " + suggestion.name
		var idx = item_list.add_item(display)
		item_list.set_item_custom_fg_color(idx, _get_color(suggestion.type))

	# Resize based on item count
	var item_count = min(filtered_suggestions.size(), 10)
	var item_height = 22
	var new_height = (item_count * item_height) + 8

	panel.size = Vector2(300, new_height)
	size = Vector2(300, new_height)

	# Position - convert global position to local
	if get_parent() is Control:
		var parent_global = get_parent().global_position
		position = global_pos - parent_global
	else:
		position = global_pos

	# Select first item
	selected_index = 0
	item_list.select(0)

	# Show
	visible = true

func update_filter(new_prefix: String) -> void:
	current_prefix = new_prefix
	_filter_suggestions()

	if filtered_suggestions.is_empty():
		hide()
		return

	# Repopulate list
	item_list.clear()
	for suggestion in filtered_suggestions:
		var icon = _get_icon(suggestion.type)
		var display = icon + " " + suggestion.name
		var idx = item_list.add_item(display)
		item_list.set_item_custom_fg_color(idx, _get_color(suggestion.type))

	# Resize
	var item_count = min(filtered_suggestions.size(), 10)
	var item_height = 22
	var new_height = (item_count * item_height) + 8
	panel.size = Vector2(300, new_height)
	size = Vector2(300, new_height)

	# Select first
	selected_index = 0
	item_list.select(0)

func select_next() -> void:
	if filtered_suggestions.is_empty():
		return
	selected_index = (selected_index + 1) % filtered_suggestions.size()
	item_list.select(selected_index)
	item_list.ensure_current_is_visible()

func select_previous() -> void:
	if filtered_suggestions.is_empty():
		return
	selected_index = (selected_index - 1 + filtered_suggestions.size()) % filtered_suggestions.size()
	item_list.select(selected_index)
	item_list.ensure_current_is_visible()

func confirm_selection() -> void:
	if filtered_suggestions.is_empty():
		return

	var suggestion = filtered_suggestions[selected_index]
	var text = suggestion.name

	# Add () for functions
	if suggestion.type == "function" or suggestion.type == "builtin":
		text += "()"

	hide()
	suggestion_selected.emit(text)

func _filter_suggestions() -> void:
	filtered_suggestions.clear()
	var prefix_lower = current_prefix.to_lower()

	for suggestion in suggestions:
		if suggestion.name.to_lower().begins_with(prefix_lower):
			filtered_suggestions.append(suggestion)

	# Limit to 20
	if filtered_suggestions.size() > 20:
		filtered_suggestions.resize(20)

func _on_item_clicked(index: int) -> void:
	selected_index = index
	confirm_selection()

func _get_icon(type: String) -> String:
	match type:
		"function": return "ƒ"
		"builtin": return "λ"
		"keyword": return "◆"
		"variable": return "χ"
		"class": return "▣"
		"object": return "●"
		_: return "○"

func _get_color(type: String) -> Color:
	match type:
		"function": return Color(0.65, 0.88, 0.18)
		"builtin": return Color(0.40, 0.85, 0.92)
		"keyword": return Color(0.79, 0.41, 0.58)
		"variable": return Color(0.61, 0.81, 1.0)
		"class": return Color(0.80, 0.73, 0.46)
		"object": return Color(1.0, 0.60, 0.40)
		_: return Color(0.8, 0.8, 0.8)
