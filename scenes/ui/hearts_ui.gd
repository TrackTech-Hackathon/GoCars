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
@export var heart_texture_path: String = "res://assets/ui/heart.png"
@export var heart_width: int = 32  # Width of each heart frame
@export var heart_height: int = 32  # Height of each heart frame
@export var heart_spacing: int = 4  # Space between hearts
@export var animation_speed: float = 0.15  # Time per animation frame

# Internal state
var max_hearts: int = 3
var current_hearts: int = 3
var heart_sprites: Array[Sprite2D] = []
var heart_container: HBoxContainer = null
var heart_texture: Texture2D = null

# Animation state
var animating_heart_index: int = -1
var animation_frame: int = 0
var animation_timer: float = 0.0
var animation_queue: Array[int] = []  # Queue of heart indices to animate


func _ready() -> void:
	# Heart count is now set by main_tilemap.gd via set_max_hearts()
	# No longer reads from HeartCount Label

	# Load heart texture
	if ResourceLoader.exists(heart_texture_path):
		heart_texture = load(heart_texture_path)

	# Create container for heart sprites
	heart_container = HBoxContainer.new()
	heart_container.add_theme_constant_override("separation", heart_spacing)
	add_child(heart_container)

	# Create heart sprites
	_create_heart_sprites()


func _process(delta: float) -> void:
	# Handle heart break animation
	if animating_heart_index >= 0:
		animation_timer += delta
		if animation_timer >= animation_speed:
			animation_timer = 0.0
			animation_frame += 1

			if animation_frame > 3:
				# Animation complete
				animating_heart_index = -1
				animation_frame = 0

				# Process next in queue if any
				if not animation_queue.is_empty():
					var next_index = animation_queue.pop_front()
					_start_break_animation(next_index)
			else:
				# Update sprite frame
				_update_heart_frame(animating_heart_index, animation_frame)


func _create_heart_sprites() -> void:
	# Clear existing sprites
	for sprite in heart_sprites:
		sprite.queue_free()
	heart_sprites.clear()

	# Create new sprites
	for i in range(max_hearts):
		var sprite = Sprite2D.new()

		if heart_texture:
			sprite.texture = heart_texture
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, heart_width, heart_height)  # Full heart
			sprite.centered = false
		else:
			# Fallback: create a colored rectangle placeholder
			var placeholder = ColorRect.new()
			placeholder.color = Color.RED
			placeholder.custom_minimum_size = Vector2(heart_width, heart_height)
			heart_container.add_child(placeholder)
			continue

		heart_container.add_child(sprite)
		heart_sprites.append(sprite)


func _update_heart_frame(heart_index: int, frame: int) -> void:
	if heart_index < 0 or heart_index >= heart_sprites.size():
		return

	var sprite = heart_sprites[heart_index]
	if sprite and heart_texture:
		# Frame 0 = full, 1 = transition1, 2 = transition2, 3 = broken
		sprite.region_rect = Rect2(frame * heart_width, 0, heart_width, heart_height)


func _start_break_animation(heart_index: int) -> void:
	if heart_index < 0 or heart_index >= heart_sprites.size():
		return

	animating_heart_index = heart_index
	animation_frame = 1  # Start from first transition frame
	animation_timer = 0.0
	_update_heart_frame(heart_index, animation_frame)


## Set the maximum number of hearts and reset to full
func set_max_hearts(count: int) -> void:
	max_hearts = max(1, count)
	current_hearts = max_hearts
	_create_heart_sprites()
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

	if animating_heart_index >= 0:
		# Already animating, queue this one
		animation_queue.append(heart_to_break)
	else:
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
	animating_heart_index = -1

	# Reset all sprites to full heart
	for i in range(heart_sprites.size()):
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
