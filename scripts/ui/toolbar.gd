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
var code_editor_button: Button
var readme_button: Button
var skill_tree_button: Button

func _ready() -> void:
	# Setup toolbar appearance
	alignment = ALIGNMENT_END

	# Create Code Editor button [+]
	code_editor_button = Button.new()
	code_editor_button.name = "CodeEditorButton"
	code_editor_button.text = "[+]"
	code_editor_button.tooltip_text = "Open Code Editor (Ctrl+1)"
	code_editor_button.custom_minimum_size = Vector2(40, 32)
	add_child(code_editor_button)

	# Create README button [i]
	readme_button = Button.new()
	readme_button.name = "ReadmeButton"
	readme_button.text = "[i]"
	readme_button.tooltip_text = "Open Documentation (Ctrl+2)"
	readme_button.custom_minimum_size = Vector2(40, 32)
	add_child(readme_button)

	# Create Skill Tree button [🌳]
	skill_tree_button = Button.new()
	skill_tree_button.name = "SkillTreeButton"
	skill_tree_button.text = "[🌳]"
	skill_tree_button.tooltip_text = "Open Skill Tree (Ctrl+3)"
	skill_tree_button.custom_minimum_size = Vector2(40, 32)
	add_child(skill_tree_button)

	# Connect signals
	code_editor_button.pressed.connect(_on_code_editor_pressed)
	readme_button.pressed.connect(_on_readme_pressed)
	skill_tree_button.pressed.connect(_on_skill_tree_pressed)

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
