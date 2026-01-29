extends Area2D
class_name RoadBorderArea

## Area2D that represents a road border for collision detection
## Cars will crash when their RoadBuildingCollision area overlaps with this

func _ready():
	# Set up collision layers
	collision_layer = 2  # Layer 2 = Roads/Buildings
	collision_mask = 0   # Don't detect anything (cars will detect us)

	# Add to Building group so cars recognize us as an obstacle
	add_to_group("Building")
	add_to_group("RoadBorder")
