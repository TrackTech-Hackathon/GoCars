## Tutorial Dialogue Box for GoCars
## Displays Maki character and dialogue with typewriter effect
## Author: Claude Code
## Date: January 2026

extends CanvasLayer

## Signals
signal continue_pressed()
signal skip_pressed()
signal retry_pressed()

## Node references
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var character_portrait: TextureRect = $DialoguePanel/CharacterPortrait
@onready var speaker_name: Label = $DialoguePanel/HBoxContainer/VBoxContainer/SpeakerName
@onready var dialogue_text: RichTextLabel = $DialoguePanel/HBoxContainer/VBoxContainer/DialogueText
@onready var action_helper: Label = $DialoguePanel/HBoxContainer/VBoxContainer/ActionHelper
@onready var continue_indicator: Label = $DialoguePanel/HBoxContainer/VBoxContainer/ContinueIndicator
@onready var skip_button: Button = $DialoguePanel/SkipButton

## Maki sprite textures
var sprites: Dictionary = {}
var current_emotion: String = "normal"



## Typewriter effect
var _typewriter_tween: Tween = null
var _full_text: String = ""
var _chars_per_second: float = 40.0
var _is_typing: bool = false

## Continue indicator animation
var _continue_tween: Tween = null

func _ready() -> void:
	# Load Maki sprites
	_load_sprites()

	# Connect signals
	skip_button.pressed.connect(_on_skip_pressed)

	# Setup input handling for clicking
	dialogue_panel.gui_input.connect(_on_panel_input)

	# Hide initially
	visible = false
	skip_button.visible = false

	# Start continue indicator animation
	_animate_continue_indicator()

## Load all Maki sprite textures
func _load_sprites() -> void:
	var sprite_paths = {
		"normal": "res://assets/sprites/Maki_Normal.png",
		"talking": "res://assets/sprites/maki_talking.png",
		"pointing": "res://assets/sprites/Maki_talking_pointing.png",
		"happy": "res://assets/sprites/Maki_happy.png"
	}

	for emotion in sprite_paths:
		var texture = load(sprite_paths[emotion])
		if texture:
			sprites[emotion] = texture
			print("TutorialDialogueBox: Loaded %s sprite" % emotion)
		else:
			push_warning("TutorialDialogueBox: Could not load %s sprite" % emotion)

## Show dialogue with text, speaker, emotion, and optional action hint
func show_dialogue(text: String, speaker: String = "Maki", emotion: String = "talking", action_hint: String = "") -> void:
	visible = true
	dialogue_panel.visible = true

	# Set speaker name
	speaker_name.text = speaker.to_upper()

	# Change character sprite with crossfade
	_set_emotion(emotion)

	# Show action helper if provided
	if action_hint.is_empty():
		action_helper.visible = false
	else:
		action_helper.text = ">> " + action_hint
		action_helper.visible = true

	# Start typewriter effect
	_start_typewriter(text)

## Hide the dialogue box
func hide_dialogue() -> void:
	# Fade out
	var tween = create_tween()
	tween.tween_property(dialogue_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(  func():
		visible = false
		dialogue_panel.modulate.a = 1.0
	)

## Show character with appear animation
func show_character() -> void:
	visible = true
	dialogue_panel.visible = true

	# Slide in from bottom
	var original_y = dialogue_panel.position.y
	dialogue_panel.position.y = dialogue_panel.position.y + 100
	dialogue_panel.modulate.a = 0.0

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(dialogue_panel, "position:y", original_y, 0.4)
	tween.parallel().tween_property(dialogue_panel, "modulate:a", 1.0, 0.3)

## Show skip button (for returning players)
func show_skip_button() -> void:
	skip_button.visible = true

## Hide skip button
func hide_skip_button() -> void:
	skip_button.visible = false

## Set character emotion/sprite
func _set_emotion(emotion: String) -> void:
	if emotion == current_emotion:
		return

	current_emotion = emotion

	# Get sprite, fallback to normal
	var texture = sprites.get(emotion, sprites.get("normal"))
	if not texture:
		return

	# Crossfade to new sprite
	var tween = create_tween()
	tween.tween_property(character_portrait, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func():
		character_portrait.texture = texture
	)
	tween.tween_property(character_portrait, "modulate:a", 1.0, 0.1)

## Start typewriter effect
func _start_typewriter(text: String) -> void:
	_full_text = text
	_is_typing = true

	dialogue_text.text = text
	dialogue_text.visible_characters = 0

	# Hide continue indicator while typing
	continue_indicator.visible = false

	# Kill existing tween
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	# Calculate duration
	var duration = text.length() / _chars_per_second

	# Create typewriter tween
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(
		dialogue_text, "visible_characters",
		text.length(), duration
	)
	_typewriter_tween.tween_callback(_on_typewriter_complete)

## Skip typewriter effect (show all text immediately)
func _skip_typewriter() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	dialogue_text.visible_characters = -1  # Show all
	_on_typewriter_complete()

## Called when typewriter finishes
func _on_typewriter_complete() -> void:
	_is_typing = false
	continue_indicator.visible = true

## Animate continue indicator (bouncing)
func _animate_continue_indicator() -> void:
	if _continue_tween and _continue_tween.is_valid():
		_continue_tween.kill()

	var original_y = continue_indicator.position.y

	_continue_tween = create_tween()
	_continue_tween.set_loops()
	_continue_tween.set_ease(Tween.EASE_IN_OUT)
	_continue_tween.set_trans(Tween.TRANS_SINE)
	_continue_tween.tween_property(continue_indicator, "position:y", original_y + 8, 0.5)
	_continue_tween.tween_property(continue_indicator, "position:y", original_y, 0.5)

## Handle panel input (click to continue)
func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click()

## Handle click
func _handle_click() -> void:
	if _is_typing:
		# Skip typewriter
		_skip_typewriter()
	else:
		# Continue to next dialogue
		continue_pressed.emit()

## Handle skip button
func _on_skip_pressed() -> void:
	skip_pressed.emit()

## Handle input globally (spacebar, enter)
func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Don't consume input if a TextEdit or LineEdit has focus (player is typing)
	var focused_control = get_viewport().gui_get_focus_owner()
	if focused_control is TextEdit or focused_control is LineEdit or focused_control is CodeEdit:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_handle_click()
			get_viewport().set_input_as_handled()
