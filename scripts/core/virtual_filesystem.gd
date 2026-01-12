## Virtual Filesystem for GoCars
## Manages in-memory file storage for multi-file Python projects
## Author: Claude Code
## Date: January 2026

extends RefCounted
class_name VirtualFileSystem

## Signals
signal file_created(path: String)
signal file_updated(path: String)
signal file_deleted(path: String)
signal directory_created(path: String)
signal directory_deleted(path: String)

## Storage dictionaries
var _files: Dictionary = {}  # "path/to/file.py" -> "file contents"
var _directories: Array = []  # List of directory paths

## Reserved filenames that cannot be deleted
const RESERVED_FILES: Array = ["main.py"]

## Valid file extensions
const VALID_EXTENSIONS: Array = [".py", ".md", ".txt"]

func _init() -> void:
	# Initialize with default workspace structure
	_initialize_default_workspace()

## Initialize default workspace with main.py and README.md
func _initialize_default_workspace() -> void:
	create_file("main.py", "# Write your code here\ncar.go()")
	create_file("README.md", _get_default_readme_content())

## Create a new file
func create_file(path: String, content: String = "") -> bool:
	var normalized_path = _normalize_path(path)

	# Validate path
	if not _is_valid_path(normalized_path):
		push_error("VirtualFileSystem: Invalid path '%s'" % path)
		return false

	# Check if file already exists
	if _files.has(normalized_path):
		push_warning("VirtualFileSystem: File '%s' already exists" % normalized_path)
		return false

	# Create parent directory if needed
	var parent_dir = _get_parent_directory(normalized_path)
	if parent_dir != "" and not _directory_exists(parent_dir):
		create_directory(parent_dir)

	# Create file
	_files[normalized_path] = content
	file_created.emit(normalized_path)
	return true

## Read file contents
func read_file(path: String) -> String:
	var normalized_path = _normalize_path(path)

	if not _files.has(normalized_path):
		push_error("VirtualFileSystem: File '%s' does not exist" % path)
		return ""

	return _files[normalized_path]

## Update file contents
func update_file(path: String, content: String) -> bool:
	var normalized_path = _normalize_path(path)

	if not _files.has(normalized_path):
		push_error("VirtualFileSystem: File '%s' does not exist" % path)
		return false

	_files[normalized_path] = content
	file_updated.emit(normalized_path)
	return true

## Delete a file
func delete_file(path: String) -> bool:
	var normalized_path = _normalize_path(path)

	# Check if file exists
	if not _files.has(normalized_path):
		push_error("VirtualFileSystem: File '%s' does not exist" % path)
		return false

	# Check if file is reserved
	var filename = _get_filename(normalized_path)
	if filename in RESERVED_FILES:
		push_error("VirtualFileSystem: Cannot delete reserved file '%s'" % filename)
		return false

	# Delete file
	_files.erase(normalized_path)
	file_deleted.emit(normalized_path)
	return true

## Check if file exists
func file_exists(path: String) -> bool:
	var normalized_path = _normalize_path(path)
	return _files.has(normalized_path)

## Create a directory
func create_directory(path: String) -> bool:
	var normalized_path = _normalize_path(path)

	# Validate path
	if not _is_valid_directory_path(normalized_path):
		push_error("VirtualFileSystem: Invalid directory path '%s'" % path)
		return false

	# Check if directory already exists
	if _directory_exists(normalized_path):
		push_warning("VirtualFileSystem: Directory '%s' already exists" % normalized_path)
		return false

	# Create parent directory if needed
	var parent_dir = _get_parent_directory(normalized_path)
	if parent_dir != "" and not _directory_exists(parent_dir):
		create_directory(parent_dir)

	# Create directory
	_directories.append(normalized_path)
	directory_created.emit(normalized_path)
	return true

## Check if directory exists
func directory_exists(path: String) -> bool:
	var normalized_path = _normalize_path(path)
	return _directory_exists(normalized_path)

## List files and directories in a directory
func list_directory(path: String) -> Array:
	var normalized_path = _normalize_path(path)
	if normalized_path != "" and not _directory_exists(normalized_path):
		push_error("VirtualFileSystem: Directory '%s' does not exist" % path)
		return []

	var items: Array = []

	# List files
	for file_path in _files.keys():
		if _is_direct_child(normalized_path, file_path):
			items.append({
				"name": _get_filename(file_path),
				"path": file_path,
				"type": "file"
			})

	# List directories
	for dir_path in _directories:
		if _is_direct_child(normalized_path, dir_path):
			items.append({
				"name": _get_filename(dir_path),
				"path": dir_path,
				"type": "directory"
			})

	return items

## Get complete file tree structure
func get_file_tree() -> Dictionary:
	var tree: Dictionary = {
		"name": "workspace",
		"type": "directory",
		"children": []
	}

	# Add all files and directories to tree
	var root_items = list_directory("")
	for item in root_items:
		if item["type"] == "file":
			tree["children"].append({
				"name": item["name"],
				"path": item["path"],
				"type": "file"
			})
		else:
			tree["children"].append(_build_directory_tree(item["path"]))

	return tree

## Get all file paths
func get_all_files() -> Array:
	return _files.keys()

## Get all directory paths
func get_all_directories() -> Array:
	return _directories.duplicate()

## Clear all files and directories (reset workspace)
func clear_all() -> void:
	_files.clear()
	_directories.clear()
	_initialize_default_workspace()

## Rename a file
func rename_file(old_path: String, new_path: String) -> bool:
	var old_normalized = _normalize_path(old_path)
	var new_normalized = _normalize_path(new_path)

	# Check if old file exists
	if not _files.has(old_normalized):
		push_error("VirtualFileSystem: File '%s' does not exist" % old_path)
		return false

	# Check if new path is valid
	if not _is_valid_path(new_normalized):
		push_error("VirtualFileSystem: Invalid new path '%s'" % new_path)
		return false

	# Check if new file already exists
	if _files.has(new_normalized):
		push_error("VirtualFileSystem: File '%s' already exists" % new_path)
		return false

	# Check if old file is reserved
	var old_filename = _get_filename(old_normalized)
	if old_filename in RESERVED_FILES:
		push_error("VirtualFileSystem: Cannot rename reserved file '%s'" % old_filename)
		return false

	# Rename file
	var content = _files[old_normalized]
	_files.erase(old_normalized)
	_files[new_normalized] = content

	file_deleted.emit(old_normalized)
	file_created.emit(new_normalized)
	return true

## Private helper functions

func _normalize_path(path: String) -> String:
	# Remove leading/trailing slashes
	var normalized = path.strip_edges()
	if normalized.begins_with("/"):
		normalized = normalized.substr(1)
	if normalized.ends_with("/"):
		normalized = normalized.substr(0, normalized.length() - 1)

	# Convert backslashes to forward slashes
	normalized = normalized.replace("\\", "/")

	return normalized

func _is_valid_path(path: String) -> bool:
	# Check for empty path
	if path == "":
		return false

	# Check for invalid characters
	var invalid_chars = ["<", ">", ":", "\"", "|", "?", "*"]
	for char in invalid_chars:
		if char in path:
			return false

	# Check for valid file extension
	var has_valid_extension = false
	for ext in VALID_EXTENSIONS:
		if path.ends_with(ext):
			has_valid_extension = true
			break

	return has_valid_extension

func _is_valid_directory_path(path: String) -> bool:
	# Check for empty path (root is valid)
	if path == "":
		return true

	# Check for invalid characters
	var invalid_chars = ["<", ">", ":", "\"", "|", "?", "*", "."]
	for char in invalid_chars:
		if char in path:
			return false

	return true

func _directory_exists(path: String) -> bool:
	# Root directory always exists
	if path == "":
		return true

	return path in _directories

func _get_parent_directory(path: String) -> String:
	var last_slash = path.rfind("/")
	if last_slash == -1:
		return ""
	return path.substr(0, last_slash)

func _get_filename(path: String) -> String:
	var last_slash = path.rfind("/")
	if last_slash == -1:
		return path
	return path.substr(last_slash + 1)

func _is_direct_child(parent_path: String, child_path: String) -> bool:
	# Root directory case
	if parent_path == "":
		# Child is direct if it has no slashes
		return "/" not in child_path

	# Check if child starts with parent path
	if not child_path.begins_with(parent_path + "/"):
		return false

	# Get relative path
	var relative_path = child_path.substr(parent_path.length() + 1)

	# Direct child has no slashes in relative path
	return "/" not in relative_path

func _build_directory_tree(dir_path: String) -> Dictionary:
	var tree: Dictionary = {
		"name": _get_filename(dir_path),
		"path": dir_path,
		"type": "directory",
		"children": []
	}

	var items = list_directory(dir_path)
	for item in items:
		if item["type"] == "file":
			tree["children"].append({
				"name": item["name"],
				"path": item["path"],
				"type": "file"
			})
		else:
			tree["children"].append(_build_directory_tree(item["path"]))

	return tree

func _get_default_readme_content() -> String:
	return """# GoCars — Code Your Way Through Traffic

## 🎮 How to Play
1. Write Python code in the Code Editor
2. Click **Run** (or press F5)
3. Watch your cars navigate the traffic!
4. Reach the destination 🏁 without crashing

## 🚗 Car Commands

### Movement
- `car.go()` — Start moving forward
- `car.stop()` — Stop immediately
- `car.turn("left")` — Turn left 90°
- `car.turn("right")` — Turn right 90°
- `car.move(N)` — Move forward N tiles
- `car.wait(N)` — Wait N seconds

### Detection
- `car.front_road()` — True if road ahead
- `car.left_road()` — True if road to left
- `car.right_road()` — True if road to right
- `car.front_car()` — True if car ahead
- `car.front_crash()` — True if crashed car ahead
- `car.at_end()` — True if at destination

## 🚦 Stoplight Commands
- `stoplight.is_red()` — True if light is red
- `stoplight.is_yellow()` — True if light is yellow
- `stoplight.is_green()` — True if light is green
- `stoplight.set_red()` — Change to red
- `stoplight.set_green()` — Change to green

⚠️ **Warning:** Cars do NOT auto-stop at red lights!
You must code: `if stoplight.is_red(): car.stop()`

## 📦 Creating Modules

### helpers.py
```python
def smart_turn(vehicle):
    if vehicle.left_road():
		vehicle.turn("left")
    elif vehicle.right_road():
		vehicle.turn("right")
```

### main.py
```python
from helpers import smart_turn

car.go()
smart_turn(car)
```

## 💡 Tips
- Always pass `car` or `stoplight` as parameters to your functions
- Use `while not car.at_end():` to loop until destination
- Crashed cars become obstacles — check with `car.front_crash()`
"""
