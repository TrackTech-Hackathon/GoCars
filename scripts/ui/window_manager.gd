## Window Manager for GoCars
## Manages floating windows and coordinates with main game
## Author: Claude Code
## Date: January 2026

extends Node
class_name WindowManager

## Signals
signal code_execution_requested(code: String)
signal pause_requested()
signal reset_requested()
signal speed_changed(speed: float)

## Window references
var toolbar: Variant = null
var code_editor_window: Variant = null
var readme_window: Variant = null
var skill_tree_window: Variant = null
var file_explorer: Variant = null

## Virtual filesystem
var virtual_fs: Variant = null

## Module loader
var module_loader: Variant = null

## UI Container
var ui_container: CanvasLayer

## Persistence settings
var settings_path: String = "user://window_settings.json"

## Scene paths for windows (use scenes when available)
const CODE_EDITOR_SCENE = "res://scenes/ui/code_editor/code_editor_window.tscn"
const TERMINAL_SCENE = "res://scenes/ui/code_editor/terminal_panel.tscn"
const FILE_EXPLORER_SCENE = "res://scenes/ui/code_editor/file_explorer.tscn"

func _init() -> void:
	# Initialize virtual filesystem
	var VirtualFileSystemClass = load("res://scripts/core/virtual_filesystem.gd")
	virtual_fs = VirtualFileSystemClass.new()

	# Initialize module loader
	var ModuleLoaderClass = load("res://scripts/core/module_loader.gd")
	module_loader = ModuleLoaderClass.new()
	module_loader.call("set_filesystem", virtual_fs)

func setup(parent_canvas_layer: CanvasLayer) -> void:
	ui_container = parent_canvas_layer

	# Load window classes/scenes
	var ToolbarScene = load("res://scenes/ui/toolbar.tscn")
	var ReadmeWindowClass = load("res://scenes/ui/readme_window.tscn")
	var SkillTreeWindowClass = load("res://scripts/ui/skill_tree_window.gd")

	# Create toolbar
	toolbar = ToolbarScene.instantiate()
	toolbar.name = "Toolbar"
	ui_container.add_child(toolbar)

	# Create code editor window - prefer scene if available
	if ResourceLoader.exists(CODE_EDITOR_SCENE):
		var CodeEditorScene = load(CODE_EDITOR_SCENE)
		code_editor_window = CodeEditorScene.instantiate()
		print("WindowManager: Loaded CodeEditorWindow from scene")
	else:
		# Fallback to dynamic creation
		var CodeEditorWindowClass = load("res://scripts/ui/code_editor_window.gd")
		code_editor_window = CodeEditorWindowClass.new()
		print("WindowManager: Created CodeEditorWindow dynamically")
	
	code_editor_window.name = "CodeEditorWindow"
	code_editor_window.visible = false
	ui_container.add_child(code_editor_window)
	code_editor_window.set_virtual_filesystem(virtual_fs)

	readme_window = ReadmeWindowClass.instantiate()
	readme_window.name = "ReadmeWindow"
	readme_window.visible = false
	ui_container.add_child(readme_window)

	skill_tree_window = SkillTreeWindowClass.new()
	skill_tree_window.name = "SkillTreeWindow"
	skill_tree_window.visible = false
	ui_container.add_child(skill_tree_window)

	# Connect toolbar signals
	toolbar.code_editor_requested.connect(_on_code_editor_requested)
	toolbar.readme_requested.connect(_on_readme_requested)
	toolbar.skill_tree_requested.connect(_on_skill_tree_requested)

	# Connect code editor signals
	code_editor_window.code_run_requested.connect(_on_code_run_requested)
	code_editor_window.code_pause_requested.connect(_on_pause_requested)
	code_editor_window.code_reset_requested.connect(_on_reset_requested)
	code_editor_window.speed_changed.connect(_on_speed_changed)
	code_editor_window.window_closed.connect(func():
		code_editor_window.visible = false
		save_window_state()
	)
	readme_window.window_closed.connect(func():
		readme_window.visible = false
		save_window_state()
	)
	skill_tree_window.window_closed.connect(func():
		skill_tree_window.visible = false
		save_window_state()
	)

	# Connect window movement/resize signals to auto-save
	code_editor_window.window_focused.connect(save_window_state)
	readme_window.window_focused.connect(save_window_state)
	skill_tree_window.window_focused.connect(save_window_state)

	# Load saved window positions/sizes
	_load_window_state()

	print("WindowManager: Setup complete")
	print("  Ctrl+1: Toggle Code Editor")
	print("  Ctrl+2: Toggle README")
	print("  Ctrl+3: Toggle Skill Tree")

func _input(event: InputEvent) -> void:
	# Handle keyboard shortcuts
	if event is InputEventKey and event.pressed and not event.echo:
		# Ctrl+1: Toggle Code Editor
		if event.keycode == KEY_1 and event.ctrl_pressed:
			_on_code_editor_requested()
			get_viewport().set_input_as_handled()

		# Ctrl+2: Toggle README
		elif event.keycode == KEY_2 and event.ctrl_pressed:
			_on_readme_requested()
			get_viewport().set_input_as_handled()

		# Ctrl+3: Toggle Skill Tree
		elif event.keycode == KEY_3 and event.ctrl_pressed:
			_on_skill_tree_requested()
			get_viewport().set_input_as_handled()

func _on_code_editor_requested() -> void:
	if code_editor_window.visible:
		code_editor_window.visible = false
	else:
		code_editor_window.open()

func _on_readme_requested() -> void:
	if readme_window.visible:
		readme_window.visible = false
	else:
		readme_window.open()

func _on_skill_tree_requested() -> void:
	if skill_tree_window.visible:
		skill_tree_window.visible = false
	else:
		skill_tree_window.open()

func _on_code_run_requested(code: String) -> void:
	code_execution_requested.emit(code)

func _on_pause_requested() -> void:
	pause_requested.emit()

func _on_reset_requested() -> void:
	reset_requested.emit()

func _on_speed_changed(speed: float) -> void:
	speed_changed.emit(speed)

## Get current code from editor
func get_current_code() -> String:
	if code_editor_window and code_editor_window.visible:
		return code_editor_window.get_code()
	return ""

## Set code in editor
func set_code(code: String) -> void:
	if code_editor_window:
		code_editor_window.set_code(code)

## Get virtual filesystem
func get_virtual_filesystem() -> Variant:
	return virtual_fs

## Get module loader
func get_module_loader() -> Variant:
	return module_loader

## Save window positions and sizes
func save_window_state() -> void:
	var settings = {
		"code_editor": {
			"position": [code_editor_window.global_position.x, code_editor_window.global_position.y],
			"size": [code_editor_window.size.x, code_editor_window.size.y]
		},
		"readme": {
			"position": [readme_window.global_position.x, readme_window.global_position.y],
			"size": [readme_window.size.x, readme_window.size.y]
		},
		"skill_tree": {
			"position": [skill_tree_window.global_position.x, skill_tree_window.global_position.y],
			"size": [skill_tree_window.size.x, skill_tree_window.size.y]
		}
	}

	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()
		print("Window state saved to %s" % settings_path)

## Load window positions and sizes
func _load_window_state() -> void:
	if not FileAccess.file_exists(settings_path):
		print("No saved window state found, using defaults")
		return

	var file = FileAccess.open(settings_path, FileAccess.READ)
	if not file:
		print("Failed to load window state")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Failed to parse window state JSON")
		return

	var settings = json.data

	# Restore code editor window
	if settings.has("code_editor"):
		var ce = settings["code_editor"]
		if ce.has("position"):
			var saved_pos = Vector2(ce["position"][0], ce["position"][1])
			# Recenter if position is at origin or off-screen (bad saved state)
			var viewport_size = code_editor_window.get_viewport_rect().size
			if saved_pos == Vector2.ZERO or saved_pos.x < 0 or saved_pos.y < 0 or saved_pos.x > viewport_size.x or saved_pos.y > viewport_size.y:
				# Recenter the window
				code_editor_window.global_position = (viewport_size - code_editor_window.default_size) / 2
			else:
				code_editor_window.global_position = saved_pos
		if ce.has("size"):
			code_editor_window.size = Vector2(ce["size"][0], ce["size"][1])

	# Restore README window
	if settings.has("readme"):
		var rm = settings["readme"]
		if rm.has("position"):
			var saved_pos = Vector2(rm["position"][0], rm["position"][1])
			# Recenter if position is at origin or off-screen (bad saved state)
			var viewport_size = readme_window.get_viewport_rect().size
			if saved_pos == Vector2.ZERO or saved_pos.x < 0 or saved_pos.y < 0 or saved_pos.x > viewport_size.x or saved_pos.y > viewport_size.y:
				# Recenter the window
				readme_window.global_position = (viewport_size - readme_window.default_size) / 2
			else:
				readme_window.global_position = saved_pos
		if rm.has("size"):
			readme_window.size = Vector2(rm["size"][0], rm["size"][1])

	# Restore skill tree window
	if settings.has("skill_tree"):
		var st = settings["skill_tree"]
		if st.has("position"):
			var saved_pos = Vector2(st["position"][0], st["position"][1])
			# Recenter if position is at origin or off-screen (bad saved state)
			var viewport_size = skill_tree_window.get_viewport_rect().size
			if saved_pos == Vector2.ZERO or saved_pos.x < 0 or saved_pos.y < 0 or saved_pos.x > viewport_size.x or saved_pos.y > viewport_size.y:
				# Recenter the window
				skill_tree_window.global_position = (viewport_size - skill_tree_window.default_size) / 2
			else:
				skill_tree_window.global_position = saved_pos
		if st.has("size"):
			skill_tree_window.size = Vector2(st["size"][0], st["size"][1])

	print("Window state loaded from %s" % settings_path)

## Called when windows are closed or moved - save state
func _on_window_changed() -> void:
	save_window_state()

## Reset all window positions to defaults
func reset_all_window_positions() -> void:
	var viewport_size = ui_container.get_viewport().get_visible_rect().size
	
	# Reset code editor window
	if code_editor_window and is_instance_valid(code_editor_window):
		code_editor_window.position = Vector2(50, 50)
		if code_editor_window.has_method("reset_size"):
			code_editor_window.reset_size()
	
	# Reset file explorer
	if file_explorer and is_instance_valid(file_explorer):
		file_explorer.position = Vector2(50, 200)
	
	# Reset readme window
	if readme_window and is_instance_valid(readme_window):
		var default_pos = (viewport_size - readme_window.default_size) / 2
		readme_window.global_position = default_pos
	
	# Reset skill tree window
	if skill_tree_window and is_instance_valid(skill_tree_window):
		var default_pos = (viewport_size - skill_tree_window.default_size) / 2
		skill_tree_window.global_position = default_pos
	
	# Save the reset state
	save_window_state()
	print("All window positions reset to defaults")
