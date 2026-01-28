## Migration Tool: Update all levels to use LevelSettings
## How to use:
## 1. Save this file in scripts/tools/
## 2. In Godot editor, run it via: File → Run
## 3. Check the console output for results
## 4. Restart Godot to reload the scenes

@tool
extends EditorScript

class_name MigrateLevelSettings

## Level configurations - customize values here if needed
var level_configs = {
	"level_00": {
		"level_name": "Welcome to GoCars!",
		"starting_hearts": 10,
		"build_mode_enabled": false,
		"road_cards": 0,
	},
	"level_01": {
		"level_name": "Navigation Basics",
		"starting_hearts": 10,
		"build_mode_enabled": false,
		"road_cards": 0,
	},
	"level_02": {
		"level_name": "Loops",
		"starting_hearts": 5,
		"build_mode_enabled": false,
		"road_cards": 0,
	},
	"level_03": {
		"level_name": "Traffic Lights",
		"starting_hearts": 5,
		"build_mode_enabled": false,
		"road_cards": 0,
	},
	"level_04": {
		"level_name": "Putting It All Together",
		"starting_hearts": 3,
		"build_mode_enabled": false,
		"road_cards": 0,
	},
}

func _run() -> void:
	print("\n" + "=".repeat(60))
	print("GoCars Level Settings Migration Tool")
	print("=".repeat(60) + "\n")

	# Find all level scenes
	var level_dir = "res://scenes/levelmaps/"
	var dir = DirAccess.open(level_dir)

	if dir == null:
		print("ERROR: Could not open level directory: " + level_dir)
		return

	var level_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tscn") and file_name.begins_with("level_"):
			level_files.append(file_name)
		file_name = dir.get_next()

	level_files.sort()

	if level_files.is_empty():
		print("ERROR: No level files found in " + level_dir)
		return

	print("Found " + str(level_files.size()) + " levels:")
	for file in level_files:
		print("  - " + file)

	print("\nMigrating levels...\n")

	var migrated_count = 0
	for file_name in level_files:
		var level_key = file_name.trim_suffix(".tscn")
		var file_path = level_dir + file_name

		if level_key not in level_configs:
			print("[SKIP] " + file_name + " - no configuration found")
			continue

		var config = level_configs[level_key]
		print("[" + level_key + "] Migrating...")

		# Load the scene
		var level_scene = load(file_path) as PackedScene
		if level_scene == null:
			print("  ERROR: Could not load scene")
			continue

		# Instantiate to get access to nodes
		var level_instance = level_scene.instantiate()
		var level_settings = level_instance.get_node_or_null("LevelSettings")

		if level_settings == null:
			print("  ERROR: LevelSettings node not found")
			level_instance.queue_free()
			continue

		# Check if script is already attached
		if level_settings.get_script() == load("res://scripts/core/level_settings.gd"):
			print("  SKIP: Already has LevelSettings script")
			level_instance.queue_free()
			continue

		# Detach from tree
		level_instance.remove_child(level_settings)

		# Attach the script
		level_settings.set_script(load("res://scripts/core/level_settings.gd"))

		# Set the properties
		level_settings.level_name = config["level_name"]
		level_settings.starting_hearts = config["starting_hearts"]
		level_settings.build_mode_enabled = config["build_mode_enabled"]
		level_settings.road_cards = config["road_cards"]

		print("  ✓ Script attached and properties set:")
		print("    - level_name: " + config["level_name"])
		print("    - starting_hearts: " + str(config["starting_hearts"]))
		print("    - build_mode_enabled: " + str(config["build_mode_enabled"]))
		print("    - road_cards: " + str(config["road_cards"]))

		# Delete old Label nodes if they exist (optional - keeps backward compat if you don't)
		var label_nodes = ["LevelName", "LevelBuildRoads", "LevelCars"]
		for label_name in label_nodes:
			var old_label = level_settings.get_node_or_null(label_name)
			if old_label:
				level_settings.remove_child(old_label)
				old_label.queue_free()
				print("    - Deleted old " + label_name + " Label")

		# Optionally delete HeartCount from HeartsUI
		var hearts_ui = level_instance.get_node_or_null("HeartsUI")
		if hearts_ui:
			var heart_count_label = hearts_ui.get_node_or_null("HeartCount")
			if heart_count_label:
				hearts_ui.remove_child(heart_count_label)
				heart_count_label.queue_free()
				print("    - Deleted HeartCount Label from HeartsUI")

		# Save the scene back
		var updated_scene = level_scene.duplicate()
		var root = updated_scene.instantiate()

		# Re-attach level_settings with updated properties
		root.add_child(level_settings)
		level_settings.owner = root

		# Save to file
		var error = ResourceSaver.save(updated_scene, file_path)
		if error == OK:
			print("  ✓ Scene saved successfully\n")
			migrated_count += 1
		else:
			print("  ERROR: Failed to save scene (error code: " + str(error) + ")\n")

		level_instance.queue_free()

	print("=".repeat(60))
	print("Migration complete! " + str(migrated_count) + "/" + str(level_files.size()) + " levels updated")
	print("=".repeat(60))
	print("\nNEXT STEPS:")
	print("1. Restart Godot editor to reload scenes")
	print("2. Open each level in the editor to verify settings")
	print("3. Check that LevelSettings node has the correct properties")
