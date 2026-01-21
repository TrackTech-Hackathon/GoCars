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
	window_title = "Documentation"
	min_size = Vector2(500, 400)
	default_size = Vector2(600, 500)
	default_position = Vector2(300, 100)

func _ready() -> void:
	super._ready()
	_setup_documentation()

func _setup_documentation() -> void:
	var content = get_content_container()

	# Scroll container
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll_container)

	# Rich text label
	rich_text = RichTextLabel.new()
	rich_text.name = "RichTextLabel"
	rich_text.bbcode_enabled = true
	rich_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich_text.fit_content = true
	scroll_container.add_child(rich_text)

	# Set documentation content
	rich_text.text = _get_documentation_text()

func _get_documentation_text() -> String:
	return """[b][color=cyan]GoCars - Python Programming Guide[/color][/b]

[b]How to Play:[/b]
Write Python code to control vehicles and complete levels. Your code runs on all spawned cars automatically!

[b][color=yellow]═══ Car Commands ═══[/color][/b]

[b]Movement:[/b]
  [color=lightgreen]car.go()[/color]           - Start moving forward
  [color=lightgreen]car.stop()[/color]         - Stop immediately
  [color=lightgreen]car.turn("left")[/color]   - Turn 90° left
  [color=lightgreen]car.turn("right")[/color]  - Turn 90° right

[b]Road Detection:[/b]
  [color=lightgreen]car.front_road()[/color]   - Road ahead? → True/False
  [color=lightgreen]car.left_road()[/color]    - Road to left? → True/False
  [color=lightgreen]car.right_road()[/color]   - Road to right? → True/False

[b]Obstacle Detection:[/b]
  [color=lightgreen]car.front_car()[/color]    - Any car ahead? → True/False
  [color=lightgreen]car.front_crash()[/color]  - Crashed car ahead? → True/False

[b]State Queries:[/b]
  [color=lightgreen]car.at_end()[/color]       - At destination? → True/False
  [color=lightgreen]car.at_cross()[/color]     - At intersection? → True/False
  [color=lightgreen]car.at_red()[/color]       - Near red light? → True/False


[b][color=yellow]═══ Stoplight Commands ═══[/color][/b]

[b]Control:[/b]
  [color=lightgreen]stoplight.red()[/color]    - Set to red
  [color=lightgreen]stoplight.green()[/color]  - Set to green

[b]State:[/b]
  [color=lightgreen]stoplight.is_red()[/color]    - Is red? → True/False
  [color=lightgreen]stoplight.is_green()[/color]  - Is green? → True/False


[b][color=yellow]═══ Python Syntax ═══[/color][/b]

[b]If Statements:[/b]
  [color=gray]if car.front_road():
      car.go()
  elif car.left_road():
	  car.turn("left")
  else:
      car.stop()[/color]

[b]While Loops:[/b]
  [color=gray]while not car.at_end():
      if car.front_road():
          car.go()[/color]

[b]Functions:[/b]
  [color=gray]def smart_turn(direction):
      car.turn(direction)
      car.go()

  smart_turn("left")[/color]


[b][color=yellow]═══ Import System ═══[/color][/b]

Create helper modules to organize your code:

[b]1. Create a module file (helpers.py):[/b]
  [color=gray]def avoid_crash():
      if car.front_crash():
          if car.left_road():
			  car.turn("left")
          elif car.right_road():
			  car.turn("right")

  def navigate():
      if car.front_road():
          car.go()
      else:
          car.stop()[/color]

[b]2. Import functions in main.py:[/b]
  [color=gray]from helpers import avoid_crash, navigate

  while not car.at_end():
      avoid_crash()
      navigate()[/color]

[b]3. Nested modules:[/b]
  [color=gray]from modules.navigation import find_path[/color]


[b][color=yellow]═══ Tips & Tricks ═══[/color][/b]

• [b]Red lights don't auto-stop![/b] You must check stoplight state
• [b]Crashed cars stay on map[/b] as obstacles - navigate around them
• [b]Your code runs on ALL cars[/b] - make it handle multiple scenarios
• [b]Use functions[/b] to break complex logic into reusable pieces
• [b]Organize with modules[/b] for cleaner, more maintainable code
• [b]Test edge cases:[/b] dead ends, multiple obstacles, timing


[b][color=yellow]═══ Example: Complete Solution ═══[/color][/b]

[color=gray]def check_stoplight():
    if stoplight.is_red():
        car.stop()
        return False
    return True

def navigate_safely():
    if car.front_crash():
        if car.left_road():
			car.turn("left")
        elif car.right_road():
			car.turn("right")
        else:
            car.stop()
    elif car.front_road() and check_stoplight():
        car.go()
    elif car.left_road():
		car.turn("left")
    elif car.right_road():
		car.turn("right")
    else:
        car.stop()

while not car.at_end():
    navigate_safely()[/color]


[b][color=cyan]Press Ctrl+2 to toggle this window[/color][/b]
"""
