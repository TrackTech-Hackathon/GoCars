extends Control
# Attach to BG (parent of BG_1 and BG_2)
# ✅ Removed horizontal scrolling/moving
# ✅ Parallax now works on BOTH X and Y (all sides)

# Mouse parallax (X + Y)
@export var parallax_pixels: Vector2 = Vector2(12.0, 10.0) # max offset (x, y)
@export var parallax_lerp: float = 10.0                    # higher = snappier
@export var parallax_deadzone: float = 0.02                # ignore tiny jitter (0..1)

# Optional subtle "life" motion (set to 0 to disable)
@export var breathe_scale: float = 0.006
@export var breathe_speed: float = 0.22

@export var tilt_degrees: float = 0.25
@export var tilt_speed: float = 0.18

var _t: float = 0.0

# store "rest" transform of the parent BG
var _base_pos: Vector2
var _base_scale: Vector2
var _base_rot: float

func _ready() -> void:
	await get_tree().process_frame

	_base_pos = position
	_base_scale = scale
	_base_rot = rotation

	await get_tree().process_frame
	pivot_offset = size * 0.5

func _process(delta: float) -> void:
	_t += delta

	var vp: Viewport = get_viewport()
	var m: Vector2 = vp.get_mouse_position()
	var vsize: Vector2 = vp.get_visible_rect().size

	var denom_x: float = maxf(1.0, vsize.x)
	var denom_y: float = maxf(1.0, vsize.y)

	# normalized (-1..1), center = 0
	var nx: float = (m.x / denom_x) * 2.0 - 1.0
	var ny: float = (m.y / denom_y) * 2.0 - 1.0

	# deadzone to avoid micro jitter
	if absf(nx) < parallax_deadzone:
		nx = 0.0
	if absf(ny) < parallax_deadzone:
		ny = 0.0

	# target offset (move opposite for depth)
	var target_pos: Vector2 = _base_pos + Vector2(
		-nx * parallax_pixels.x,
		-ny * parallax_pixels.y
	)

	# Optional subtle breathe/tilt
	var sc: float = 1.0 + sin(_t * TAU * breathe_speed) * breathe_scale
	var rot: float = deg_to_rad(sin(_t * TAU * tilt_speed) * tilt_degrees)

	var a: float = clampf(delta * parallax_lerp, 0.0, 1.0)
	position = position.lerp(target_pos, a)
	scale = _base_scale * sc
	rotation = _base_rot + rot
