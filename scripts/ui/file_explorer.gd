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
var rename_button: Button

## Virtual filesystem reference
var virtual_fs: Variant = null  # VirtualFileSystem instance

## Current selection
var selected_file: String = ""

## Popup for naming/renaming
var name_popup: PopupPanel
var name_input: LineEdit
var name_confirm_button: Button
var name_cancel_button: Button
var current_action: String = ""  # "new_file", "new_folder", "rename"
var rename_target: String = ""  # Path of item being renamed

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

	# Rename button
	rename_button = Button.new()
	rename_button.name = "RenameButton"
	rename_button.text = "Rename"
	rename_button.tooltip_text = "Rename selected file/folder (F2)"
	rename_button.disabled = true
	button_container.add_child(rename_button)

	# File tree
	tree = Tree.new()
	tree.name = "FileTree"
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.hide_root = true
	tree.allow_rmb_select = true
	add_child(tree)

	# Create name popup
	_create_name_popup()

	# Connect signals
	new_file_button.pressed.connect(_on_new_file_pressed)
	new_folder_button.pressed.connect(_on_new_folder_pressed)
	rename_button.pressed.connect(_on_rename_pressed)
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

func _create_name_popup() -> void:
	# Create popup panel
	name_popup = PopupPanel.new()
	name_popup.name = "NamePopup"
	name_popup.size = Vector2(300, 100)
	name_popup.popup_window = false
	add_child(name_popup)

	# VBox for layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	name_popup.add_child(vbox)

	# Input field
	name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "Enter name..."
	vbox.add_child(name_input)

	# Button container
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	# Cancel button
	name_cancel_button = Button.new()
	name_cancel_button.text = "Cancel"
	name_cancel_button.pressed.connect(_on_name_cancel)
	hbox.add_child(name_cancel_button)

	# Confirm button
	name_confirm_button = Button.new()
	name_confirm_button.text = "OK"
	name_confirm_button.pressed.connect(_on_name_confirm)
	hbox.add_child(name_confirm_button)

	# Enter key confirms
	name_input.text_submitted.connect(func(_text): _on_name_confirm())

func _show_name_popup(action: String, title: String, default_name: String = "") -> void:
	current_action = action
	name_input.text = default_name
	name_popup.title = title
	name_popup.popup_centered()
	name_input.grab_focus()
	name_input.select_all()

func _on_name_confirm() -> void:
	var name = name_input.text.strip_edges()
	if name.is_empty():
		name_popup.hide()
		return

	match current_action:
		"new_file":
			_create_file(name)
		"new_folder":
			_create_folder(name)
		"rename":
			_rename_item(name)

	name_popup.hide()

func _on_name_cancel() -> void:
	name_popup.hide()

func _on_item_selected() -> void:
	var selected = tree.get_selected()
	if selected == null:
		rename_button.disabled = true
		return

	var metadata = selected.get_metadata(0)
	if metadata != null:
		rename_button.disabled = false
		if metadata.get("type") == "file":
			selected_file = metadata.get("path", "")
	else:
		rename_button.disabled = true

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
	_show_name_popup("new_file", "New File", "new_file.py")

func _on_new_folder_pressed() -> void:
	if virtual_fs == null:
		return
	_show_name_popup("new_folder", "New Folder", "new_folder")

func _on_rename_pressed() -> void:
	var selected = tree.get_selected()
	if selected == null or virtual_fs == null:
		return

	var metadata = selected.get_metadata(0)
	if metadata == null:
		return

	rename_target = metadata.get("path", "")
	var current_name = selected.get_text(0)
	_show_name_popup("rename", "Rename", current_name)

func _create_file(file_name: String) -> void:
	if not file_name.ends_with(".py"):
		file_name += ".py"

	if virtual_fs.file_exists(file_name):
		push_error("File already exists: %s" % file_name)
		return

	if virtual_fs.create_file(file_name, "# " + file_name + "\n"):
		refresh()
		file_created.emit(file_name)
		select_file(file_name)

func _create_folder(folder_name: String) -> void:
	if virtual_fs.directory_exists(folder_name):
		push_error("Folder already exists: %s" % folder_name)
		return

	if virtual_fs.create_directory(folder_name):
		refresh()

func _rename_item(new_name: String) -> void:
	if rename_target.is_empty():
		return

	var old_path = rename_target
	var parent_dir = old_path.get_base_dir()
	var new_path = parent_dir.path_join(new_name) if parent_dir != "" else new_name

	# Check if renaming a file
	if virtual_fs.file_exists(old_path):
		var content = virtual_fs.read_file(old_path)
		if virtual_fs.delete_file(old_path) and virtual_fs.create_file(new_path, content):
			refresh()
			file_renamed.emit(old_path, new_path)
			select_file(new_path)
	# Check if renaming a directory
	elif virtual_fs.directory_exists(old_path):
		# For now, just show an error (directory renaming is complex)
		push_error("Directory renaming not yet implemented")

	rename_target = ""

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
