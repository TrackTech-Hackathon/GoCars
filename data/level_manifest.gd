extends RefCounted
class_name LevelManifest

## Static level manifest for exported builds
## DirAccess cannot enumerate packed resources, so we maintain this list
##
## IMPORTANT: Update this file whenever you add/remove/rename levels!
## Run the game in editor and call LevelManifest.generate_manifest() to update

## All level paths organized by map folder
## Format: { "folder_name": ["level_path1", "level_path2", ...] }
const LEVELS: Dictionary = {
	"01Tutorial": [
		"res://scenes/levelmaps/01Tutorial/01 Level 1.tscn",
		"res://scenes/levelmaps/01Tutorial/01 Level 2.tscn",
		"res://scenes/levelmaps/01Tutorial/01 Level 3.tscn",
		"res://scenes/levelmaps/01Tutorial/01 Level 4.tscn",
		"res://scenes/levelmaps/01Tutorial/01 Level 5.tscn",
	],
	"02Iloilo": [
		"res://scenes/levelmaps/02Iloilo/02 Level 1.tscn",
	],
	"03Antique": [],
	"04Aklan": [],
	"05Capiz": [],
}

## All level paths as a flat sorted array (for LevelLoader compatibility)
const ALL_LEVELS: Array[String] = [
	"res://scenes/levelmaps/01Tutorial/01 Level 1.tscn",
	"res://scenes/levelmaps/01Tutorial/01 Level 2.tscn",
	"res://scenes/levelmaps/01Tutorial/01 Level 3.tscn",
	"res://scenes/levelmaps/01Tutorial/01 Level 4.tscn",
	"res://scenes/levelmaps/01Tutorial/01 Level 5.tscn",
	"res://scenes/levelmaps/02Iloilo/02 Level 1.tscn",
]

## Root-level levels (not in subfolders)
const ROOT_LEVELS: Array[String] = [
	"res://scenes/levelmaps/level_00.tscn",
	"res://scenes/levelmaps/level_01.tscn",
	"res://scenes/levelmaps/level_02.tscn",
	"res://scenes/levelmaps/level_03.tscn",
	"res://scenes/levelmaps/level_04.tscn",
]


## Get levels for a specific map folder
static func get_levels_for_map(folder_name: String) -> Array:
	if LEVELS.has(folder_name):
		return LEVELS[folder_name].duplicate()
	return []


## Get all levels (flat list, sorted)
static func get_all_levels() -> Array[String]:
	return ALL_LEVELS.duplicate()


## Get root-level levels only
static func get_root_levels() -> Array[String]:
	return ROOT_LEVELS.duplicate()


## Check if we're running in an exported build
static func is_exported() -> bool:
	return not OS.has_feature("editor")


## Generate manifest from current folder structure (call from editor)
## Prints GDScript code to paste into this file
static func generate_manifest() -> void:
	if not OS.has_feature("editor"):
		print("generate_manifest() can only be called from the editor!")
		return

	var base_path = "res://scenes/levelmaps/"
	var map_folders = ["01Tutorial", "02Iloilo", "03Antique", "04Aklan", "05Capiz"]

	print("\n# Generated Level Manifest - Copy this into level_manifest.gd\n")
	print("const LEVELS: Dictionary = {")

	var all_levels: Array[String] = []

	for folder in map_folders:
		var folder_path = base_path + folder + "/"
		var levels = _scan_folder(folder_path)
		levels.sort()

		print('\t"%s": [' % folder)
		for level_path in levels:
			print('\t\t"%s",' % level_path)
			all_levels.append(level_path)
		print("\t],")

	print("}\n")

	all_levels.sort()
	print("const ALL_LEVELS: Array[String] = [")
	for level_path in all_levels:
		print('\t"%s",' % level_path)
	print("]\n")

	# Root levels
	var root_levels = _scan_folder(base_path)
	root_levels.sort()
	print("const ROOT_LEVELS: Array[String] = [")
	for level_path in root_levels:
		print('\t"%s",' % level_path)
	print("]")


static func _scan_folder(folder_path: String) -> Array[String]:
	var levels: Array[String] = []
	var dir = DirAccess.open(folder_path)
	if dir == null:
		return levels

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			levels.append(folder_path + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	return levels
