# Stoplight System Redesign - Implementation Guide

## Overview
The stoplight system has been redesigned to run Python-like code. Each stoplight now has its own script that executes in a loop, controlling its state and timing.

## Architecture

### 1. Stoplight Code Execution
- Each stoplight stores code in the `stoplight_code` export variable
- Code runs in a separate `PythonInterpreter` instance
- The interpreter loops continuously until the level ends
- `wait()` pauses execution for a specified duration

### 2. Direction-Based State Management
Stoplights now support directional state:
```gdscript
_directional_states: Dictionary = {
    "north": LightState.RED,
    "south": LightState.RED,
    "east": LightState.RED,
    "west": LightState.RED,
}
```

### 3. Python API for Stoplights

#### Direction-Based Functions
```python
# Set specific directions to a color
stoplight.green("north", "south")   # N and S green, E and W unchanged
stoplight.red("east", "west")       # E and W red, N and S unchanged
stoplight.yellow("north")            # Only N yellow

# Set all directions
stoplight.green()   # All directions green
stoplight.red()     # All directions red
stoplight.yellow()  # All directions yellow
```

#### Query Functions
```python
# Check global state
stoplight.is_red()     # Returns True if red for any direction
stoplight.is_green()   # Returns True if green for any direction

# Check specific direction
stoplight.is_red("north")      # True if north is red
stoplight.is_green("south")    # True if south is green
```

#### Timing Function
```python
wait(5)     # Pause for 5 seconds before next instruction
```

## File Changes

### Modified Files

#### `scripts/entities/stoplight.gd`
**Key Additions:**
- `stoplight_code: String` export variable for storing Python code
- `_directional_states` dictionary for tracking direction-specific states
- `_interpreter` and `_code_parser` for code execution
- `_wait_timer` and `_wait_duration` for timing display
- New methods: `green()`, `red()`, `yellow()` with direction parameters
- Updated query methods: `is_red()`, `is_green()`, `is_yellow()` with direction support
- `wait()` function called by interpreter to pause execution
- Code execution pipeline: `_setup_interpreter()`, `_start_code_execution()`, `_continue_code_execution()`
- `_process()` function to handle wait timer countdown

**Example Preset Codes:**
```gdscript
const PRESET_STANDARD_4WAY = """
while True:
    stoplight.green("north", "south")
    stoplight.red("east", "west")
    wait(5)
    stoplight.yellow("north", "south")
    wait(2)
    stoplight.red("north", "south")
    stoplight.green("east", "west")
    wait(5)
    stoplight.yellow("east", "west")
    wait(2)
"""
```

#### `scripts/core/level_settings.gd`
**Key Additions:**
- `@export_group("Stoplights")`
- `@export var stoplight_code_editable: bool = false`

Allows level designers to configure whether stoplight code is editable per level.

#### `scripts/core/python_interpreter.gd`
**Key Additions:**
- Added `wait()` built-in function handler in `_evaluate_call_expr()`
- `wait()` calls `stoplight.wait(seconds)` to pause code execution
- Already supports variable argument counts (0-3+ args)

#### `scenes/main_tilemap.gd`
**Key Additions:**
- `stoplight_code_popup` instance variable
- `_hovered_stoplight` tracking variable
- `_setup_stoplight_popup()` initializes the popup UI
- `_check_stoplight_hover()` detects mouse hover over stoplights and shows/hides popup
- Added `_setup_stoplight_popup()` and `_check_stoplight_hover()` to `_process()`

### New Files

#### `scripts/ui/stoplight_code_popup.gd`
The popup UI script that shows stoplight code on hover.

**Features:**
- Displays stoplight code with line numbers
- Highlights current executing line in yellow with ▶ indicator
- Shows countdown timer for wait() duration
- Displays read-only or editable status
- Updates in real-time as code executes

**Key Methods:**
- `show_for_stoplight(stoplight, editable)` - Display popup for a stoplight
- `hide_popup()` - Hide the popup
- `_update_code_display()` - Refresh code display with syntax highlighting
- `_on_gui_input()` - Handle clicks (for future editor integration)

#### `scenes/ui/stoplight_code_popup.tscn`
Godot scene file for the popup UI with:
- PanelContainer for styling
- RichTextLabel for code display with BBCode support
- Timer label showing time until next state change
- Edit hint label (read-only/editable indicator)
- Custom minimum size (400x400)

## How It Works

### Stoplight Initialization Flow
1. Level loads, stoplights are spawned from tilemap
2. Each stoplight checks if `stoplight_code` is set
3. If code exists:
   - `_setup_interpreter()` creates parser and interpreter
   - `_start_code_execution()` parses code and starts execution
   - Interpreter registered with stoplight reference

### Code Execution Flow
1. `_process()` is called every frame
2. If `_wait_timer > 0`, decrement it
3. When timer reaches 0, call `_continue_code_execution()`
4. Interpreter executes one step
5. When step completes (no more code), restart from beginning (infinite loop)

### Hover Detection Flow
1. `_process()` calls `_check_stoplight_hover()`
2. Calculates distance from mouse to each stoplight (40px hover range)
3. If hovering over a stoplight:
   - Show popup with current code and executing line
   - Update timer display showing wait() countdown
4. If no longer hovering:
   - Hide popup

## Usage Examples

### Simple 2-Way Stoplight
```gdscript
# In level tilemap, set stoplight_code export:
var stoplight_code = """
while True:
    stoplight.green()
    wait(5)
    stoplight.yellow()
    wait(2)
    stoplight.red()
    wait(5)
"""
```

### Standard 4-Way Intersection
```gdscript
stoplight.stoplight_code = Stoplight.PRESET_STANDARD_4WAY
```

### All Directions Always Green
```gdscript
stoplight.stoplight_code = Stoplight.PRESET_ALL_GREEN
```

### Custom Direction-Based Timing
```gdscript
var stoplight_code = """
while True:
    # North-South gets 7 seconds
    stoplight.green("north", "south")
    stoplight.red("east", "west")
    wait(7)
    
    # East-West gets 5 seconds
    stoplight.green("east", "west")
    stoplight.red("north", "south")
    wait(5)
"""
```

## Testing Checklist

- [ ] Stoplight without code works as before (no code = no auto execution)
- [ ] Stoplight code executes in a loop continuously
- [ ] `wait(N)` pauses execution for N seconds
- [ ] Direction-based `green("north", "south")` works correctly
- [ ] Direction-based `red("east", "west")` works correctly
- [ ] Single-direction `yellow("north")` works correctly
- [ ] `stoplight.green()` with no args sets all directions to green
- [ ] Hover popup appears within 40px of stoplight
- [ ] Popup shows current executing line with ▶ indicator
- [ ] Popup shows countdown timer during `wait()`
- [ ] Popup displays read-only status when `stoplight_code_editable = false`
- [ ] Popup displays edit hint when `stoplight_code_editable = true`
- [ ] Car's `is_red()` checks correct direction for stopping
- [ ] Red light violations still work with directional states
- [ ] Multiple stoplights can run code simultaneously
- [ ] Preset codes load correctly
- [ ] Code with syntax errors shows error message
- [ ] Stoplight code restarts from beginning after completing

## Future Enhancements

1. **Editable Stoplight Code** - When `stoplight_code_editable = true`:
   - Click on stoplight to open code editor
   - Player writes their own stoplight logic
   - Teaches traffic light coordination concepts

2. **Syntax Highlighting** - RichTextLabel BBCode:
   - Keywords in blue
   - Strings in green
   - Comments in gray

3. **Breakpoints** - Developer/teacher feature:
   - Pause stoplight execution at specific lines
   - Step through code line by line

4. **Visual State Indicator** - On stoplight sprite:
   - Show which directions are green/red/yellow
   - Help players understand directional states

5. **Code Templates** - Quick access to:
   - Standard cycles
   - Sensor-based timing
   - Traffic-aware logic

## Integration Notes

### With Vehicle System
- Vehicle.gd checks `stoplight.is_red()` and `stoplight.is_green()`
- Already supports direction parameters (no changes needed)
- Cars still respect red light violations

### With Tutorial System
- Tutorial can point to stoplights
- Can ask players to observe stoplight timing
- Can ask players to write if statements based on stoplight state

### With Level Editor
- Stoplight code can be set via inspector
- `stoplight_code_editable` per level in LevelSettings
- Preset codes available for quick setup

## Performance Considerations

- Each stoplight runs its own interpreter instance
- `wait()` pauses interpreter, doesn't block main thread
- No performance overhead for stoplights without code
- Multiple stoplights can run simultaneously without blocking cars
