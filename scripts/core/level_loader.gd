extends Node
class_name LevelLoader

## Automatically loads level scenes from the levelmaps folder
## Levels are detected by scanning for .tscn files in scenes/levelmaps/
## Now supports subfolders (01Tutorial, 02Iloilo, etc.)
## Level order is determined by full path (alphabetical/numerical)

const LEVELS_PATH: String = "res://scenes/levelmaps/"

# Cached list of level paths
var _level_paths: Array[String] = []
var _levels_loaded: bool = false


## Get all available level paths (scans folder if not cached)
func get_level_paths() -> Array[String]:
	if not _levels_loaded:
		_scan_levels_folder()
	return _level_paths


## Get the number of available levels
func get_level_count() -> int:
	if not _levels_loaded:
		_scan_levels_folder()
	return _level_paths.size()


## Get level path by index (0-based)
func get_level_path(index: int) -> String:
	if not _levels_loaded:
		_scan_levels_folder()
	if index >= 0 and index < _level_paths.size():
		return _level_paths[index]
	return ""


## Get level filename from path (filename without extension)
func get_level_filename(index: int) -> String:
	var path = get_level_path(index)
	if path.is_empty():
		return ""
	return path.get_file().get_basename()


## Get level display name from the LevelName label in the scene
## Falls back to filename if LevelName label doesn't exist
func get_level_display_name(index: int) -> String:
	var path = get_level_path(index)
	if path.is_empty():
		return ""

	# Load the scene to check for LevelName label
	var scene = load(path)
	if scene == null:
		return path.get_file().get_basename()

	var instance = scene.instantiate()
	var display_name = _extract_level_name(instance)
	instance.queue_free()

	if display_name.is_empty():
		return path.get_file().get_basename()
	return display_name


## Get level display name by path
func get_level_display_name_by_path(path: String) -> String:
	var scene = load(path)
	if scene == null:
		return path.get_file().get_basename()

	var instance = scene.instantiate()
	var display_name = _extract_level_name(instance)
	instance.queue_free()

	if display_name.is_empty():
		return path.get_file().get_basename()
	return display_name


## Extract level name from a level instance
func _extract_level_name(level_instance: Node) -> String:
	# Use LevelSettings to get level name (with backward compatibility)
	var settings = LevelSettings.from_node(level_instance)
	var name = settings.level_name
	if name.is_empty():
		return level_instance.name  # Fallback to node name
	return name


## Get level name from an already loaded level instance
func get_level_name_from_instance(level_instance: Node) -> String:
	var name = _extract_level_name(level_instance)
	if name.is_empty():
		return level_instance.name
	return name


## Load and instantiate a level scene by index
func load_level(index: int) -> Node:
	var path = get_level_path(index)
	if path.is_empty():
		push_error("Level index %d not found" % index)
		return null

	var scene = load(path)
	if scene == null:
		push_error("Failed to load level scene: %s" % path)
		return null

	return scene.instantiate()


## Load and instantiate a level scene by name (searches all subfolders)
func load_level_by_name(level_name: String) -> Node:
	if not _levels_loaded:
		_scan_levels_folder()

	for path in _level_paths:
		if path.get_file().get_basename() == level_name:
			var scene = load(path)
			if scene:
				return scene.instantiate()
	return null


## Scan the levelmaps folder for .tscn files (including subfolders)
func _scan_levels_folder() -> void:
	_level_paths.clear()
	_scan_folder_recursive(LEVELS_PATH)

	# Sort alphabetically/numerically by full path
	_level_paths.sort()
	_levels_loaded = true

	print("LevelLoader: Found %d levels" % _level_paths.size())
	for path in _level_paths:
		print("  - %s" % path)


## Recursively scan a folder for .tscn files
func _scan_folder_recursive(folder_path: String) -> void:
	var dir = DirAccess.open(folder_path)
	if dir == null:
		push_warning("Could not open folder: %s" % folder_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		var full_path = folder_path + file_name

		if dir.current_is_dir():
			# Skip hidden folders
			if not file_name.begins_with("."):
				_scan_folder_recursive(full_path + "/")
		elif file_name.ends_with(".tscn"):
			_level_paths.append(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()


## Force rescan of levels folder
func refresh() -> void:
	_levels_loaded = false
	_scan_levels_folder()


## Check if a level exists by name
func level_exists(level_name: String) -> bool:
	if not _levels_loaded:
		_scan_levels_folder()

	for path in _level_paths:
		if path.get_file().get_basename() == level_name:
			return true
	return false


## Get level path by name (searches all subfolders)
func get_level_path_by_name(level_name: String) -> String:
	if not _levels_loaded:
		_scan_levels_folder()

	for path in _level_paths:
		if path.get_file().get_basename() == level_name:
			return path
	return ""


## Get the index of a level by name
func get_level_index_by_name(level_name: String) -> int:
	if not _levels_loaded:
		_scan_levels_folder()

	for i in range(_level_paths.size()):
		if _level_paths[i].get_file().get_basename() == level_name:
			return i
	return -1
