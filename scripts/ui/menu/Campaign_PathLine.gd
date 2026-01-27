extends Line2D

# Set this to your MapIsland Control (drag it in the Inspector)
@export var map_rect: Control

# Optional: if you already have points drawn in editor, keep them.
@export var normalized_points: PackedVector2Array = []

func _ready():
	# Always keep this line above the map image
	z_index = 100
	z_as_relative = false

	# Wait until UI layout has valid sizes
	call_deferred("_boot")

func _boot():
	if map_rect == null:
		return

	# If MapIsland hasn't been laid out yet, don't touch points.
	if map_rect.size.x <= 1.0 or map_rect.size.y <= 1.0:
		# Try again next frame
		call_deferred("_boot")
		return

	# If user didn't set normalized_points, convert CURRENT points into normalized ONCE
	if normalized_points.is_empty() and points.size() >= 2:
		var np := PackedVector2Array()
		for pt in points:
			np.append(Vector2(pt.x / map_rect.size.x, pt.y / map_rect.size.y))
		normalized_points = np

	_apply_points()

	# Re-apply when MapIsland resizes
	map_rect.resized.connect(_apply_points)

func _apply_points():
	if map_rect == null:
		return
	if map_rect.size.x <= 1.0 or map_rect.size.y <= 1.0:
		return
	if normalized_points.size() < 2:
		return  # IMPORTANT: don't wipe existing line

	var pts := PackedVector2Array()
	for np in normalized_points:
		pts.append(Vector2(np.x * map_rect.size.x, np.y * map_rect.size.y))

	points = pts
