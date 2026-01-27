extends Control

@export var design_resolution: Vector2 = Vector2(1920, 1080)
@export var uniform_scale: bool = true   # keep aspect ratio
@export var extra_zoom: float = 1.0      # tweak if it feels small (1.1–1.25)

func _ready() -> void:
	await get_tree().process_frame
	_apply_scale()
	get_viewport().size_changed.connect(_apply_scale)

func _apply_scale() -> void:
	var vp_size: Vector2 = get_viewport_rect().size

	var sx: float = vp_size.x / design_resolution.x
	var sy: float = vp_size.y / design_resolution.y

	if uniform_scale:
		var s: float = min(sx, sy) * extra_zoom
		scale = Vector2(s, s)
	else:
		scale = Vector2(sx, sy) * extra_zoom
