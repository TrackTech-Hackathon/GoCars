## Toolbar for GoCars
## Top-right toolbar with window launcher buttons
## Author: Claude Code
## Date: January 2026

extends HBoxContainer
class_name Toolbar

## Signals
signal code_editor_requested()
signal readme_requested()
signal skill_tree_requested()

## Child nodes
@onready var code_editor_button: Button = $CodeEditorButton
@onready var readme_button: Button = $ReadmeButton
@onready var skill_tree_button: Button = $SkillTreeButton

func _ready() -> void:
	# Setup toolbar appearance
	alignment = ALIGNMENT_END

	# Connect signals
	code_editor_button.pressed.connect(_on_code_editor_pressed)
	readme_button.pressed.connect(_on_readme_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		match event.keycode:
			KEY_1:
				_on_code_editor_pressed()
				get_viewport().set_input_as_handled()
			KEY_2:
				_on_readme_pressed()
				get_viewport().set_input_as_handled()
			KEY_3:
				_on_skill_tree_pressed()
				get_viewport().set_input_as_handled()

func _on_code_editor_pressed() -> void:
	code_editor_requested.emit()

func _on_readme_pressed() -> void:
	readme_requested.emit()

func _on_skill_tree_pressed() -> void:
	skill_tree_requested.emit()
