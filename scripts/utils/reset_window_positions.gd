## Reset Window Positions Script
## Deletes saved window state to reset all windows to default centered positions
## Usage: Run this script from Godot with "godot --path . --script reset_window_positions.gd"

extends SceneTree

func _init():
	print("Resetting window positions...")

	var settings_path = "user://window_settings.json"

	if FileAccess.file_exists(settings_path):
		var error = DirAccess.remove_absolute(settings_path)
		if error == OK:
			print("✓ Deleted saved window state: %s" % settings_path)
			print("✓ All windows will now spawn centered on next launch")
		else:
			print("✗ Failed to delete window state file (error %d)" % error)
	else:
		print("✓ No saved window state found - windows already using defaults")

	print("\nWindow positions reset complete!")
	quit()
