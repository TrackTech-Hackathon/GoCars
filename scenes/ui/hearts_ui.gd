extends Control
class_name HeartsUI

## Hearts UI Component
## Displays animated hearts based on configurable count
## Set the heart_count via the exported Label text in the scene
##
## Heart sprite layout (4 columns, 1 row):
## Column 0: Full heart
## Column 1: Transition frame 1
## Column 2: Transition frame 2
## Column 3: Broken heart

signal hearts_changed(current: int, max_hearts: int)
signal hearts_depleted

# Heart configuration
@export var heart_texture_path: String = "res://assets/UI/Heart.png"
@export var heart_width: int = 32  # Width of each heart frame
@export var heart_height: int = 32  # Height of each heart frame
@export var heart_spacing: int = 4  # Space between hearts
@export var animation_speed: float = 0.15  # Time per animation frame

# Internal state
var max_hearts: int = 3
var current_hearts: int = 1
var heart_sprites: Array = []  # Array of heart nodes (AnimatedSprite2D)
var heart_container: HBoxContainer = null
var heart_texture: Texture2D = null

# Animation state
var animating_heart_index: int = -1
var animation_frame: int = 0
var animation_timer: float = 0.0
var animation_queue: Array[int] = []  # Queue of heart indices to animate


func _ready() -> void:
	# Load heart texture
	if ResourceLoader.exists(heart_texture_path):
		heart_texture = load(heart_texture_path)

	# Find existing container and sprites from scene
	heart_container = get_node_or_null("HeartContainer")
	if heart_container == null:
		# Fallback: create container if not found
		heart_container = HBoxContainer.new()
		heart_container.add_theme_constant_override("separation", heart_spacing)
		add_child(heart_container)

	# Find pre-created heart sprites
	_find_heart_sprites()

	# Heart count is set by main_tilemap.gd via set_max_hearts()
	# Do NOT read HeartCount label here - let main_tilemap.gd handle it


func _process(delta: float) -> void:
	# AnimatedSprite2D handles animation automatically
	# No manual frame updating needed
	pass


## Find pre-created heart sprites from the scene
func _find_heart_sprites() -> void:
	heart_sprites.clear()

	# Look for Heart1, Heart2, Heart3, etc. in the container
	var i = 1
	while true:
		var node = heart_container.get_node_or_null("Heart%d" % i)
		if node == null:
			break

		# Add the node to our sprites list
		heart_sprites.append(node)
		print("[HeartsUI] Found heart sprite: Heart%d" % i)

		# Try to set to frame 0 (full heart)
		if node.has_method("set_frame") or "frame" in node:
			node.frame = 0

		i += 1

	print("[HeartsUI] Total heart sprites found: %d" % heart_sprites.size())

	# Hide all hearts beyond max_hearts
	for j in range(heart_sprites.size()):
		if j >= max_hearts:
			heart_sprites[j].visible = false
			print("[HeartsUI] Hiding heart %d (beyond max %d)" % [j, max_hearts])
		else:
			heart_sprites[j].visible = true
			print("[HeartsUI] Showing heart %d" % j)


func _create_heart_sprites() -> void:
	# For dynamic creation (fallback if sprites not in scene)
	var missing_count = max_hearts - heart_sprites.size()
	if missing_count <= 0:
		return

	# Note: Dynamic creation of AnimatedSprite2D with SpriteFrames is complex
	# Usually pre-created in scene. This is a simplified fallback.
	for i in range(missing_count):
		var placeholder = ColorRect.new()
		placeholder.color = Color.RED
		placeholder.custom_minimum_size = Vector2(heart_width, heart_height)
		heart_container.add_child(placeholder)
		heart_sprites.append(placeholder)


func _update_heart_frame(heart_index: int, frame: int) -> void:
	if heart_index < 0 or heart_index >= heart_sprites.size():
		return

	var sprite = heart_sprites[heart_index]
	if sprite:
		# Set the frame directly (0-3)
		if "frame" in sprite:
			sprite.frame = frame


func _start_break_animation(heart_index: int) -> void:
	if heart_index < 0 or heart_index >= heart_sprites.size():
		print("[HeartsUI] ERROR: Invalid heart index %d (valid range: 0-%d)" % [heart_index, heart_sprites.size() - 1])
		return

	var sprite = heart_sprites[heart_index]
	if sprite:
		print("[HeartsUI] Found sprite for heart %d: %s" % [heart_index, sprite.name])
		if sprite.has_method("play"):
			# Play the break animation (goes from frame 0->1->2->3)
			print("[HeartsUI] Playing break animation on heart %d" % heart_index)
			sprite.play("break")

			# Connect to animation_finished if not already connected
			if sprite.has_signal("animation_finished"):
				if not sprite.animation_finished.is_connected(_on_heart_animation_finished):
					sprite.animation_finished.connect(_on_heart_animation_finished)
					print("[HeartsUI] Connected animation_finished signal")
		else:
			print("[HeartsUI] ERROR: Sprite doesn't have play() method")
	else:
		print("[HeartsUI] ERROR: No sprite found at index %d" % heart_index)


## Called when any heart's break animation finishes
func _on_heart_animation_finished() -> void:
	# Animation finished, check queue for next
	if not animation_queue.is_empty():
		var next_index = animation_queue.pop_front()
		_start_break_animation(next_index)


## Set the maximum number of hearts and reset to full
func set_max_hearts(count: int) -> void:
	max_hearts = max(1, count)
	current_hearts = max_hearts
	# Use pre-created sprites if available, fallback to dynamic creation
	if heart_sprites.is_empty():
		_find_heart_sprites()
	# Create additional sprites dynamically if needed
	if heart_sprites.size() < max_hearts:
		_create_heart_sprites()
	# Reset all to full hearts
	reset_hearts()
	hearts_changed.emit(current_hearts, max_hearts)


## Get current heart count
func get_hearts() -> int:
	return current_hearts


## Get maximum heart count
func get_max_hearts() -> int:
	return max_hearts


## Lose one heart with animation
func lose_heart() -> void:
	if current_hearts <= 0:
		return

	current_hearts -= 1

	# Animate the rightmost full heart (current_hearts is now the index of the heart to break)
	var heart_to_break = current_hearts
	print("[HeartsUI] Losing heart! Heart index: %d, Total hearts left: %d, Max hearts: %d" % [heart_to_break, current_hearts, max_hearts])

	# Check if any animation is playing
	var any_animating = false
	for sprite in heart_sprites:
		if sprite.has_method("is_playing") and sprite.is_playing():
			any_animating = true
			break

	if any_animating:
		# Queue this animation to play after current one finishes
		print("[HeartsUI] Animation queued for heart %d" % heart_to_break)
		animation_queue.append(heart_to_break)
	else:
		# No animation playing, start immediately
		print("[HeartsUI] Starting animation for heart %d" % heart_to_break)
		_start_break_animation(heart_to_break)

	hearts_changed.emit(current_hearts, max_hearts)

	if current_hearts <= 0:
		hearts_depleted.emit()


## Gain one heart (if not at max)
func gain_heart() -> void:
	if current_hearts >= max_hearts:
		return

	# Restore the heart sprite to full
	_update_heart_frame(current_hearts, 0)
	current_hearts += 1
	hearts_changed.emit(current_hearts, max_hearts)


## Reset all hearts to full
func reset_hearts() -> void:
	current_hearts = max_hearts
	animation_queue.clear()

	# Stop all animations and reset all sprites to full heart (frame 0)
	for i in range(heart_sprites.size()):
		var sprite = heart_sprites[i]
		if sprite.has_method("stop"):
			sprite.stop()
		_update_heart_frame(i, 0)

	hearts_changed.emit(current_hearts, max_hearts)


## Set hearts to specific value (no animation)
func set_hearts(count: int) -> void:
	current_hearts = clamp(count, 0, max_hearts)

	# Update all sprites
	for i in range(heart_sprites.size()):
		if i < current_hearts:
			_update_heart_frame(i, 0)  # Full heart
		else:
			_update_heart_frame(i, 3)  # Broken heart

	hearts_changed.emit(current_hearts, max_hearts)

	if current_hearts <= 0:
		hearts_depleted.emit()
