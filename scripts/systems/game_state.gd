extends Node

## GameState Autoload
## Singleton for passing data between scenes

# Selected level ID (set by level selector, read by main game)
var selected_level_id: String = ""

# Selected level full path (for loading from subfolders)
var selected_level_path: String = ""


## Clear selected level data
func clear_level_selection() -> void:
	selected_level_id = ""
	selected_level_path = ""
