# CLAUDE.md - GoCars Development Guide

## Project Overview

GoCars is an educational coding-puzzle game built with Godot 4.5.1 for the TrackTech: CSS Hackathon 2026. Players write **real Python code** to control vehicles and traffic elements to solve puzzles.

**Theme:** Cars, Transportation, Motorsports, or Racing Systems  
**Focus:** Educational project teaching real Python programming  
**Engine:** Godot 4.5.1  
**Language:** GDScript (engine), Python subset (player code)

Read the full PRD at `docs/PRD.md` before implementing any features.

---

## How to Run the Game

### Run in Editor (with visible window)
```bash
godot --path . --editor
```

### Run Game Directly
```bash
godot --path . --run
```

### Run Headless (for testing/CI - no window)
```bash
godot --path . --headless --quit-after 10
```

### Run and Capture Errors
```bash
godot --path . 2>&1 | tee godot_output.log
```

---

## How to Run Tests

Run all tests:
```bash
./run_tests.sh
```

Run a specific test:
```bash
godot --path . --headless --script tests/test_python_parser.gd
```

Tests are located in `tests/` directory with `.test.gd` extension. Co-located tests can also be placed next to their source files.

---

## Project Structure

```
GoCars/
├── CLAUDE.md              # You are here
├── project.godot          # Godot project file
├── run_tests.sh           # Test runner script
├── docs/
│   └── PRD.md             # Full Product Requirements Document
├── assets/
│   ├── sprites/
│   ├── audio/
│   ├── fonts/
│   └── tiles/             # Tileset images for map editor
│       ├── RoadTilesDebug64x64.png   # Debug tileset (17x16 tiles)
│       ├── RoadTilesDebug32x32.png   # Debug tileset 32px version
│       ├── RoadTiles64x64.png        # Production tileset
│       └── RoadTiles32x32.png        # Production tileset 32px
├── scenes/
│   ├── main.tscn
│   ├── map_editor/
│   │   └── map_editor.tscn    # Level/map editor scene
│   └── levels/
├── scripts/
│   ├── core/              # Python parser, interpreter, simulation engine
│   ├── entities/          # Vehicle, stoplight, boat
│   ├── ui/                # Code editor, file explorer, HUD
│   └── systems/           # Save manager, score manager
├── tests/                 # Test files (.test.gd)
└── data/
	└── levels/            # Level configuration files
```

---

## GDScript Important Rules

### CRITICAL - Common Mistakes to Avoid

**1. String multiplication syntax:**
```gdscript
# ❌ WRONG - This is Python, not GDScript
var line = "=" * 50

# ✅ CORRECT - Use repeat() method
var line = "=".repeat(50)
```

**2. Print formatting:**
```gdscript
# ❌ WRONG - f-strings don't exist in GDScript
print(f"Value: {value}")

# ✅ CORRECT - Use % operator or str()
print("Value: %s" % value)
print("Value: " + str(value))
```

**3. Dictionary/Array initialization:**
```gdscript
# ❌ WRONG - dict() doesn't exist
var my_dict = dict()

# ✅ CORRECT
var my_dict = {}
var my_array = []
```

**4. Type hints:**
```gdscript
# ❌ WRONG - Python-style hints
def my_func(value: int) -> str:

# ✅ CORRECT - GDScript style
func my_func(value: int) -> String:
```

**5. Null checking:**
```gdscript
# ❌ WRONG
if my_var == None:

# ✅ CORRECT
if my_var == null:
```

**6. Boolean values:**
```gdscript
# ❌ WRONG - Python capitalization
True, False

# ✅ CORRECT - GDScript lowercase
true, false
```

**7. Self reference:**
```gdscript
# ❌ WRONG in most cases
self.my_method()

# ✅ CORRECT - self is often optional
my_method()
```

**8. For loops:**
```gdscript
# ❌ WRONG
for i in range(len(array)):

# ✅ CORRECT - Use size()
for i in range(array.size()):
# Or iterate directly
for item in array:
```

**9. Class inheritance:**
```gdscript
# ❌ WRONG
class MyClass(Node):

# ✅ CORRECT
extends Node
class_name MyClass
```

**10. Lambda/Anonymous functions:**
```gdscript
# ❌ WRONG - Python lambda
var fn = lambda x: x * 2

# ✅ CORRECT - GDScript callable
var fn = func(x): return x * 2
```

---

## Core Systems Overview

### 1. Python Parser (`scripts/core/python_parser.gd`)
- Parses **actual Python syntax** (subset)
- **Tokenizer:** Keywords, identifiers, operators, literals, INDENT/DEDENT
- **AST Builder:** Creates Abstract Syntax Tree from tokens
- **Indentation Handler:** Tracks levels, emits INDENT/DEDENT tokens
- Returns Python-style errors (SyntaxError, IndentationError, NameError, etc.)
- See PRD section TECH-003 for grammar specification

### 2. Python Interpreter (`scripts/core/python_interpreter.gd`)
- Executes AST nodes sequentially
- Manages variable scope (store/retrieve variables)
- Evaluates expressions and conditions
- Executes loops with iteration limits
- Handles control flow (if/elif/else, while, for, break)
- Infinite loop detection (10-second timeout)

### 3. Simulation Engine (`scripts/core/simulation_engine.gd`)
- Receives commands from interpreter
- Manages vehicle physics (position, velocity, rotation)
- Handles collision detection (vehicle-vehicle, vehicle-boundary)
- Controls traffic light state machines
- Manages timing and synchronization

### 4. Level Manager (`scripts/core/level_manager.gd`)
- Loads level configurations from data files
- Spawns vehicles and traffic elements at designated positions
- Tracks win/lose condition states
- Manages scoring and star rating calculations
- Handles level transitions

---

## Python API Reference (Player Code)

### Car Object

```python
# Basic Movement
car.go()                    # Start moving forward continuously
car.stop()                  # Stop immediately
car.turn_left()             # Queue 90° left turn at intersection
car.turn_right()            # Queue 90° right turn at intersection
car.wait(seconds)           # Wait for seconds (float)

# Enhanced Movement (NEW!)
car.turn(direction)         # Turn 90° immediately ("left" or "right")
car.move(tiles)             # Move forward N tiles (1-100)

# Speed Control
car.set_speed(multiplier)   # Set speed (0.5 to 2.0)
car.get_speed()             # Get current speed → float

# Road Detection (NEW!)
car.is_front_road()         # Is there a road tile in front? → bool
car.is_left_road()          # Is there a road tile to the left? → bool
car.is_right_road()         # Is there a road tile to the right? → bool

# Car Detection (NEW!)
car.is_front_car()          # Is there ANY car (active or crashed) in front? → bool
car.is_front_crashed_car()  # Is there a CRASHED car in front? → bool

# State Queries (return bool)
car.is_moving()             # Is car currently moving?
car.is_blocked()            # Is path blocked?
car.is_at_intersection()    # Is car at intersection?
car.is_at_destination()     # Has car reached destination?

# Distance Queries (return float)
car.distance_to_destination()    # Distance to destination
car.distance_to_intersection()   # Distance to next intersection
```

### Stoplight Object

```python
# Control
stoplight.set_red()         # Change to red
stoplight.set_yellow()      # Change to yellow
stoplight.set_green()       # Change to green

# State Queries (return bool)
stoplight.is_red()          # Is light red?
stoplight.is_yellow()       # Is light yellow?
stoplight.is_green()        # Is light green?

# Get State (return string)
stoplight.get_state()       # Returns "red", "yellow", or "green"
```

### Boat Object

```python
# Control
boat.depart()               # Force immediate departure

# State Queries
boat.is_ready()             # Is boat docked and ready?
boat.is_full()              # Is boat at capacity?
boat.get_passenger_count()  # Number of cars on board → int
```

---

## Supported Python Syntax

### Variables
```python
speed = 1.5
wait_time = 3
is_ready = True
light_state = stoplight.get_state()
car.set_speed(speed)
```

### Conditionals (if/elif/else)
```python
if stoplight.is_red():
	car.stop()
elif stoplight.is_yellow():
	car.stop()
else:
	car.go()
```

### Comparison Operators
```python
==    # Equal to
!=    # Not equal to
<     # Less than
>     # Greater than
<=    # Less than or equal
>=    # Greater than or equal

# Example
if car.distance_to_destination() < 5:
	car.stop()
```

### Logical Operators
```python
and   # Both conditions True
or    # At least one condition True
not   # Inverts the condition

# Example
if stoplight.is_green() and not car.is_blocked():
	car.go()
```

### While Loops
```python
while not car.is_at_destination():
	car.go()

# With break
while True:
	car.go()
	if car.is_at_intersection():
		break
```

### For Loops
```python
for i in range(3):
	car.go()
	car.wait(1)
	car.stop()
```

### Comments
```python
# This is a single-line comment
car.go()  # Inline comment
```

### NOT Supported (to keep it simple)
```python
# These are NOT supported:
# - Function definitions (def)
# - Classes
# - Import statements
# - List/dict comprehensions
# - Try/except
# - With statements
# - Lambda functions
# - Multiple assignment (a, b = 1, 2)
# - Lists and dictionaries
```

---

## Python Error Messages

The parser/interpreter generates Python-style error messages:

| Error Type | Example Message |
|------------|-----------------|
| SyntaxError | `SyntaxError: expected ':' after if condition (line 3)` |
| IndentationError | `IndentationError: expected an indented block (line 5)` |
| NameError | `NameError: 'car2' is not defined (line 7)` |
| TypeError | `TypeError: car.wait() requires a number, got string (line 2)` |
| AttributeError | `AttributeError: 'car' has no method 'fly' (line 4)` |
| RuntimeError | `RuntimeError: infinite loop detected (exceeded 10s)` |

---

## Keyboard Shortcuts

| Control | Function | Shortcut |
|---------|----------|----------|
| Run | Execute Python code | F5 or Ctrl+Enter |
| Pause | Freeze simulation | Space |
| Resume | Continue simulation | Space (toggle) |
| Fast-Forward 2x | Double speed | + or = |
| Fast-Forward 4x | Quadruple speed | Ctrl + + |
| Slow-Motion 0.5x | Half speed | - |
| Fast Retry | Instant restart | R or Ctrl+R |
| Step | Execute one line | F10 |

---

## Development Workflow

### Before Implementing a Feature:
1. Read the relevant section in `docs/PRD.md`
2. Plan the implementation - create a plan in a markdown file if complex
3. Identify which files need to be created/modified
4. Write tests first if applicable

### After Implementing:
1. Run `./run_tests.sh` to verify nothing broke
2. Run the game and test manually
3. Check for GDScript errors in output
4. Update documentation if needed

### When Creating New Files:
- Use snake_case for file names: `python_parser.gd`
- Use PascalCase for class names: `PythonParser`
- Place files in appropriate directories per project structure
- Add corresponding test file if it's a core system

---

## Testing Guidelines

### Test File Naming
- Test files end with `.test.gd`
- Name matches source: `python_parser.gd` → `python_parser.test.gd`

### Test Structure
```gdscript
extends SceneTree

func _init():
    print("Running PythonParser tests...")
    test_tokenize_keywords()
    test_parse_if_statement()
    test_indentation_error()
    print("All tests passed!")
    quit()

func test_tokenize_keywords():
    var parser = PythonParser.new()
    var tokens = parser.tokenize("if True:")
    assert(tokens[0].type == "KEYWORD", "First token should be keyword")
    print("  ✓ test_tokenize_keywords")

func test_parse_if_statement():
    var parser = PythonParser.new()
    var ast = parser.parse("if stoplight.is_red():\n    car.stop()")
    assert(ast.type == "if_statement", "Should parse if statement")
    print("  ✓ test_parse_if_statement")
```

---

## Level Data Format

Levels are stored as JSON in `data/levels/`:

```json
{
    "id": "C2",
    "name": "Esplanade Evening",
    "description": "Learn to use if statements to react to traffic lights",
    "location": "Iloilo Esplanade",
    "python_concepts": ["if", "boolean_queries"],
    "available_functions": ["car.go", "car.stop", "stoplight.is_green", "stoplight.is_red"],
    "entities": {
        "cars": [
            {"id": "car1", "position": [2, 5], "destination": [8, 5]}
        ],
        "stoplights": [
            {"id": "stoplight1", "position": [5, 5], "initial_state": "red"}
        ]
    },
    "win_condition": "all_cars_at_destination",
    "star_criteria": {
        "one_star": "complete",
        "two_stars": "lines_of_code <= 6",
        "three_stars": "lines_of_code <= 4"
    },
	"hint": "Use 'if stoplight.is_green():' to check the light state"
}
```

---

## Signals to Use

```gdscript
# Parser/Interpreter events
signal code_parsed(ast: Dictionary)
signal parse_error(error: String, line: int)
signal execution_started()
signal execution_line(line_number: int)
signal execution_error(error: String, line: int)
signal execution_completed()

# Game events
signal simulation_started()
signal simulation_paused()
signal simulation_ended(success: bool)
signal car_reached_destination(car_id: String)
signal car_crashed(car_id: String)
signal infinite_loop_detected()
signal level_completed(stars: int)
signal level_failed(reason: String)
```

---

## Priority Order for Implementation

Based on PRD priorities:

### P0 - Critical (Must Have)
1. Python Parser System (TECH-003)
2. Python Interpreter (TECH-002)
3. Python Vehicle API (CORE-002)
4. Python Language Features (CORE-003)
5. Simulation Controls (CORE-004)
6. Campaign Mode (MODE-001)
7. Tutorial Levels T1-T5 (LVL-001) - Functions
8. Iloilo City Levels C1-C5 (LVL-002) - Variables & Conditionals
9. Main Menu (UI-001)
10. Gameplay Interface with Python Highlighting (UI-002)

### P1 - High (Should Have)
1. Water/Port Levels W1-W5 (LVL-003) - Loops
2. Boat Mechanics
3. Infinite Mode (MODE-002)
4. Vehicle Collection System (VEH-001)

### P2 - Medium (Nice to Have)
1. Vehicle Info Display (VEH-002)
2. Advanced functions (follow)
3. Sound effects and music
4. Polish and animations

---

## Python Concepts by Level Set

| Set | Levels | Python Concepts |
|-----|--------|-----------------|
| Tutorial | T1-T5 | Function calls, sequencing |
| Iloilo City | C1-C5 | Variables, if/elif/else, and/or/not, comparisons |
| Water/Port | W1-W5 | while loops, for loops with range(), nested loops |

---

## Syntax Highlighting Colors (VS Code Python Theme)

| Element | Color | Hex |
|---------|-------|-----|
| Keywords | Purple | #C586C0 |
| Built-in Constants | Blue | #569CD6 |
| Functions/Methods | Yellow | #DCDCAA |
| Strings | Orange | #CE9178 |
| Numbers | Light Green | #B5CEA8 |
| Comments | Green | #6A9955 |
| Variables | Light Blue | #9CDCFE |
| Operators | White | #D4D4D4 |

---

## Asking Claude Code for Help

### Good Prompts:
- "Read docs/PRD.md section TECH-003 and implement the Python tokenizer"
- "Create the Python AST builder based on the grammar in the PRD"
- "Write tests for the Python parser before implementing"
- "Implement the if/elif/else interpreter following PRD CORE-003"
- "Run the game and fix any errors you see"

### When Stuck:
- "Let's plan this feature before implementing. Create a plan in docs/plans/"
- "What's the simplest way to implement [feature]?"
- "Run ./run_tests.sh and fix failing tests"

---

## Hackathon Timeline Reminder

- **Dec 15-22:** Phase 1 - Python parser foundation
- **Dec 23-31:** Phase 2 - Complete Python interpreter, game mechanics
- **Jan 1-10:** Phase 3 - All 15 levels with Python concepts
- **Jan 11-18:** Phase 4 - VS Code UI with Python highlighting
- **Jan 19-23:** Phase 5 - Testing & Submission
- **Jan 24:** Demo Day

---

## Notes

- Keep code clean and delete unused files regularly
- Commit frequently with descriptive messages
- Test on target hardware (standard school computer specs)
- The game should run at stable 60 FPS
- Executable size target: < 200MB
- Code parse time target: < 100ms

---

## Map Editor

The Map Editor (`scenes/map_editor/map_editor.tscn`) allows creating levels visually.

### Controls
- **WASD / Arrow Keys**: Move camera
- **Mouse Wheel**: Zoom in/out (0.25x - 3x)
- **Left Click**: Paint selected terrain
- **Right Click**: Erase (paint grass)
- **1 / Grass Button**: Select grass terrain
- **2 / Road Button**: Select road terrain

### Tileset System

The map editor uses a 17-column x 16-row tileset (`RoadTilesDebug64x64.png`) with auto-tiling:

#### Columns (Main Tile Type - Cardinal Connections)
Roads automatically connect to adjacent roads in cardinal directions:

| Column | Index | Description |
|--------|-------|-------------|
| c1 | 0 | Grass |
| c2 | 1 | Road (isolated, no connections) |
| c3 | 2 | Road connects South |
| c4 | 3 | Road connects North |
| c5 | 4 | Road connects East |
| c6 | 5 | Road connects West |
| c7 | 6 | Road connects South + North |
| c8 | 7 | Road connects East + West |
| c9 | 8 | Road connects South + East |
| c10 | 9 | Road connects South + West |
| c11 | 10 | Road connects North + East |
| c12 | 11 | Road connects North + West |
| c13 | 12 | Road connects South + North + East |
| c14 | 13 | Road connects South + East + West |
| c15 | 14 | Road connects North + East + West |
| c16 | 15 | Road connects South + North + West |
| c17 | 16 | Road connects all four (4-way intersection) |

#### Rows (Sub Type - Diagonal Road Detection)
Rows are selected based on which diagonal tiles contain roads (for corner decorations):

| Row | Index | Diagonal Roads Present |
|-----|-------|------------------------|
| r1 | 0 | None (basic tile) |
| r2 | 1 | NW only |
| r3 | 2 | NE only |
| r4 | 3 | SW only |
| r5 | 4 | SE only |
| r6 | 5 | NW + SW |
| r7 | 6 | NE + NW |
| r8 | 7 | NE + SE |
| r9 | 8 | SW + SE |
| r10 | 9 | NW + SE |
| r11 | 10 | SW + NE |
| r12 | 11 | NW + NE + SW |
| r13 | 12 | NW + NE + SE |
| r14 | 13 | NE + SW + SE |
| r15 | 14 | NW + SW + SE |
| r16 | 15 | All four diagonals |

#### How Auto-Tiling Works
1. When placing a road, the system checks cardinal neighbors (N, S, E, W) to determine the column
2. It also checks diagonal neighbors (NW, NE, SW, SE) to determine the row
3. All affected tiles (placed tile + 8 neighbors) are updated automatically
4. Priority: More specific diagonal patterns (r16) are checked before less specific ones (r1)

### Map Editor Code Location
- Scene: `scenes/map_editor/map_editor.tscn`
- Script: `scenes/map_editor/map_editor.gd`

---

## Implemented Game Mechanics

### TileMapLayer System
The main game scene uses Godot's modern `TileMapLayer` for rendering roads and terrain:
- **Grass tiles**: Column 0 in the tileset
- **Road tiles**: Columns 1-16 in the tileset (auto-connecting)
- Players can edit the map by placing/removing roads

### Road Cards System
Players have a limited number of road cards to modify the map:
- **Initial count**: 10 road cards (configurable per level)
- **Placing a road**: Costs 1 road card (left-click on grass tile)
- **Removing a road**: Refunds 1 road card (right-click on road tile)
- **Live editing**: Map editing works DURING gameplay, allowing reactive strategy
- **UI Display**: Road card count shown in top-left corner

### Hearts System
Players have a limited number of hearts (lives):
- **Initial count**: 10 hearts (configurable per level)
- **Losing hearts**: Car goes off-road or collides with another car (-1 heart)
- **Game over**: When hearts reach 0, level fails
- **UI Display**: Hearts count shown in top-left corner

### Crashed Cars as Obstacles (CRITICAL MECHANIC!)
Cars do NOT disappear when they crash - they become permanent obstacles:
- **Visual**: Crashed cars are darkened (50% gray modulate)
- **Vehicle States**:
  - State 1 (Active): Car moves and executes code normally
  - State 0 (Crashed): Car stops all movement, becomes a static obstacle
- **Off-Road Crashes**: Moving onto grass triggers crash (car stays on map)
- **Car-to-Car Collisions**:
  - Active hits Active: Both crash and turn gray, 1 heart lost
  - Active hits Crashed: Only active car crashes, 1 heart lost
  - Crashed cars always stay on the map as obstacles

### Automatic Car Spawning
Cars automatically spawn at regular intervals after running code:
- **Interval**: Every 15 seconds after simulation starts
- **Location**: Position (100, 300) facing RIGHT
- **Destination**: Position (700, 300)
- **Naming**: car1, car2, car3, car4, etc.
- **Code Execution**: Each new car automatically runs the current code
- **Control**: Spawning starts when "Run Code" is pressed, stops on reset
- **Strategy**: Your code must handle multiple cars and navigate around crashed cars

### Stoplight Control Panel
UI panel in top-right corner allows manual stoplight control:
- **Set Red** button - Change stoplight to red
- **Set Yellow** button - Change stoplight to yellow
- **Set Green** button - Change stoplight to green
- **State display** - Shows current stoplight color

### Road-Only Movement
Cars must stay on road tiles:
- **Valid roads**: Columns 1-16 (any road tile)
- **Invalid terrain**: Column 0 (grass)
- **Detection methods**: `is_front_road()`, `is_left_road()`, `is_right_road()`
- **Penalty**: Moving onto grass triggers crash and heart loss

---

## Implemented Features Summary

| Feature | Status | Description |
|---------|--------|-------------|
| TileMapLayer System | ✅ COMPLETE | Modern tile rendering with auto-connecting roads |
| Road Cards System | ✅ COMPLETE | Consumable resource for map editing |
| Hearts System | ✅ COMPLETE | Lives/health system with crash penalties |
| Live Map Editing | ✅ COMPLETE | Edit roads during gameplay (always enabled) |
| Crashed Cars as Obstacles | ✅ COMPLETE | Cars stay on map when crashed (darkened) |
| Vehicle State System | ✅ COMPLETE | State 0 = Crashed, 1 = Active |
| Automatic Car Spawning | ✅ COMPLETE | New car every 15 seconds |
| `car.turn(direction)` | ✅ COMPLETE | Immediate 90° turns |
| `car.move(tiles)` | ✅ COMPLETE | Move forward N tiles |
| `car.is_front_road()` | ✅ COMPLETE | Detect road ahead |
| `car.is_left_road()` | ✅ COMPLETE | Detect road to left |
| `car.is_right_road()` | ✅ COMPLETE | Detect road to right |
| `car.is_front_car()` | ✅ COMPLETE | Detect any car ahead |
| `car.is_front_crashed_car()` | ✅ COMPLETE | Detect crashed cars ahead |
| Stoplight Control Panel | ✅ COMPLETE | Manual stoplight control UI |
| Road-Only Movement | ✅ COMPLETE | Cars crash on non-road tiles |
| Car-to-Car Collisions | ✅ COMPLETE | State-aware collision detection |

---

## Python Code Examples

### Example 1: Basic Navigation with Road Detection
```python
# Move forward if road ahead, otherwise turn right
if car.is_front_road():
	car.move(3)
else:
	car.turn("right")
```

### Example 2: Intersection Logic
```python
# Navigate through an intersection
if car.is_front_road():
	car.go()
elif car.is_left_road():
	car.turn("left")
	car.go()
elif car.is_right_road():
	car.turn("right")
	car.go()
else:
	car.stop()
```

### Example 3: Obstacle Avoidance (Multi-Car Strategy)
```python
# Navigate around crashed cars
if car.is_front_crashed_car():
	# Crashed car blocking, find alternate route
	if car.is_left_road():
		car.turn("left")
		car.go()
	elif car.is_right_road():
		car.turn("right")
		car.go()
	else:
		car.stop()  # Stuck, need player to build road
elif car.is_front_car():
	# Active car ahead, wait
	car.stop()
elif car.is_front_road():
	# Clear path
	car.go()
```

### Example 4: Multi-Car Code (Runs on Every Spawned Car)
```python
# This code runs on ALL cars (spawned every 15 seconds)
# Must handle different scenarios dynamically

# First priority: Check for obstacles
if car.is_front_crashed_car():
	# Route around crashed car
	if car.is_left_road() and not car.is_front_car():
		car.turn("left")
	elif car.is_right_road():
		car.turn("right")

# Second priority: Check for active cars
elif car.is_front_car():
	car.stop()  # Wait for car to move

# Third priority: Continue if path clear
elif car.is_front_road():
	car.go()
```

---

## Game Controls Summary

| Action | Input | Notes |
|--------|-------|-------|
| Place road | Left-click | Costs 1 road card, **works during gameplay** |
| Remove road | Right-click | Refunds 1 road card, **works during gameplay** |
| Control stoplight | Stoplight panel buttons | Red/Yellow/Green buttons in top-right |
| Run code | Run Code button or F5 | Starts car spawning every 15 seconds |
| Pause/Resume | Space | Pauses simulation and spawning |
| Reset level | R | Clears crashed cars, resets hearts, stops spawning |
| Speed up | + or = | 2x or 4x speed |
| Slow down | - | 0.5x speed |
| Step | F10 | Execute one line |

---

## Educational Value

The current game mechanics teach:
- **Conditional logic**: if/elif/else for decisions
- **State management**: Tracking crashed vs active vehicles
- **Edge case handling**: Multiple scenarios with different vehicle states
- **Resource management**: Hearts and road cards as constraints
- **Dynamic problem solving**: React to changing conditions (crashed cars)
- **Code reuse**: Same code runs on all spawned cars
- **Debugging live systems**: See code execute in real-time on multiple vehicles
- **Spatial reasoning**: Road detection and pathfinding
