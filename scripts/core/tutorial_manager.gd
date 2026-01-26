## Tutorial Manager for GoCars
## AutoLoad singleton that manages tutorial progression and UI
## Author: Claude Code
## Date: January 2026

extends Node

## Preload TutorialData class
const TutorialDataClass = preload("res://scripts/core/tutorial_data.gd")

## Signals
signal tutorial_started(level_id: String)
signal tutorial_step_changed(step_index: int)
signal tutorial_completed(level_id: String)
signal tutorial_skipped(level_id: String)
signal dialogue_shown(text: String, speaker: String, emotion: String)
signal dialogue_hidden()
signal highlight_requested(target: String)
signal highlight_cleared()
signal wait_for_action(action_type: String)
signal force_event(event_type: String)

## Tutorial data (RefCounted - TutorialData instance)
var tutorial_data = null

## Current tutorial state (TutorialData.TutorialLevel instance)
var current_tutorial = null
var current_step_index: int = -1
var current_dialogue_index: int = 0
var is_tutorial_active: bool = false
var is_waiting_for_action: bool = false
var pending_wait_action: String = ""

## UI references (set by main_tilemap.gd when tutorial starts)
var dialogue_box: Node = null

## Preloaded dialogue box scene
var dialogue_box_scene: PackedScene = null

## Preloaded highlight scene
var highlight_scene: PackedScene = null

## Highlight overlay
var highlight_overlay: Node = null

func _ready() -> void:
	# Load tutorial data
	tutorial_data = TutorialDataClass.new()

	# Preload dialogue box scene
	dialogue_box_scene = load("res://scenes/ui/tutorial/tutorial_dialogue_box.tscn")	
	# Preload highlight scene
	highlight_scene = load("res://scenes/ui/tutorial/tutorial_highlight.tscn")
	print("TutorialManager: Ready")

## Start tutorial for a level
func start_tutorial(level_name: String, parent_node: Node) -> bool:
	if not tutorial_data:
		push_error("TutorialManager: No tutorial data loaded")
		return false

	current_tutorial = tutorial_data.get_tutorial_for_level(level_name)
	if not current_tutorial:
		print("TutorialManager: No tutorial found for level %s" % level_name)
		return false

	# Check if already completed and should skip
	if GameData.has_completed_tutorial(level_name):
		print("TutorialManager: Tutorial %s already completed, showing skip option" % level_name)
		# Show skip option will be handled by dialogue box

	# Create dialogue box if not exists
	if not dialogue_box and dialogue_box_scene:
		dialogue_box = dialogue_box_scene.instantiate()
		parent_node.add_child(dialogue_box)

		# Connect dialogue box signals
		if dialogue_box.has_signal("continue_pressed"):
			dialogue_box.continue_pressed.connect(_on_continue_pressed)
		if dialogue_box.has_signal("skip_pressed"):
			dialogue_box.skip_pressed.connect(_on_skip_pressed)
	
	# Create highlight overlay if not exists
	if not highlight_overlay and highlight_scene:
		highlight_overlay = highlight_scene.instantiate()
		parent_node.add_child(highlight_overlay)

	# Show skip button if already completed
	if dialogue_box and GameData.has_completed_tutorial(level_name):
		if dialogue_box.has_method("show_skip_button"):
			dialogue_box.show_skip_button()

	# Start tutorial
	current_step_index = -1
	current_dialogue_index = 0
	is_tutorial_active = true
	is_waiting_for_action = false

	tutorial_started.emit(current_tutorial.id)
	print("TutorialManager: Started tutorial %s" % current_tutorial.id)

	# Show first step
	advance_step()

	return true

## Advance to next step
func advance_step() -> void:
	if not is_tutorial_active or not current_tutorial:
		return

	current_step_index += 1
	current_dialogue_index = 0

	if current_step_index >= current_tutorial.steps.size():
		# Tutorial complete
		complete_tutorial()
		return

	var step = current_tutorial.steps[current_step_index]
	tutorial_step_changed.emit(current_step_index)

	print("TutorialManager: Step %d - %s" % [step.step_number, step.title])

	# Process the step
	_process_step(step)

## Process a tutorial step
func _process_step(step) -> void:
	print("TutorialManager: Processing step - action: %s, target: %s" % [step.action, step.target])
	
	# Handle action
	match step.action:
		"point":
			# Extract hint from target if it contains "|" separator
			var parts = step.target.split("|", false)
			var target_name = parts[0].strip_edges()
			var hint = parts[1].strip_edges() if parts.size() > 1 else ""
			print("TutorialManager: Calling highlight for target: '%s'" % target_name)
			_highlight_target(target_name, hint)
		"point_and_wait":
			# Combined action: highlight AND wait
			var parts = step.target.split("|", false)
			var target_name = parts[0].strip_edges()
			var hint = parts[1].strip_edges() if parts.size() > 1 else ""
			print("TutorialManager: Calling highlight for target: '%s'" % target_name)
			_highlight_target(target_name, hint)
			is_waiting_for_action = true
			pending_wait_action = step.wait_type
			print("Tutorial waiting for action: %s" % step.wait_type)
			wait_for_action.emit(step.wait_type)
		"wait":
			is_waiting_for_action = true
			pending_wait_action = step.wait_type
			print("Tutorial waiting for action: %s" % step.wait_type)
			wait_for_action.emit(step.wait_type)
		"force":
			force_event.emit(step.target)
		"level_complete":
			# Show final dialogue then complete
			pass
		"appear":
			# Character appears - show dialogue box
			if dialogue_box and dialogue_box.has_method("show_character"):
				dialogue_box.show_character()
		_:
			# Clear any highlight for non-point actions
			_clear_highlight()

	# Show dialogue if there is any
	if step.dialogue.size() > 0:
		_show_dialogue(step)
	elif step.action != "wait":
		# No dialogue and not waiting, auto-advance
		call_deferred("advance_step")

## Show dialogue for current step
func _show_dialogue(step) -> void:
	if current_dialogue_index >= step.dialogue.size():
		# All dialogue shown, check if waiting
		if step.action == "wait" or step.action == "point_and_wait":
			# Stay on this step until action is performed
			return
		else:
			# Move to next step
			advance_step()
		return

	var text = step.dialogue[current_dialogue_index]
	var speaker = step.speaker
	var emotion = step.emotion
	
	# Generate action hint based on wait type
	var action_hint = ""
	if (step.action == "wait" or step.action == "point_and_wait") and not step.wait_type.is_empty():
		action_hint = _get_action_hint(step.wait_type)

	# Emit signal for dialogue
	dialogue_shown.emit(text, speaker, emotion)

	# Update dialogue box with action hint
	if dialogue_box and dialogue_box.has_method("show_dialogue"):
		dialogue_box.call("show_dialogue", text, speaker, emotion, action_hint)

## Continue to next dialogue line or step
func continue_dialogue() -> void:
	if not is_tutorial_active or not current_tutorial:
		return

	if is_waiting_for_action:
		# Can't continue while waiting for action
		return

	var step = current_tutorial.steps[current_step_index]

	current_dialogue_index += 1

	if current_dialogue_index >= step.dialogue.size():
		# All dialogue shown
		if step.action == "wait":
			# Stay on this step
			return
		elif step.action == "level_complete":
			complete_tutorial()
		else:
			advance_step()
	else:
		_show_dialogue(step)

## Called when player performs waited action
func notify_action(action_type: String) -> void:
	if not is_waiting_for_action:
		return

	# Check if action matches what we're waiting for
	if _action_matches(action_type, pending_wait_action):
		print("TutorialManager: Action '%s' completed" % action_type)
		is_waiting_for_action = false
		pending_wait_action = ""
		advance_step()

## Check if performed action matches waited action
func _action_matches(performed: String, waited: String) -> bool:
	# Normalize both strings
	performed = performed.to_lower().strip_edges()
	waited = waited.to_lower().strip_edges()

	print("TutorialManager: Matching action '%s' against '%s'" % [performed, waited])

	# Direct match
	if performed == waited:
		print("TutorialManager: Direct match!")
		return true

	# Common action mappings
	var mappings = {
		"run_code": ["player presses run", "player presses f5", "player runs code", "run", "f5"],
		"open_code_editor": ["player clicks to open code editor", "open editor", "code editor"],
		"type_code": ["player types", "player writes code", "type", "car.go()"],
	}

	for key in mappings:
		if performed == key:
			for match_str in mappings[key]:
				if match_str in waited:
					print("TutorialManager: Matched via mapping!")
					return true
	
	# Check if waited action contains the performed action
	if performed in waited:
		print("TutorialManager: Partial match!")
		return true

	return false

## Complete the tutorial
func complete_tutorial() -> void:
	if not current_tutorial:
		return

	var level_name = ""
	for key in tutorial_data.level_to_tutorial:
		if tutorial_data.level_to_tutorial[key] == current_tutorial.id:
			level_name = key
			break

	# Mark as completed in GameData
	if not level_name.is_empty():
		GameData.mark_tutorial_completed(level_name)

	# Hide dialogue box
	if dialogue_box and dialogue_box.has_method("hide_dialogue"):
		dialogue_box.hide_dialogue()

	dialogue_hidden.emit()
	highlight_cleared.emit()
	tutorial_completed.emit(current_tutorial.id)

	print("TutorialManager: Tutorial %s completed" % current_tutorial.id)

	is_tutorial_active = false
	current_tutorial = null

## Skip tutorial
func skip_tutorial() -> void:
	if not current_tutorial:
		return

	var tutorial_id = current_tutorial.id
	var level_name = ""

	for key in tutorial_data.level_to_tutorial:
		if tutorial_data.level_to_tutorial[key] == tutorial_id:
			level_name = key
			break

	# Mark as completed
	if not level_name.is_empty():
		GameData.mark_tutorial_completed(level_name)

	# Hide UI
	if dialogue_box and dialogue_box.has_method("hide_dialogue"):
		dialogue_box.hide_dialogue()

	dialogue_hidden.emit()
	highlight_cleared.emit()
	tutorial_skipped.emit(tutorial_id)

	print("TutorialManager: Tutorial %s skipped" % tutorial_id)

	is_tutorial_active = false
	current_tutorial = null

## Signal callbacks
func _on_continue_pressed() -> void:
	continue_dialogue()

func _on_skip_pressed() -> void:
	skip_tutorial()

## Get user-friendly action hint from wait type
func _get_action_hint(wait_type: String) -> String:
	wait_type = wait_type.to_lower().strip_edges()
	
	# Map wait actions to user-friendly hints
	var hints = {
		"player presses run": "Click the ▶ Run button (or press F5) to continue",
		"player presses f5": "Press F5 or click the ▶ Run button to continue",
		"run_code": "Click the ▶ Run button to execute your code",
		"player clicks to open code editor": "Click the Code Editor button in the toolbar",
		"open_code_editor": "Click the Code Editor button to open it",
		"player types car.go()": "Type: car.go() in the code editor",
		"player types": "Type car.go() in the code editor",
		"type_code": "Type car.go() in the code editor",
		"player writes code": "Type car.go() in the code editor",
	}
	
	# Try direct match
	if wait_type in hints:
		return hints[wait_type]
	
	# Try partial match
	for key in hints:
		if key in wait_type:
			return hints[key]
	
	# Fallback: clean up the wait type
	return "Complete the action: " + wait_type.capitalize()

## Highlight a target UI element
func _highlight_target(target_name: String, hint: String = "") -> void:
	print("TutorialManager: _highlight_target called, overlay exists: %s" % (highlight_overlay != null))
	if highlight_overlay and highlight_overlay.has_method("highlight_target"):
		print("TutorialManager: Calling highlight_overlay.highlight_target('%s')" % target_name)
		highlight_overlay.highlight_target(target_name, hint)
		highlight_requested.emit(target_name)
	else:
		print("TutorialManager: highlight_overlay not ready or missing method")

## Clear highlight
func _clear_highlight() -> void:
	if highlight_overlay and highlight_overlay.has_method("clear_highlight"):
		highlight_overlay.clear_highlight()
		highlight_cleared.emit()

## Check if a level has a tutorial
func has_tutorial(level_name: String) -> bool:
	if not tutorial_data:
		return false
	return tutorial_data.has_tutorial(level_name)

## Get current step info
func get_current_step():
	if not current_tutorial or current_step_index < 0:
		return null
	if current_step_index >= current_tutorial.steps.size():
		return null
	return current_tutorial.steps[current_step_index]

## Check if tutorial is active
func is_active() -> bool:
	return is_tutorial_active

## Check if waiting for player action
func is_waiting() -> bool:
	return is_waiting_for_action

## Get pending wait action
func get_pending_action() -> String:
	return pending_wait_action
