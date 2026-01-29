extends Node

## SceneLoader - Async scene loading system
## Loads scenes in background thread to prevent freezing
## Autoload singleton - accessible globally as SceneLoader

signal scene_loaded(scene: PackedScene)
signal load_progress(progress: float)
signal load_failed(path: String)

# Preload loading screen to avoid blocking when showing it
const LOADING_SCREEN = preload("res://scenes/ui/loading_screen.tscn")

var _loading_path: String = ""
var _loading: bool = false
var _loading_screen: CanvasLayer = null

## Load a scene asynchronously (in background thread)
## Shows loading screen during load
func load_scene_async(path: String) -> void:
	if _loading:
		push_warning("SceneLoader: Already loading a scene, ignoring request for %s" % path)
		return

	_loading = true
	_loading_path = path

	# Show loading screen
	_show_loading_screen()

	# Start threaded resource loading
	var status = ResourceLoader.load_threaded_request(path)
	if status != OK:
		push_error("SceneLoader: Failed to start loading %s" % path)
		_loading = false
		_hide_loading_screen()
		load_failed.emit(path)
		return

	# Start polling for completion
	set_process(true)


## Hide loading screen and show it (internal)
func _show_loading_screen() -> void:
	if _loading_screen != null:
		return  # Already showing

	# Instantiate preloaded loading screen (no blocking load!)
	_loading_screen = LOADING_SCREEN.instantiate()
	get_tree().root.add_child(_loading_screen)


func _hide_loading_screen() -> void:
	if _loading_screen != null:
		_loading_screen.queue_free()
		_loading_screen = null


## Poll for loading completion (called every frame while loading)
func _process(_delta: float) -> void:
	if not _loading:
		set_process(false)
		return

	# Check loading status
	var progress: Array = []
	var status = ResourceLoader.load_threaded_get_status(_loading_path, progress)

	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# Still loading - emit progress
		if progress.size() > 0:
			load_progress.emit(progress[0])
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		# Loading complete!
		var scene = ResourceLoader.load_threaded_get(_loading_path)
		_loading = false
		set_process(false)

		# Emit signal
		scene_loaded.emit(scene)

		# Wait one frame to ensure loading screen is visible
		await get_tree().process_frame

		# Change to the loaded scene (deferred to avoid blocking)
		get_tree().call_deferred("change_scene_to_packed", scene)

		# Hide loading screen after a short delay (let scene start loading)
		await get_tree().create_timer(0.1).timeout
		_hide_loading_screen()
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		# Loading failed
		push_error("SceneLoader: Failed to load scene: %s" % _loading_path)
		_loading = false
		set_process(false)
		_hide_loading_screen()
		load_failed.emit(_loading_path)
	else:
		# Invalid resource
		push_error("SceneLoader: Invalid resource path: %s" % _loading_path)
		_loading = false
		set_process(false)
		_hide_loading_screen()
		load_failed.emit(_loading_path)


func _ready() -> void:
	# Start with process disabled (only enable when loading)
	set_process(false)
