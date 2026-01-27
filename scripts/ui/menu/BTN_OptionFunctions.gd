extends TextureButton

# ─────────────────────────────────────────
# ✦ VISIBILITY ASSIGNMENTS (Inspector)
# ─────────────────────────────────────────

@export var show_node: CanvasItem        # This will be made visible

@export var hide_node_1: CanvasItem      # These will be hidden
@export var hide_node_2: CanvasItem
@export var hide_node_3: CanvasItem


func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	# Show assigned node
	if show_node:
		show_node.visible = true

	# Hide assigned nodes
	if hide_node_1:
		hide_node_1.visible = false

	if hide_node_2:
		hide_node_2.visible = false

	if hide_node_3:
		hide_node_3.visible = false
