extends CanvasLayer

## Loading screen UI
## Shows while scenes are loading asynchronously

@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel

var _dot_count: int = 0
var _animation_timer: float = 0.0
const ANIMATION_INTERVAL: float = 0.3

func _ready() -> void:
	# Connect to SceneLoader signals if available
	if has_node("/root/SceneLoader"):
		var scene_loader = get_node("/root/SceneLoader")
		if scene_loader.has_signal("load_progress"):
			scene_loader.load_progress.connect(_on_load_progress)


func _process(delta: float) -> void:
	# Animate loading dots
	_animation_timer += delta
	if _animation_timer >= ANIMATION_INTERVAL:
		_animation_timer = 0.0
		_dot_count = (_dot_count + 1) % 4
		var dots = ".".repeat(_dot_count)
		loading_label.text = "Loading" + dots


func _on_load_progress(progress: float) -> void:
	if progress_bar:
		progress_bar.value = progress
