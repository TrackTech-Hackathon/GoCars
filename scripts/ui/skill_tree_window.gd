## Skill Tree Window Placeholder for GoCars
## Shows "Coming Soon" message for future skill tree feature
## Author: Claude Code
## Date: January 2026

extends FloatingWindow
class_name SkillTreeWindow

## Child nodes
var vbox: VBoxContainer
var content_title_label: Label
var message_label: Label

func _init() -> void:
	window_title = "Skill Tree"
	min_size = Vector2(400, 300)
	default_size = Vector2(500, 350)
	default_position = Vector2(400, 150)

func _ready() -> void:
	super._ready()
	_setup_placeholder()

func _setup_placeholder() -> void:
	var content = get_content_container()

	# VBox for centered content
	vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(vbox)

	# Spacer
	var spacer_top = Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer_top)

	# Content title label
	content_title_label = Label.new()
	content_title_label.name = "ContentTitleLabel"
	content_title_label.text = "🌳 Skill Tree"
	content_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_title_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(content_title_label)

	# Spacing
	var spacing = Control.new()
	spacing.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacing)

	# Message label
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.text = "Coming Soon!\n\nThe skill tree feature will unlock\nnew abilities and commands as you\ncomplete levels.\n\nStay tuned for future updates!"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(message_label)

	# Spacer
	var spacer_bottom = Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer_bottom)
