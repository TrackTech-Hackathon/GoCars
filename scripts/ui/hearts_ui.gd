extends Node2D
class_name HeartsUI

## Hearts UI Component
## Displays animated hearts based on configurable count
## Frame 0: Full heart (has life)
## Frame 1: Slightly damaged
## Frame 2: More cracked
## Frame 3: Broken heart (no life)

signal hearts_changed(current: int, max_hearts: int)
signal hearts_depleted

# Heart configuration
@export var heart_spacing: float = 20.0

# Internal state
var max_hearts: int = 3
var current_hearts: int = 3
var heart_sprites: Array[AnimatedSprite2D] = []
var sprite_frames: SpriteFrames = null


func _ready() -> void:
	# Get the sprite frames from Heart1 if it exists
	var heart1 = get_node_or_null("Heart1")
	if heart1:
		sprite_frames = heart1.sprite_frames
		heart_sprites.append(heart1)
		print("[HeartsUI] Found Heart1, sprite frames loaded")
	else:
		print("[HeartsUI] Warning: Heart1 not found in scene")


## Initialize hearts based on max_hearts
func _initialize_heart_display() -> void:
	# Clear extra hearts (keep Heart1)
	for i in range(1, heart_sprites.size()):
		if heart_sprites[i]:
			heart_sprites[i].queue_free()

	if heart_sprites.size() > 1:
		heart_sprites.resize(1)

	# Create additional heart sprites if needed
	if sprite_frames == null:
		print("[HeartsUI] Error: No sprite frames available")
		return

	var heart1 = get_node_or_null("Heart1")
	if heart1 == null:
		print("[HeartsUI] Error: Heart1 not found")
		return

	# Create additional hearts beyond the first one
	for i in range(1, max_hearts):
		var new_heart = AnimatedSprite2D.new()
		new_heart.sprite_frames = sprite_frames
		new_heart.animation = "default"
		new_heart.frame = 0  # Start with full heart

		# Position hearts horizontally and scale down
		new_heart.position = Vector2(i * heart_spacing, 0)
		new_heart.scale = Vector2(0.006464851, 0.006464851)

		add_child(new_heart)
		heart_sprites.append(new_heart)

	print("[HeartsUI] Initialized %d hearts" % max_hearts)


## Set the maximum number of hearts and reset to full
func set_max_hearts(count: int) -> void:
	max_hearts = max(1, count)
	current_hearts = max_hearts
	_initialize_heart_display()
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

	# Play break animation on the heart that was lost
	if current_hearts >= 0 and current_hearts < heart_sprites.size():
		var heart_sprite = heart_sprites[current_hearts]
		if heart_sprite:
			print("[HeartsUI] Playing break animation for heart %d" % current_hearts)
			heart_sprite.frame = 0
			# Play the "default" animation which is the break animation
			heart_sprite.play("default")

	hearts_changed.emit(current_hearts, max_hearts)

	if current_hearts <= 0:
		hearts_depleted.emit()


## Gain one heart (if not at max)
func gain_heart() -> void:
	if current_hearts >= max_hearts:
		return

	# Reset the heart sprite to full (frame 0)
	if current_hearts < heart_sprites.size():
		var heart_sprite = heart_sprites[current_hearts]
		if heart_sprite:
			heart_sprite.frame = 0
			heart_sprite.stop()

	current_hearts += 1
	hearts_changed.emit(current_hearts, max_hearts)


## Reset all hearts to full
func reset_hearts() -> void:
	current_hearts = max_hearts

	# Reset all sprites to frame 0 (full heart)
	for heart in heart_sprites:
		if heart:
			heart.stop()
			heart.frame = 0

	hearts_changed.emit(current_hearts, max_hearts)


## Set hearts to specific value (no animation)
func set_hearts(count: int) -> void:
	current_hearts = clamp(count, 0, max_hearts)

	# Update all sprites
	for i in range(heart_sprites.size()):
		if heart_sprites[i]:
			if i < current_hearts:
				heart_sprites[i].frame = 0  # Full heart
			else:
				heart_sprites[i].frame = 3  # Broken heart

	hearts_changed.emit(current_hearts, max_hearts)

	if current_hearts <= 0:
		hearts_depleted.emit()
