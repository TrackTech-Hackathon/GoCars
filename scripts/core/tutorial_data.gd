## Tutorial Data Parser for GoCars
## Parses tutorial_script.md and provides structured tutorial data
## Author: Claude Code
## Date: January 2026

extends RefCounted
class_name TutorialData

## Tutorial step structure
class TutorialStep:
	var step_number: int = 0
	var title: String = ""
	var speaker: String = "Maki"
	var emotion: String = "normal"  # normal, talking, pointing, happy
	var dialogue: Array[String] = []  # Lines of dialogue
	var action: String = ""  # point, wait, force, level_complete
	var target: String = ""  # Target for point/wait actions
	var wait_type: String = ""  # Type of wait action

	func _to_string() -> String:
		return "Step %d: %s (%s)" % [step_number, title, action if action else "dialogue"]

## Tutorial level structure
class TutorialLevel:
	var id: String = ""  # T1, T2, T3, etc.
	var title: String = ""
	var objective: String = ""
	var steps: Array[TutorialStep] = []

	func _to_string() -> String:
		return "%s: %s (%d steps)" % [id, title, steps.size()]

## Parsed tutorial data
var tutorials: Dictionary = {}  # id -> TutorialLevel

## Level filename to tutorial ID mapping
var level_to_tutorial: Dictionary = {
	"01 Level 1": "T1",
	"01 Level 2": "T2",
	"01 Level 3": "T3",
	"01 Level 4": "T4",
	"01 Level 5": "T5"
}

func _init() -> void:
	_load_tutorial_script()

## Load and parse the tutorial script
func _load_tutorial_script() -> void:
	var file_path = "res://docs/tutorial_script.md"
	var file = FileAccess.open(file_path, FileAccess.READ)

	if not file:
		push_error("TutorialData: Could not open tutorial_script.md")
		return

	var content = file.get_as_text()
	file.close()

	_parse_content(content)
	print("TutorialData: Loaded %d tutorials" % tutorials.size())

## Parse the markdown content
func _parse_content(content: String) -> void:
	# Split by tutorial sections
	var tutorial_sections = content.split("## TUTORIAL ")

	for i in range(1, tutorial_sections.size()):
		var section = tutorial_sections[i]
		var tutorial = _parse_tutorial_section(section)
		if tutorial:
			tutorials[tutorial.id] = tutorial
			print("TutorialData: Parsed %s with %d steps" % [tutorial.id, tutorial.steps.size()])

## Parse a single tutorial section
func _parse_tutorial_section(section: String) -> TutorialLevel:
	var tutorial = TutorialLevel.new()

	# Get first line for ID and title
	var lines = section.split("\n")
	if lines.is_empty():
		return null

	# Parse ID and title: '1: "Welcome to GoCars!"'
	var first_line = lines[0].strip_edges()
	var colon_pos = first_line.find(":")
	if colon_pos == -1:
		return null

	var id_num = first_line.substr(0, colon_pos).strip_edges()
	tutorial.id = "T" + id_num

	# Extract title from quotes
	var quote_start = first_line.find('"')
	var quote_end = first_line.rfind('"')
	if quote_start != -1 and quote_end > quote_start:
		tutorial.title = first_line.substr(quote_start + 1, quote_end - quote_start - 1)

	# Find objective
	for line in lines:
		if line.begins_with("**Objective:**"):
			tutorial.objective = line.replace("**Objective:**", "").strip_edges()
			break

	# Find script section between ``` markers
	var script_marker = "### Script:"
	var script_start_pos = section.find(script_marker)
	
	if script_start_pos != -1:
		# Find the opening ``` after "### Script:"
		var code_block_start = section.find("```", script_start_pos)
		if code_block_start != -1:
			# Skip the ``` line itself
			var content_start = section.find("\n", code_block_start) + 1
			# Find the closing ```
			var code_block_end = section.find("```", content_start)
			if code_block_end != -1:
				var script_content = section.substr(content_start, code_block_end - content_start)
				# Parse the script content
				tutorial.steps = _parse_script_steps(script_content)

	return tutorial

## Parse script steps from content
func _parse_script_steps(content: String) -> Array[TutorialStep]:
	var steps: Array[TutorialStep] = []
	var lines = content.split("\n")

	var current_step: TutorialStep = null

	for line in lines:
		line = line.strip_edges()
		if line.is_empty():
			continue

		# Check for new step
		if line.begins_with("STEP "):
			# Save previous step
			if current_step:
				steps.append(current_step)

			# Create new step
			current_step = TutorialStep.new()

			# Parse "STEP N: Title"
			var colon_pos = line.find(":")
			if colon_pos != -1:
				var step_part = line.substr(5, colon_pos - 5).strip_edges()
				current_step.step_number = step_part.to_int()
				current_step.title = line.substr(colon_pos + 1).strip_edges()

			continue

		if not current_step:
			continue

		# Check for actions in brackets
		if line.begins_with("[") and line.ends_with("]"):
			var action_content = line.substr(1, line.length() - 2)
			_parse_action(current_step, action_content)
			continue

		# Check for dialogue in quotes
		if line.begins_with('"') and line.ends_with('"'):
			var dialogue_text = line.substr(1, line.length() - 2)
			current_step.dialogue.append(dialogue_text)

			# Determine emotion based on content
			current_step.emotion = _determine_emotion(dialogue_text, current_step.action)

	# Don't forget the last step
	if current_step:
		steps.append(current_step)

	return steps

## Parse action from bracket content
func _parse_action(step: TutorialStep, action_content: String) -> void:
	if action_content.begins_with("Arrow points"):
		step.action = "point"
		step.emotion = "pointing"
		# Extract target - everything after "to "
		var to_pos = action_content.find(" to ")
		if to_pos != -1:
			step.target = action_content.substr(to_pos + 4).strip_edges()
			print("TutorialData: Point action - target: '%s'" % step.target)

	elif action_content.begins_with("WAIT:"):
		# If already pointing, combine actions as "point_and_wait"
		if step.action == "point":
			step.action = "point_and_wait"
		else:
			step.action = "wait"
		step.wait_type = action_content.substr(5).strip_edges()
		# Don't overwrite target if already set from point action
		if step.target.is_empty():
			step.target = step.wait_type

	elif action_content.begins_with("FORCE"):
		step.action = "force"
		step.target = action_content.replace("FORCE:", "").replace("FORCED", "").strip_edges()

	elif action_content == "Character appears":
		step.action = "appear"
		step.emotion = "normal"

	elif action_content == "LEVEL COMPLETE" or action_content.begins_with("LEVEL COMPLETE"):
		step.action = "level_complete"
		step.emotion = "happy"

	elif action_content.begins_with("Car"):
		step.action = "car_event"
		step.target = action_content

## Determine emotion based on dialogue content
func _determine_emotion(text: String, action: String) -> String:
	# If already pointing, keep pointing
	if action == "point":
		return "pointing"
	
	# Check for level complete - always happy
	if action == "level_complete":
		return "happy"

	# Check for happy indicators (success, praise, encouragement)
	var happy_words = ["AMAZING", "CONGRATULATIONS", "EXCELLENT", "Perfect", "GREAT", "Good luck", "Well done", "Nice", "Awesome", "correct", "succeeded", "success"]
	for word in happy_words:
		if word.to_lower() in text.to_lower():
			return "happy"

	# Check for warning/concerned indicators
	var concern_words = ["CRASH", "VIOLATION", "lost", "GAME OVER", "careful", "Uh oh", "Oh no", "mistake", "error", "wrong"]
	for word in concern_words:
		if word.to_lower() in text.to_lower():
			return "normal"  # Use normal with concerned text

	# Default to talking for most dialogue
	return "talking"

## Get tutorial for a level filename
func get_tutorial_for_level(level_name: String) -> TutorialLevel:
	var tutorial_id = level_to_tutorial.get(level_name, "")
	if tutorial_id.is_empty():
		return null
	return tutorials.get(tutorial_id, null)

## Get tutorial by ID
func get_tutorial(id: String) -> TutorialLevel:
	return tutorials.get(id, null)

## Check if a level has a tutorial
func has_tutorial(level_name: String) -> bool:
	return level_name in level_to_tutorial

## Get all tutorial IDs
func get_tutorial_ids() -> Array:
	return tutorials.keys()
