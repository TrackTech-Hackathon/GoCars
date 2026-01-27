extends ColorRect

@export var start_visible := true
@export var start_alpha := 1.0

var _fade_tween: Tween

func _enter_tree() -> void:
	# Guarantees correct appearance BEFORE first frame (F6-safe)
	if start_visible:
		visible = true
		color.a = start_alpha

func force_visible() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	visible = true
	color.a = start_alpha

func fade_out(duration: float = 0.6) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	visible = true # ensure it can fade out
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_property(self, "color:a", 0.0, duration)

	_fade_tween.tween_callback(func():
		visible = false
		color.a = start_alpha # reset for next time
	)
