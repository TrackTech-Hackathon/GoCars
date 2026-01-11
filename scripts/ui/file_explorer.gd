## File Explorer for GoCars Code Editor
## Tree-based file browser with create/rename/delete operations
## Author: Claude Code
## Date: January 2026

extends VBoxContainer
class_name FileExplorer

## Signals
signal file_selected(file_path: String)
signal file_created(file_path: String)
signal file_renamed(old_path: String, new_path: String)
signal file_deleted(file_path: String)

## Child nodes
var tree: Tree
var button_container: HBoxContainer
var new_file_button: Button
var new_folder_button: Button

## Virtual filesystem reference
var virtual_fs: Variant = null  # VirtualFileSystem instance

## Current selection
var selected_file: String = ""

func _ready() -> void:
	# Button container
	button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	add_child(button_container)

	# New file button
	new_file_button = Button.new()
	new_file_button.name = "NewFileButton"
	new_file_button.text = "+File"
	new_file_button.tooltip_text = "Create new file"
	button_container.add_child(new_file_button)

	# New folder button
	new_folder_button = Button.new()
	new_folder_button.name = "NewFolderButton"
	new_folder_button.text = "+Folder"
	new_folder_button.tooltip_text = "Create new folder"
	button_container.add_child(new_folder_button)

	# File tree
	tree = Tree.new()
	tree.name = "FileTree"
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.hide_root = true
	tree.allow_rmb_select = true
	add_child(tree)

	# Connect signals
	new_file_button.pressed.connect(_on_new_file_pressed)
	new_folder_button.pressed.connect(_on_new_folder_pressed)
	tree.item_selected.connect(_on_item_selected)
	tree.item_activated.connect(_on_item_activated)

## Set the virtual filesystem
func set_virtual_filesystem(vfs: Variant) -> void:
	virtual_fs = vfs
	refresh()

## Refresh the file tree from virtual filesystem
func refresh() -> void:
	if virtual_fs == null:
		return

	tree.clear()
	var root = tree.create_item()

	# Get all files and directories
	var all_files = virtual_fs.get_all_files()
	var all_dirs = virtual_fs.get_all_directories()

	# Build directory structure
	var dir_items: Dictionary = {}  # path -> TreeItem
	dir_items[""] = root

	# Create directory items first
	all_dirs.sort()
	for dir_path in all_dirs:
		if dir_path == "":
			continue
		var parent_path = dir_path.get_base_dir()
		var dir_name = dir_path.get_file()
		if dir_name == "":
			dir_name = dir_path

		var parent_item = dir_items.get(parent_path, root)
		var dir_item = tree.create_item(parent_item)
		dir_item.set_text(0, dir_name)
		dir_item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
		dir_item.set_metadata(0, {"type": "directory", "path": dir_path})
		dir_items[dir_path] = dir_item

	# Create file items
	all_files.sort()
	for file_path in all_files:
		var parent_path = file_path.get_base_dir()
		var file_name = file_path.get_file()

		var parent_item = dir_items.get(parent_path, root)
		var file_item = tree.create_item(parent_item)
		file_item.set_text(0, file_name)
		file_item.set_icon(0, _get_file_icon(file_path))
		file_item.set_metadata(0, {"type": "file", "path": file_path})

func _get_file_icon(file_path: String) -> Texture2D:
	var ext = file_path.get_extension()
	match ext:
		"py":
			return get_theme_icon("Script", "EditorIcons")
		"md", "txt":
			return get_theme_icon("TextFile", "EditorIcons")
		_:
			return get_theme_icon("File", "EditorIcons")

func _on_item_selected() -> void:
	var selected = tree.get_selected()
	if selected == null:
		return

	var metadata = selected.get_metadata(0)
	if metadata != null and metadata.get("type") == "file":
		selected_file = metadata.get("path", "")

func _on_item_activated() -> void:
	var selected = tree.get_selected()
	if selected == null:
		return

	var metadata = selected.get_metadata(0)
	if metadata != null and metadata.get("type") == "file":
		var file_path = metadata.get("path", "")
		file_selected.emit(file_path)

func _on_new_file_pressed() -> void:
	if virtual_fs == null:
		return

	# Create new file dialog (simplified - just use default name)
	var file_name = "new_file.py"
	var counter = 1
	while virtual_fs.file_exists(file_name):
		file_name = "new_file_%d.py" % counter
		counter += 1

	if virtual_fs.create_file(file_name, "# New file\n"):
		refresh()
		file_created.emit(file_name)

func _on_new_folder_pressed() -> void:
	if virtual_fs == null:
		return

	# Create new folder (simplified - just use default name)
	var folder_name = "new_folder"
	var counter = 1
	while virtual_fs.directory_exists(folder_name):
		folder_name = "new_folder_%d" % counter
		counter += 1

	if virtual_fs.create_directory(folder_name):
		refresh()

## Get currently selected file path
func get_selected_file() -> String:
	return selected_file

## Select a specific file in the tree
func select_file(file_path: String) -> void:
	var root = tree.get_root()
	if root == null:
		return

	_select_file_recursive(root, file_path)

func _select_file_recursive(item: TreeItem, file_path: String) -> bool:
	var metadata = item.get_metadata(0)
	if metadata != null and metadata.get("path") == file_path:
		item.select(0)
		return true

	for child in item.get_children():
		if _select_file_recursive(child, file_path):
			return true

	return false
