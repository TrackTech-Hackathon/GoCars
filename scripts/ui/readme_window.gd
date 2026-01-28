## README Documentation Window for GoCars
## Displays Python commands, import system help, and tips
## Author: Claude Code
## Date: January 2026

extends FloatingWindow
class_name ReadmeWindow

## Child nodes
var scroll_container: ScrollContainer
var rich_text: RichTextLabel

func _init() -> void:
	min_size = Vector2(500, 400)
	default_size = Vector2(600, 500)
	default_position = Vector2(300, 100)

func _ready() -> void:
	super._ready()
	
	# Get references to nodes from scene
	scroll_container = $VBoxContainer/ContentContainer/ScrollContainer
	rich_text = $VBoxContainer/ContentContainer/ScrollContainer/RichTextLabel
