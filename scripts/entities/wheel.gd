extends Sprite2D
class_name Wheel

## A wheel sprite that rotates based on vehicle movement
## Wheels spin visually based on the vehicle's velocity

# Wheel configuration
@export var wheel_radius: float = 8.0  # Radius in pixels (for rotation calculation)
@export var is_front_wheel: bool = false  # Front wheels can steer (for future use)

# Parent vehicle reference (set by Vehicle._ready())
var vehicle: Vehicle = null

# Visual spin rotation (accumulated over time)
var spin_angle: float = 0.0


func _process(delta: float) -> void:
	if vehicle == null:
		return

	# Only spin if vehicle is moving
	if not vehicle.is_moving():
		return

	# Calculate wheel spin based on vehicle velocity
	var velocity_magnitude = vehicle.velocity.length()

	# Circumference = 2 * PI * radius
	# Angular velocity = linear velocity / radius
	var angular_velocity = velocity_magnitude / wheel_radius

	# Determine spin direction based on vehicle's forward movement
	var velocity_dot = vehicle.velocity.dot(vehicle.direction)
	if velocity_dot < 0:
		angular_velocity = -angular_velocity

	# Accumulate spin angle
	spin_angle += angular_velocity * delta

	# Keep angle in reasonable range
	if spin_angle > TAU:
		spin_angle -= TAU
	elif spin_angle < -TAU:
		spin_angle += TAU

	# Apply visual rotation
	# For a 2D top-down view, we scale the wheel sprite to simulate rotation
	# When wheel rotates, it appears to squish vertically
	var squish_factor = cos(spin_angle)
	scale.y = abs(squish_factor) * 0.3 + 0.7  # Scale between 0.7 and 1.0
