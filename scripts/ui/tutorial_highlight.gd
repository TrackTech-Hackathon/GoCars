## Tutorial Highlight System for GoCars
## Creates a spotlight effect to highlight UI elements during tutorials
## Author: Claude Code
## Date: January 2026

extends CanvasLayer

## Child nodes
@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var spotlight_rect: ColorRect = $SpotlightRect
@onready var pointer_arrow: Label = $PointerArrow
@onready var hint_label: Label = $HintLabel

## Tween for animations
var tween: Tween

## Target tracking
var current_target: Control = null
var is_highlighting: bool = false

## Margin around highlighted element
const SPOTLIGHT_MARGIN: float = 10.0

## Bounce animation settings
const BOUNCE_DISTANCE: float = 15.0
const BOUNCE_DURATION: float = 0.6

func _ready() -> void:
	# Start hidden (will be shown when highlight_target is called)
	visible = false
	
	# Set dark overlay to cover entire viewport
	var viewport_size = get_viewport().get_visible_rect().size
	dark_overlay.size = viewport_size
	dark_overlay.position = Vector2.ZERO
	
	# Make sure child elements are visible
	dark_overlay.visible = true
	pointer_arrow.visible = true
	hint_label.visible = true
	spotlight_rect.visible = true
	
	# Dark overlay is already semi-transparent black in scene
	# Start with overlay and elements transparent for fade-in
	dark_overlay.modulate.a = 0.0
	pointer_arrow.modulate.a = 0.0
	hint_label.modulate.a = 0.0
	
	print("TutorialHighlight: Ready - layer=%d, viewport_size=%s" % [layer, viewport_size])

## Highlight a target UI element
func highlight_target(target_name: String, hint: String = "") -> void:
	print("TutorialHighlight: highlight_target called for: '%s'" % target_name)
	
	# Find the target node
	var target = _find_target(target_name)
	
	if not target:
		print("TutorialHighlight: Target '%s' not found - skipping highlight" % target_name)
		# Not all targets are UI elements (e.g., "car on screen" is a game object)
		# Just skip highlighting gracefully
		return
	
	current_target = target
	is_highlighting = true
	
	# Make sure everything is visible
	visible = true
	dark_overlay.visible = true
	pointer_arrow.visible = true
	spotlight_rect.visible = true
	
	print("TutorialHighlight: Highlighting '%s', visible=%s, layer=%d" % [target_name, visible, layer])
	print("TutorialHighlight: DarkOverlay - visible=%s, modulate=%s, color=%s" % [dark_overlay.visible, dark_overlay.modulate, dark_overlay.color])
	print("TutorialHighlight: PointerArrow - visible=%s, modulate=%s, position=%s" % [pointer_arrow.visible, pointer_arrow.modulate, pointer_arrow.position])
	
	# Position spotlight and pointer
	_update_spotlight_position()
	
	# Set hint text
	if hint.is_empty():
		hint_label.text = ""
		hint_label.visible = false
	else:
		hint_label.text = hint
		hint_label.visible = true
		hint_label.modulate.a = 1.0  # TEST: Force visible
		_position_hint_label()
	
	# Force everything visible immediately - NO ANIMATION
	await get_tree().process_frame  # Wait one frame for positioning
	dark_overlay.modulate.a = 1.0
	pointer_arrow.modulate.a = 1.0
	
	print("TutorialHighlight: Setup complete, dark_overlay.modulate=%s, pointer.modulate=%s" % [dark_overlay.modulate, pointer_arrow.modulate])

## Clear the highlight
func clear_highlight() -> void:
	if not is_highlighting:
		return
	
	is_highlighting = false
	current_target = null
	
	print("TutorialHighlight: Clearing highlight")
	
	# Stop animations
	if tween:
		tween.kill()
	
	# Fade out
	_animate_hide()

## Find target by name or path
func _find_target(target_name: String) -> Control:
	# Normalize target name
	target_name = target_name.to_lower().strip_edges()
	
	# Get root node (main scene)
	var root = get_tree().root
	
	# Common target mappings
	var targets = {
		"run_button": ["RunButton", "run_button"],
		"pause_button": ["PauseButton", "pause_button"],
		"reset_button": ["ResetButton", "reset_button"],
		"code_editor": ["CodeEditorWindow"],
		"code_edit": ["CodeEdit"],
		"toolbar": ["Toolbar"],
		# Search for button with 'code' AND 'editor' in toolbar - avoid matching the window
		"code_editor_button": ["Toolbar/HBoxContainer/CodeEditorButton", "BTN_CodeEditor", "code_editor_btn"],
		"readme_button": ["Toolbar/HBoxContainer/ReadmeButton", "BTN_Readme"],
		"skill_tree_button": ["Toolbar/HBoxContainer/SkillTreeButton", "BTN_SkillTree"],
		"file_explorer": ["FileExplorer", "file_explorer"],
		"speed_controls": ["SpeedButton", "speed_button"],
	}
	
	# Try to find mapped target
	if target_name in targets:
		for path in targets[target_name]:
			var target = _find_node_by_name(root, path)
			if target:
				return target
	
	# Try direct name search
	var target = _find_node_by_name(root, target_name)
	if target:
		return target
	
	return null

## Recursively find node by name
func _find_node_by_name(node: Node, target_name: String) -> Control:
	# Normalize names for comparison
	var normalized_target = target_name.to_lower().replace(" ", "").replace("_", "")
	var normalized_node_name = node.name.to_lower().replace(" ", "").replace("_", "")
	
	# Check if this node matches
	# For exact match or if node name contains the target (but not vice versa to avoid partial matches)
	if node is Control:
		# Exact match has priority
		if normalized_node_name == normalized_target:
			print("TutorialHighlight: Found target node: %s (searched for: %s)" % [node.name, target_name])
			return node as Control
		# Only match if target is contained in node name (not the other way around)
		# This prevents "CodeEditor" window from matching "CodeEditorButton"
		elif normalized_target in normalized_node_name and len(normalized_node_name) <= len(normalized_target) + 6:
			print("TutorialHighlight: Found target node: %s (searched for: %s)" % [node.name, target_name])
			return node as Control
	
	# Check children
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	
	return null

## Update spotlight position based on target
func _update_spotlight_position() -> void:
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Get target's global rect
	var target_rect = current_target.get_global_rect()
	
	# Expand rect with margin
	var spotlight_pos = target_rect.position - Vector2(SPOTLIGHT_MARGIN, SPOTLIGHT_MARGIN)
	var spotlight_size = target_rect.size + Vector2(SPOTLIGHT_MARGIN * 2, SPOTLIGHT_MARGIN * 2)
	
	# Position spotlight rect
	spotlight_rect.position = spotlight_pos
	spotlight_rect.size = spotlight_size
	
	# Get arrow size for proper centering
	var arrow_size = Vector2(40, 40)  # PointerArrow's actual size
	
	# Position pointer arrow intelligently (above or below based on space)
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Center the arrow horizontally on the target
	var arrow_center_x = target_rect.position.x + (target_rect.size.x / 2.0) - (arrow_size.x / 2.0)
	
	# Check if there's room above the target (need at least 70 pixels)
	var arrow_y: float
	if target_rect.position.y > 70:
		# Position above target
		arrow_y = target_rect.position.y - arrow_size.y - 20
		pointer_arrow.text = "▼"  # Point down
	else:
		# Not enough room above, position below target
		arrow_y = target_rect.position.y + target_rect.size.y + 10
		pointer_arrow.text = "▲"  # Point up
	
	var arrow_pos = Vector2(arrow_center_x, arrow_y)
	
	# Clamp arrow position to stay on screen
	arrow_pos.x = clamp(arrow_pos.x, 10, viewport_size.x - arrow_size.x - 10)
	arrow_pos.y = clamp(arrow_pos.y, 10, viewport_size.y - arrow_size.y - 10)
	
	pointer_arrow.position = arrow_pos

## Position hint label near target
func _position_hint_label() -> void:
	if not current_target or not is_instance_valid(current_target):
		return
	
	var target_rect = current_target.get_global_rect()
	
	# Position hint below pointer arrow
	var hint_pos = Vector2(
		target_rect.position.x + target_rect.size.x / 2 - hint_label.size.x / 2,
		target_rect.position.y - pointer_arrow.size.y - hint_label.size.y - 20
	)
	
	# Keep within screen bounds
	var screen_size = get_viewport().get_visible_rect().size
	hint_pos.x = clamp(hint_pos.x, 10, screen_size.x - hint_label.size.x - 10)
	hint_pos.y = clamp(hint_pos.y, 10, screen_size.y - hint_label.size.y - 10)
	
	hint_label.position = hint_pos

## Animate show
func _animate_show() -> void:
	print("TutorialHighlight: _animate_show called")
	
	if tween:
		tween.kill()
	
	# Set initial states - use modulate for fade effect
	dark_overlay.modulate.a = 0.0
	pointer_arrow.modulate.a = 0.0
	hint_label.modulate.a = 0.0
	
	# Create tween
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade in dark overlay using modulate
	tween.tween_property(dark_overlay, "modulate:a", 1.0, 0.3)
	
	# Fade in pointer and hint
	tween.tween_property(pointer_arrow, "modulate:a", 1.0, 0.4)
	if hint_label.visible:
		tween.tween_property(hint_label, "modulate:a", 1.0, 0.4)
	
	print("TutorialHighlight: Tween started, dark_overlay visible=%s, pointer visible=%s" % [dark_overlay.visible, pointer_arrow.visible])

func _animate_hide() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade out using modulate
	tween.tween_property(dark_overlay, "modulate:a", 0.0, 0.2)
	tween.tween_property(pointer_arrow, "modulate:a", 0.0, 0.2)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.2)
	
	# Hide when done
	tween.finished.connect(func(): visible = false)

## Start bounce animation for pointer arrow
func _start_bounce_animation() -> void:
	if not is_highlighting:
		return
	
	# Store original position
	var original_y = pointer_arrow.position.y
	
	# Create bounce tween
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Bounce down and up
	tween.tween_property(pointer_arrow, "position:y", original_y + BOUNCE_DISTANCE, BOUNCE_DURATION / 2)
	tween.tween_property(pointer_arrow, "position:y", original_y, BOUNCE_DURATION / 2)

## Process to update position if target moves (runs every frame)
func _process(_delta: float) -> void:
	if is_highlighting and current_target and is_instance_valid(current_target):
		# Update position every frame to track moving windows
		_update_spotlight_position()
		if hint_label.visible:
			_position_hint_label()
		
		# Keep overlay and pointer visible while tracking
		if dark_overlay.modulate.a < 1.0:
			dark_overlay.modulate.a = 1.0
		if pointer_arrow.modulate.a < 1.0:
			pointer_arrow.modulate.a = 1.0
		
		# Debug: Print position periodically to verify tracking
		var frame_count = Engine.get_process_frames()
		if frame_count % 60 == 0:  # Every 60 frames (~1 second)
			var target_rect = current_target.get_global_rect()
			print("TutorialHighlight: Tracking %s at global pos (%.1f, %.1f), arrow at (%.1f, %.1f)" % [
				current_target.name, target_rect.position.x, target_rect.position.y,
				pointer_arrow.position.x, pointer_arrow.position.y
			])
