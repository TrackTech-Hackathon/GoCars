# GoCars IDE/Code Editor Improvements - Claude Code Prompt

## Project Context
GoCars is an educational coding-puzzle game built in Godot that teaches Python programming through traffic simulation scenarios. The game features an in-game IDE/code editor where users write Python-like code to solve puzzles.

## Overview of Required Changes
I need you to implement the following improvements to the GoCars code editor system:

1. **Terminal/Output Panel** - Add a debug console panel below the code editor
2. **Window Snap Feature** - Implement Windows 11-style window snapping for the code editor
3. **Bug Fixes** - Fix Python interpreter logic, syntax highlighting, and loop execution

---

## 1. Terminal/Output Panel Implementation

### Requirements
Create a terminal/output panel that appears **below** the code editor (similar to VS Code's integrated terminal), with these features:

### Visual Design
```
┌─────────────────────────────────────────┐
│  Code Editor                        [_][□][×] │
│─────────────────────────────────────────│
│  1 │ car = Car()                        │
│  2 │ while car.fuel > 0:                │
│  3 │     car.move_forward()             │
│  4 │     print(car.position)            │
│─────────────────────────────────────────│
│  OUTPUT / TERMINAL              [Clear] │
│─────────────────────────────────────────│
│  > Running script...                    │
│  [DEBUG] Car spawned at (0, 0)          │
│  Position: (1, 0)                       │
│  Position: (2, 0)                       │
│  [ERROR] Line 3: Car collided with wall │
└─────────────────────────────────────────┘
```

### Features to Implement

```gdscript
# Create a new scene: res://scenes/ui/terminal_panel.tscn

# Terminal Panel Structure:
# - PanelContainer (TerminalPanel)
#   - VBoxContainer
#     - HBoxContainer (Header)
#       - Label ("OUTPUT")
#       - HSeparator
#       - Button ("Clear")
#       - Button ("Copy All")
#     - HSeparator
#     - ScrollContainer
#       - RichTextLabel (OutputText) - for colored/formatted output

# terminal_panel.gd
extends PanelContainer

signal terminal_cleared

@onready var output_text: RichTextLabel = $VBoxContainer/ScrollContainer/OutputText
@onready var clear_button: Button = $VBoxContainer/HBoxContainer/ClearButton

# Message types for coloring
enum MessageType {
    INFO,      # White/default
    DEBUG,     # Gray
    WARNING,   # Yellow
    ERROR,     # Red
    SUCCESS,   # Green
    PRINT      # Cyan - for user print() statements
}

var auto_scroll: bool = true
var max_lines: int = 500

func _ready() -> void:
    clear_button.pressed.connect(_on_clear_pressed)
    output_text.bbcode_enabled = true
    output_text.scroll_following = true

func print_message(message: String, type: MessageType = MessageType.PRINT) -> void:
    var color: String
    var prefix: String = ""
    
    match type:
        MessageType.INFO:
            color = "#FFFFFF"
        MessageType.DEBUG:
            color = "#888888"
            prefix = "[DEBUG] "
        MessageType.WARNING:
            color = "#FFD700"
            prefix = "[WARNING] "
        MessageType.ERROR:
            color = "#FF4444"
            prefix = "[ERROR] "
        MessageType.SUCCESS:
            color = "#44FF44"
            prefix = "[SUCCESS] "
        MessageType.PRINT:
            color = "#00FFFF"
            prefix = "> "
    
    var timestamp = Time.get_time_string_from_system()
    var formatted = "[color=%s]%s%s[/color]\n" % [color, prefix, message]
    output_text.append_text(formatted)
    
    _trim_output_if_needed()
    
    if auto_scroll:
        await get_tree().process_frame
        output_text.scroll_to_line(output_text.get_line_count())

func print_error(message: String, line_number: int = -1) -> void:
    var line_info = " (Line %d)" % line_number if line_number > 0 else ""
    print_message(message + line_info, MessageType.ERROR)

func print_debug(message: String) -> void:
    print_message(message, MessageType.DEBUG)

func print_warning(message: String) -> void:
    print_message(message, MessageType.WARNING)

func print_success(message: String) -> void:
    print_message(message, MessageType.SUCCESS)

func clear() -> void:
    output_text.clear()
    terminal_cleared.emit()

func _on_clear_pressed() -> void:
    clear()

func _trim_output_if_needed() -> void:
    # Prevent memory issues with too many lines
    var line_count = output_text.get_line_count()
    if line_count > max_lines:
        var text = output_text.get_parsed_text()
        var lines = text.split("\n")
        var trimmed_lines = lines.slice(lines.size() - max_lines)
        output_text.clear()
        output_text.append_text("\n".join(trimmed_lines))
```

### Integration with Code Editor

```gdscript
# In your main code_editor.gd or ide_panel.gd, add:

@onready var terminal_panel: PanelContainer = $TerminalPanel

# Connect the Python interpreter to output here
func _on_code_executed(output: String) -> void:
    terminal_panel.print_message(output)

func _on_interpreter_error(error: String, line: int) -> void:
    terminal_panel.print_error(error, line)

# Resizable splitter between editor and terminal
# Use a VSplitContainer to allow resizing:
# - VSplitContainer
#   - CodeEditorPanel (top)
#   - TerminalPanel (bottom)
```

---

## 2. Windows 11-Style Window Snap Feature

### Requirements
Implement draggable code editor window with Windows 11-style snap zones:
- Drag to left edge → Snap to left half
- Drag to right edge → Snap to right half  
- Drag to top → Maximize
- Drag to corners → Snap to quadrants (optional)
- Double-click title bar → Toggle maximize
- Still fully draggable when not snapped

### Implementation

```gdscript
# window_snap_controller.gd
extends Control

class_name SnapWindowController

signal window_snapped(snap_zone: SnapZone)
signal window_unsnapped
signal window_maximized
signal window_minimized
signal window_restored

enum SnapZone {
    NONE,
    LEFT_HALF,
    RIGHT_HALF,
    TOP_HALF,
    BOTTOM_HALF,
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
    MAXIMIZED
}

# Configuration
@export var snap_threshold: int = 20  # Pixels from edge to trigger snap
@export var snap_preview_alpha: float = 0.3
@export var snap_animation_duration: float = 0.15
@export var enable_corner_snapping: bool = true

# State
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_rect: Rect2  # Store rect before snapping
var current_snap_zone: SnapZone = SnapZone.NONE
var is_maximized: bool = false
var is_minimized: bool = false

# References
var target_window: Control  # The window being controlled
var snap_preview: Panel  # Visual preview of snap zone
var title_bar: Control  # Draggable area

func _ready() -> void:
    _create_snap_preview()

func setup(window: Control, titlebar: Control) -> void:
    target_window = window
    title_bar = titlebar
    
    # Connect title bar signals
    title_bar.gui_input.connect(_on_title_bar_input)

func _create_snap_preview() -> void:
    snap_preview = Panel.new()
    snap_preview.visible = false
    snap_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.3, 0.5, 1.0, snap_preview_alpha)
    style.border_color = Color(0.4, 0.6, 1.0, 0.8)
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    snap_preview.add_theme_stylebox_override("panel", style)
    
    # Add to root so it's always on top
    get_tree().root.call_deferred("add_child", snap_preview)

func _on_title_bar_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb = event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed:
                _start_drag(mb.global_position)
            else:
                _end_drag()
        # Double-click to maximize/restore
        if mb.double_click and mb.button_index == MOUSE_BUTTON_LEFT:
            toggle_maximize()
    
    elif event is InputEventMouseMotion and is_dragging:
        _update_drag(event.global_position)

func _start_drag(mouse_pos: Vector2) -> void:
    is_dragging = true
    drag_offset = mouse_pos - target_window.global_position
    
    # If currently snapped, unsnap first
    if current_snap_zone != SnapZone.NONE:
        _unsnap_window()

func _update_drag(mouse_pos: Vector2) -> void:
    if not is_dragging:
        return
    
    # Move window
    target_window.global_position = mouse_pos - drag_offset
    
    # Check snap zones and show preview
    var detected_zone = _detect_snap_zone(mouse_pos)
    _update_snap_preview(detected_zone)

func _end_drag() -> void:
    is_dragging = false
    snap_preview.visible = false
    
    var mouse_pos = get_viewport().get_mouse_position()
    var snap_zone = _detect_snap_zone(mouse_pos)
    
    if snap_zone != SnapZone.NONE:
        _snap_to_zone(snap_zone)

func _detect_snap_zone(mouse_pos: Vector2) -> SnapZone:
    var viewport_size = get_viewport_rect().size
    var threshold = snap_threshold
    
    var at_left = mouse_pos.x <= threshold
    var at_right = mouse_pos.x >= viewport_size.x - threshold
    var at_top = mouse_pos.y <= threshold
    var at_bottom = mouse_pos.y >= viewport_size.y - threshold
    
    # Corner detection (if enabled)
    if enable_corner_snapping:
        if at_left and at_top:
            return SnapZone.TOP_LEFT
        if at_right and at_top:
            return SnapZone.TOP_RIGHT
        if at_left and at_bottom:
            return SnapZone.BOTTOM_LEFT
        if at_right and at_bottom:
            return SnapZone.BOTTOM_RIGHT
    
    # Edge detection
    if at_left:
        return SnapZone.LEFT_HALF
    if at_right:
        return SnapZone.RIGHT_HALF
    if at_top:
        return SnapZone.MAXIMIZED
    
    return SnapZone.NONE

func _get_snap_rect(zone: SnapZone) -> Rect2:
    var viewport_size = get_viewport_rect().size
    var padding = 4  # Small gap from edges
    
    match zone:
        SnapZone.LEFT_HALF:
            return Rect2(padding, padding, viewport_size.x / 2 - padding * 1.5, viewport_size.y - padding * 2)
        SnapZone.RIGHT_HALF:
            return Rect2(viewport_size.x / 2 + padding * 0.5, padding, viewport_size.x / 2 - padding * 1.5, viewport_size.y - padding * 2)
        SnapZone.TOP_HALF:
            return Rect2(padding, padding, viewport_size.x - padding * 2, viewport_size.y / 2 - padding * 1.5)
        SnapZone.BOTTOM_HALF:
            return Rect2(padding, viewport_size.y / 2 + padding * 0.5, viewport_size.x - padding * 2, viewport_size.y / 2 - padding * 1.5)
        SnapZone.TOP_LEFT:
            return Rect2(padding, padding, viewport_size.x / 2 - padding * 1.5, viewport_size.y / 2 - padding * 1.5)
        SnapZone.TOP_RIGHT:
            return Rect2(viewport_size.x / 2 + padding * 0.5, padding, viewport_size.x / 2 - padding * 1.5, viewport_size.y / 2 - padding * 1.5)
        SnapZone.BOTTOM_LEFT:
            return Rect2(padding, viewport_size.y / 2 + padding * 0.5, viewport_size.x / 2 - padding * 1.5, viewport_size.y / 2 - padding * 1.5)
        SnapZone.BOTTOM_RIGHT:
            return Rect2(viewport_size.x / 2 + padding * 0.5, viewport_size.y / 2 + padding * 0.5, viewport_size.x / 2 - padding * 1.5, viewport_size.y / 2 - padding * 1.5)
        SnapZone.MAXIMIZED:
            return Rect2(padding, padding, viewport_size.x - padding * 2, viewport_size.y - padding * 2)
    
    return Rect2()

func _update_snap_preview(zone: SnapZone) -> void:
    if zone == SnapZone.NONE:
        snap_preview.visible = false
        return
    
    var target_rect = _get_snap_rect(zone)
    snap_preview.visible = true
    snap_preview.global_position = target_rect.position
    snap_preview.size = target_rect.size

func _snap_to_zone(zone: SnapZone) -> void:
    if zone == SnapZone.NONE:
        return
    
    # Store original rect for restoration
    if current_snap_zone == SnapZone.NONE:
        original_rect = Rect2(target_window.global_position, target_window.size)
    
    current_snap_zone = zone
    var target_rect = _get_snap_rect(zone)
    
    # Animate to snap position
    var tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(target_window, "global_position", target_rect.position, snap_animation_duration)
    tween.tween_property(target_window, "size", target_rect.size, snap_animation_duration)
    
    is_maximized = (zone == SnapZone.MAXIMIZED)
    window_snapped.emit(zone)

func _unsnap_window() -> void:
    current_snap_zone = SnapZone.NONE
    is_maximized = false
    
    # Restore to floating size but keep at current position
    var restore_size = original_rect.size if original_rect.size != Vector2.ZERO else Vector2(600, 400)
    target_window.size = restore_size
    
    window_unsnapped.emit()

func toggle_maximize() -> void:
    if is_maximized:
        restore()
    else:
        maximize()

func maximize() -> void:
    if not is_maximized:
        original_rect = Rect2(target_window.global_position, target_window.size)
    _snap_to_zone(SnapZone.MAXIMIZED)
    window_maximized.emit()

func restore() -> void:
    if original_rect.size == Vector2.ZERO:
        original_rect = Rect2(Vector2(100, 100), Vector2(600, 400))
    
    var tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(target_window, "global_position", original_rect.position, snap_animation_duration)
    tween.tween_property(target_window, "size", original_rect.size, snap_animation_duration)
    
    current_snap_zone = SnapZone.NONE
    is_maximized = false
    window_restored.emit()

func minimize() -> void:
    # You can implement minimize to taskbar/dock here
    is_minimized = true
    target_window.visible = false
    window_minimized.emit()

func show_window() -> void:
    is_minimized = false
    target_window.visible = true
```

### Window Title Bar with Buttons

```gdscript
# code_editor_window.gd
extends PanelContainer

@onready var title_bar: HBoxContainer = $VBoxContainer/TitleBar
@onready var minimize_btn: Button = $VBoxContainer/TitleBar/MinimizeButton
@onready var maximize_btn: Button = $VBoxContainer/TitleBar/MaximizeButton
@onready var close_btn: Button = $VBoxContainer/TitleBar/CloseButton
@onready var code_editor: CodeEdit = $VBoxContainer/VSplitContainer/CodeEditor
@onready var terminal: PanelContainer = $VBoxContainer/VSplitContainer/TerminalPanel

var snap_controller: SnapWindowController

func _ready() -> void:
    # Setup snap controller
    snap_controller = SnapWindowController.new()
    add_child(snap_controller)
    snap_controller.setup(self, title_bar)
    
    # Connect buttons
    minimize_btn.pressed.connect(_on_minimize_pressed)
    maximize_btn.pressed.connect(_on_maximize_pressed)
    close_btn.pressed.connect(_on_close_pressed)
    
    # Update maximize button icon based on state
    snap_controller.window_maximized.connect(_on_window_maximized)
    snap_controller.window_restored.connect(_on_window_restored)

func _on_minimize_pressed() -> void:
    snap_controller.minimize()

func _on_maximize_pressed() -> void:
    snap_controller.toggle_maximize()

func _on_close_pressed() -> void:
    visible = false
    # Or emit signal: window_closed.emit()

func _on_window_maximized() -> void:
    # Change icon to restore icon
    maximize_btn.icon = preload("res://assets/icons/restore.svg")
    maximize_btn.tooltip_text = "Restore"

func _on_window_restored() -> void:
    # Change icon back to maximize icon
    maximize_btn.icon = preload("res://assets/icons/maximize.svg")
    maximize_btn.tooltip_text = "Maximize"
```

---

## 3. Python Interpreter Bug Fixes

### Critical Issues to Fix

#### A. While Loop Not Executing Properly

The issue described: "while loop isn't working properly, it's just repeating the second line in the loop but not looping with the first one"

**Likely Causes:**
1. Loop body not being tracked correctly
2. Indentation parsing issues
3. Statement execution order problems
4. Variable scope not persisting between iterations

**Fix Implementation:**

```gdscript
# python_interpreter.gd (or wherever your interpreter lives)

# PROBLEM: Loop body detection/execution
# The interpreter needs to properly:
# 1. Identify the complete loop body (all indented lines)
# 2. Execute ALL statements in the body each iteration
# 3. Re-evaluate the condition after EACH complete iteration

class WhileLoop:
    var condition_expression: String
    var body_statements: Array[String]  # ALL lines in the loop body
    var start_line: int
    var end_line: int

func parse_while_loop(lines: Array[String], start_index: int) -> WhileLoop:
    var loop = WhileLoop.new()
    var condition_line = lines[start_index]
    
    # Extract condition from "while condition:"
    var regex = RegEx.new()
    regex.compile(r"while\s+(.+):")
    var match = regex.search(condition_line)
    if match:
        loop.condition_expression = match.get_string(1)
    
    loop.start_line = start_index
    loop.body_statements = []
    
    # Get the indentation level of the while statement
    var while_indent = _get_indentation(condition_line)
    var body_indent = -1
    
    # Parse ALL body statements
    var i = start_index + 1
    while i < lines.size():
        var line = lines[i]
        var current_indent = _get_indentation(line)
        
        # Skip empty lines
        if line.strip_edges().is_empty():
            i += 1
            continue
        
        # First non-empty line after while determines body indent
        if body_indent == -1:
            body_indent = current_indent
        
        # If we've returned to while's indent level or less, loop body is done
        if current_indent <= while_indent and not line.strip_edges().is_empty():
            break
        
        # This line is part of the loop body
        loop.body_statements.append(line.strip_edges())
        i += 1
    
    loop.end_line = i - 1
    return loop

func execute_while_loop(loop: WhileLoop, variables: Dictionary) -> void:
    var max_iterations = 10000  # Safety limit
    var iteration_count = 0
    
    terminal.print_debug("Entering while loop: %s" % loop.condition_expression)
    
    while _evaluate_condition(loop.condition_expression, variables):
        iteration_count += 1
        
        if iteration_count > max_iterations:
            terminal.print_error("Infinite loop detected! Loop exceeded %d iterations." % max_iterations)
            break
        
        terminal.print_debug("Loop iteration %d" % iteration_count)
        
        # Execute EVERY statement in the body
        for statement in loop.body_statements:
            terminal.print_debug("  Executing: %s" % statement)
            _execute_statement(statement, variables)
            
            # Check for break/continue
            if _break_requested:
                terminal.print_debug("Break requested, exiting loop")
                _break_requested = false
                return
            if _continue_requested:
                terminal.print_debug("Continue requested, next iteration")
                _continue_requested = false
                break  # Break inner for loop, continue outer while
    
    terminal.print_debug("Exited while loop after %d iterations" % iteration_count)

func _get_indentation(line: String) -> int:
    var count = 0
    for c in line:
        if c == ' ':
            count += 1
        elif c == '\t':
            count += 4  # Treat tab as 4 spaces
        else:
            break
    return count

func _evaluate_condition(condition: String, variables: Dictionary) -> bool:
    # Parse and evaluate the condition
    # Handle comparisons: ==, !=, <, >, <=, >=
    # Handle boolean: and, or, not
    # Handle attribute access: car.fuel, car.position.x
    
    # Example for "car.fuel > 0"
    var parts = _tokenize_condition(condition)
    return _eval_expression(parts, variables)
```

#### B. Syntax Highlighting Issues

```gdscript
# code_editor_highlighter.gd

extends SyntaxHighlighter

# Python keywords
const KEYWORDS = [
    "and", "as", "assert", "async", "await", "break", "class", "continue",
    "def", "del", "elif", "else", "except", "finally", "for", "from",
    "global", "if", "import", "in", "is", "lambda", "nonlocal", "not",
    "or", "pass", "raise", "return", "try", "while", "with", "yield",
    "True", "False", "None"
]

# GoCars-specific keywords/functions
const GOCARS_FUNCTIONS = [
    "move_forward", "turn_left", "turn_right", "stop", "accelerate",
    "brake", "honk", "signal_left", "signal_right", "check_traffic",
    "get_position", "get_speed", "get_fuel", "refuel"
]

const GOCARS_CLASSES = [
    "Car", "TrafficLight", "Road", "Intersection", "Pedestrian"
]

# Colors
var color_keyword = Color(0.8, 0.4, 0.9)      # Purple
var color_string = Color(0.6, 0.9, 0.6)        # Green
var color_number = Color(0.9, 0.7, 0.4)        # Orange
var color_comment = Color(0.5, 0.5, 0.5)       # Gray
var color_function = Color(0.4, 0.7, 1.0)      # Blue
var color_class = Color(0.4, 0.9, 0.9)         # Cyan
var color_gocars = Color(1.0, 0.8, 0.2)        # Yellow/Gold
var color_operator = Color(0.9, 0.9, 0.9)      # White
var color_error = Color(1.0, 0.3, 0.3)         # Red

func _get_line_syntax_highlighting(line: int) -> Dictionary:
    var text = get_text_edit().get_line(line)
    var coloring = {}
    
    var i = 0
    while i < text.length():
        var c = text[i]
        
        # Skip whitespace
        if c in [' ', '\t']:
            i += 1
            continue
        
        # Comments
        if c == '#':
            coloring[i] = {"color": color_comment}
            break  # Rest of line is comment
        
        # Strings
        if c in ['"', "'"]:
            var string_char = c
            var start = i
            i += 1
            # Handle triple quotes
            if i + 1 < text.length() and text[i] == string_char and text[i + 1] == string_char:
                i += 2
                # Find closing triple quote
                while i + 2 < text.length():
                    if text[i] == string_char and text[i + 1] == string_char and text[i + 2] == string_char:
                        i += 3
                        break
                    i += 1
            else:
                # Find closing quote
                while i < text.length() and text[i] != string_char:
                    if text[i] == '\\':  # Escape character
                        i += 1
                    i += 1
                i += 1  # Include closing quote
            
            coloring[start] = {"color": color_string}
            continue
        
        # Numbers
        if c.is_valid_int() or (c == '.' and i + 1 < text.length() and text[i + 1].is_valid_int()):
            var start = i
            while i < text.length() and (text[i].is_valid_int() or text[i] == '.'):
                i += 1
            coloring[start] = {"color": color_number}
            continue
        
        # Identifiers and keywords
        if c.is_valid_identifier() or c == '_':
            var start = i
            var word = ""
            while i < text.length() and (text[i].is_valid_identifier() or text[i] == '_' or text[i].is_valid_int()):
                word += text[i]
                i += 1
            
            # Determine color based on word type
            if word in KEYWORDS:
                coloring[start] = {"color": color_keyword}
            elif word in GOCARS_CLASSES:
                coloring[start] = {"color": color_class}
            elif word in GOCARS_FUNCTIONS:
                coloring[start] = {"color": color_gocars}
            elif i < text.length() and text[i] == '(':
                coloring[start] = {"color": color_function}
            # else: default color (no entry needed)
            continue
        
        # Operators
        if c in ['+', '-', '*', '/', '%', '=', '<', '>', '!', '&', '|', '^', '~']:
            coloring[i] = {"color": color_operator}
            i += 1
            continue
        
        i += 1
    
    return coloring
```

#### C. General Interpreter Fixes

```gdscript
# Ensure proper variable scoping and persistence

class PythonInterpreter:
    var global_variables: Dictionary = {}
    var local_variables: Dictionary = {}
    var current_scope: Dictionary = {}
    var terminal: TerminalPanel
    
    # Track control flow
    var _break_requested: bool = false
    var _continue_requested: bool = false
    var _return_requested: bool = false
    var _return_value: Variant = null
    
    func execute(code: String) -> void:
        var lines = code.split("\n")
        var line_number = 0
        
        terminal.print_message("Running script...", TerminalPanel.MessageType.INFO)
        
        while line_number < lines.size():
            var line = lines[line_number].strip_edges()
            
            # Skip empty lines and comments
            if line.is_empty() or line.begins_with("#"):
                line_number += 1
                continue
            
            # Handle different statement types
            if line.begins_with("while "):
                var loop = parse_while_loop(lines, line_number)
                execute_while_loop(loop, current_scope)
                line_number = loop.end_line + 1
            elif line.begins_with("for "):
                var loop = parse_for_loop(lines, line_number)
                execute_for_loop(loop, current_scope)
                line_number = loop.end_line + 1
            elif line.begins_with("if "):
                var conditional = parse_if_block(lines, line_number)
                execute_if_block(conditional, current_scope)
                line_number = conditional.end_line + 1
            elif line.begins_with("def "):
                var func_def = parse_function(lines, line_number)
                register_function(func_def)
                line_number = func_def.end_line + 1
            elif line.begins_with("print("):
                execute_print(line, line_number)
                line_number += 1
            else:
                # Regular statement (assignment, expression, function call)
                execute_statement(line, line_number)
                line_number += 1
        
        terminal.print_success("Script completed")
    
    func execute_print(line: String, line_number: int) -> void:
        # Extract content between print( and )
        var regex = RegEx.new()
        regex.compile(r'print\s*\((.*)\)\s*$')
        var match = regex.search(line)
        
        if match:
            var content = match.get_string(1)
            var result = evaluate_expression(content)
            terminal.print_message(str(result))
        else:
            terminal.print_error("Invalid print statement", line_number)
    
    func evaluate_expression(expr: String) -> Variant:
        expr = expr.strip_edges()
        
        # Handle string literals
        if (expr.begins_with('"') and expr.ends_with('"')) or \
           (expr.begins_with("'") and expr.ends_with("'")):
            return expr.substr(1, expr.length() - 2)
        
        # Handle numbers
        if expr.is_valid_float():
            return float(expr)
        if expr.is_valid_int():
            return int(expr)
        
        # Handle boolean
        if expr == "True":
            return true
        if expr == "False":
            return false
        if expr == "None":
            return null
        
        # Handle variable lookup
        if current_scope.has(expr):
            return current_scope[expr]
        if global_variables.has(expr):
            return global_variables[expr]
        
        # Handle attribute access (e.g., car.fuel)
        if "." in expr:
            return evaluate_attribute_access(expr)
        
        # Handle arithmetic expressions
        if _contains_operator(expr):
            return evaluate_arithmetic(expr)
        
        # Handle function calls
        if "(" in expr:
            return evaluate_function_call(expr)
        
        terminal.print_error("Unknown expression: %s" % expr)
        return null
    
    func evaluate_attribute_access(expr: String) -> Variant:
        var parts = expr.split(".")
        var obj = current_scope.get(parts[0], global_variables.get(parts[0]))
        
        if obj == null:
            terminal.print_error("Undefined variable: %s" % parts[0])
            return null
        
        for i in range(1, parts.size()):
            var attr = parts[i]
            # Handle method calls
            if "(" in attr:
                var method_name = attr.split("(")[0]
                var args_str = attr.split("(")[1].trim_suffix(")")
                obj = _call_method(obj, method_name, _parse_args(args_str))
            else:
                obj = _get_attribute(obj, attr)
        
        return obj
```

---

## 4. UI/UX Improvements for Advanced Features

### Issues to Address
- Inconvenient advanced feature UI
- Unclear button purposes
- Poor layout/spacing
- Missing visual feedback

### Recommendations

```gdscript
# General UI improvements for the code editor

# 1. Add tooltips to all buttons
minimize_btn.tooltip_text = "Minimize window (Ctrl+M)"
maximize_btn.tooltip_text = "Maximize/Restore window (F11)"
close_btn.tooltip_text = "Close editor (Escape)"
run_btn.tooltip_text = "Run code (F5)"
stop_btn.tooltip_text = "Stop execution (Shift+F5)"
clear_btn.tooltip_text = "Clear terminal (Ctrl+L)"

# 2. Add keyboard shortcuts
func _input(event: InputEvent) -> void:
    if not visible:
        return
    
    if event.is_action_pressed("ui_cancel"):
        visible = false
    elif event.is_action_pressed("run_code"):  # Map F5 to this
        _run_code()
    elif event.is_action_pressed("toggle_maximize"):  # Map F11
        snap_controller.toggle_maximize()
    elif event.is_action_pressed("clear_terminal"):  # Map Ctrl+L
        terminal.clear()

# 3. Visual feedback for running state
func _run_code() -> void:
    run_btn.disabled = true
    stop_btn.disabled = false
    
    # Add pulsing animation to indicate running
    var tween = create_tween()
    tween.set_loops()
    tween.tween_property(run_btn, "modulate", Color(0.5, 1.0, 0.5), 0.5)
    tween.tween_property(run_btn, "modulate", Color.WHITE, 0.5)
    
    # ... run code ...
    
    tween.kill()
    run_btn.modulate = Color.WHITE
    run_btn.disabled = false
    stop_btn.disabled = true

# 4. Better error highlighting in code editor
func highlight_error_line(line_number: int) -> void:
    code_editor.set_line_background_color(line_number, Color(1.0, 0.2, 0.2, 0.3))
    
    # Auto-scroll to error
    code_editor.set_caret_line(line_number)
    code_editor.center_viewport_to_caret()

func clear_error_highlights() -> void:
    for i in range(code_editor.get_line_count()):
        code_editor.set_line_background_color(i, Color.TRANSPARENT)

# 5. Add line execution indicator (shows current executing line)
var execution_marker_line: int = -1

func set_execution_marker(line: int) -> void:
    # Clear previous marker
    if execution_marker_line >= 0:
        code_editor.set_line_gutter_icon(execution_marker_line, 0, null)
    
    execution_marker_line = line
    if line >= 0:
        code_editor.set_line_gutter_icon(line, 0, preload("res://assets/icons/arrow_right.svg"))
```

---

## 5. Scene Structure Reference

Here's the recommended scene tree structure:

```
CodeEditorWindow (PanelContainer)
├── SnapWindowController (custom script)
├── VBoxContainer
│   ├── TitleBar (HBoxContainer)
│   │   ├── DragHandle (Control) - invisible, for dragging
│   │   ├── WindowTitle (Label) - "GoCars Code Editor"
│   │   ├── HSpacer (Control) - expand
│   │   ├── MinimizeButton (Button) - icon: minimize
│   │   ├── MaximizeButton (Button) - icon: maximize/restore
│   │   └── CloseButton (Button) - icon: close
│   │
│   ├── ToolBar (HBoxContainer)
│   │   ├── RunButton (Button) - icon: play, tooltip: "Run (F5)"
│   │   ├── StopButton (Button) - icon: stop, tooltip: "Stop (Shift+F5)"
│   │   ├── VSeparator
│   │   ├── StepButton (Button) - icon: step, tooltip: "Step (F10)"
│   │   ├── VSeparator
│   │   ├── UndoButton (Button)
│   │   ├── RedoButton (Button)
│   │   └── HSpacer
│   │
│   └── VSplitContainer (split_offset: -150)
│       ├── CodeEditorPanel (PanelContainer)
│       │   └── CodeEdit
│       │       ├── SyntaxHighlighter (custom)
│       │       └── GutterConfig (line numbers, breakpoints, execution marker)
│       │
│       └── TerminalPanel (PanelContainer)
│           └── VBoxContainer
│               ├── TerminalHeader (HBoxContainer)
│               │   ├── TabBar (OUTPUT | PROBLEMS | DEBUG CONSOLE)
│               │   ├── HSpacer
│               │   ├── ClearButton
│               │   └── CopyButton
│               ├── HSeparator
│               └── ScrollContainer
│                   └── OutputText (RichTextLabel)
```

---

## Summary of Tasks

1. **Create Terminal Panel** (`terminal_panel.tscn` + `terminal_panel.gd`)
   - Rich text output with color-coded messages
   - Clear and copy buttons
   - Auto-scroll functionality
   - Message type support (debug, error, warning, etc.)

2. **Implement Window Snapping** (`snap_window_controller.gd`)
   - Snap zones: left/right half, maximize, corners
   - Visual preview when dragging near edges
   - Smooth animations
   - Window buttons: minimize, maximize/restore, close

3. **Fix Python Interpreter** (in your interpreter script)
   - Fix while loop body detection and execution
   - Ensure ALL statements in loop body execute each iteration
   - Fix variable scoping
   - Improve error reporting with line numbers

4. **Improve Syntax Highlighting**
   - Proper Python keyword detection
   - GoCars-specific function/class highlighting
   - String and comment handling
   - Error underlines

5. **UI/UX Polish**
   - Add tooltips everywhere
   - Implement keyboard shortcuts
   - Add visual feedback for running state
   - Error line highlighting
   - Execution marker for current line

---

## Notes for Claude Code

- The project is in **Godot 4.x** (use GDScript 2.0 syntax)
- The game teaches **Python** syntax, so the interpreter needs to handle Python-like code
- Focus on making the IDE feel like a **real IDE** (VS Code-like experience)
- All colors should be customizable/themeable
- Consider adding a settings panel for editor preferences later

Please examine the existing codebase first to understand the current implementation, then apply these fixes and improvements while maintaining compatibility with existing features.
