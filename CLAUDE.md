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
│   └── tiles/             # Tileset images and resources
│       ├── gocarstilesSheet.png      # Main tileset (8x7, 144x144 per tile)
│       ├── road_tileset.tres         # TileSet resource for TileMapLayers
│       └── Old Assets/               # Deprecated tilesets
├── scenes/
│   ├── main.tscn                     # Main game scene (old RoadTile system)
│   ├── main_tilemap.gd               # Main game script (TileMap system)
│   ├── levelmaps/                    # Level scene files (auto-loaded)
│   │   └── level_01.tscn             # Level 1 template
│   ├── map_editor/
│   │   ├── road_tile.tscn            # Old road tile scene
│   │   └── road_tile.gd              # Old road tile script
│   └── entities/                     # Vehicle and other entity scenes
├── scripts/
│   ├── core/              # Python parser, interpreter, simulation engine
│   │   └── level_loader.gd           # Auto-loads levels from levelmaps/
│   ├── map_editor/
│   │   ├── road_tilemap_layer.gd     # TileMapLayer script with guideline paths
│   │   └── road_tile_proxy.gd        # Wrapper for Vehicle compatibility
│   ├── entities/          # Vehicle, stoplight, boat
│   ├── ui/                # Code editor, file explorer, HUD
│   └── systems/           # Save manager, score manager
├── tests/                 # Test files (.test.gd)
└── data/
	└── levels/            # Level configuration files (JSON)
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

### Car Commands (Short Names)

```python
# Movement
car.go()                # Start moving forward
car.stop()              # Stop immediately
car.turn("left")        # Turn 90° left
car.turn("right")       # Turn 90° right
car.move(N)             # Move forward N tiles
car.wait(N)             # Wait N seconds

# Speed
car.set_speed(N)        # Set speed (0.5-2.0)
car.get_speed()         # Get current speed → float

# Road Detection
car.front_road()        # Road ahead? → bool
car.left_road()         # Road to left? → bool
car.right_road()        # Road to right? → bool
car.dead_end()          # No roads anywhere? → bool

# Car Detection
car.front_car()         # Any car ahead? → bool
car.front_crash()       # Crashed car ahead? → bool

# State
car.moving()            # Is moving? → bool
car.blocked()           # Path blocked? → bool
car.at_cross()          # At intersection? → bool
car.at_end()            # At destination? → bool
car.at_red()            # Near red light? → bool
car.turning()           # Currently turning? → bool

# Distance
car.dist()              # Distance to destination → float
```

### Stoplight Commands (Short Names)

```python
# Control
stoplight.red()         # Set to red
stoplight.yellow()      # Set to yellow
stoplight.green()       # Set to green

# State
stoplight.is_red()      # Is red? → bool
stoplight.is_yellow()   # Is yellow? → bool
stoplight.is_green()    # Is green? → bool
stoplight.state()       # Get state → "red"/"yellow"/"green"
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

## Level Creation System (TileMap-Based)

Levels are created using Godot's TileMapLayer system. Each level is a scene file in `scenes/levelmaps/`.

### Creating a New Level

1. **Copy an existing level**: Duplicate `scenes/levelmaps/level_01.tscn`
2. **Rename it**: e.g., `level_02.tscn`, `level_03.tscn`, etc.
3. **Open in Godot Editor**: Double-click to open
4. **Set the display name**: Edit `LevelSettings/LevelName` Label's text property
5. **Configure road building**: Edit `LevelSettings/LevelBuildRoads` Label's text (0=disabled, 1+=enabled with count)
6. **Paint tiles on RoadLayer**: Use the TileMap painting tools
7. **Configure hearts**: Edit `HeartsUI/HeartCount` Label's text (e.g., "3" for 3 hearts)
8. **Save**: The level auto-loads from the folder

Levels are automatically detected from `scenes/levelmaps/` and sorted alphabetically by filename.

### Level Naming System

Levels have two names:
- **Filename** (e.g., `level_01`, `level_02`): Used internally for save data and level loading
- **Display Name** (from LevelName label): Shown in menus and game UI

To set the display name:
1. Expand `LevelSettings` node in the scene tree
2. Select the `LevelName` Label node
3. Edit the `text` property to your desired name (e.g., "TileMap Tutorial", "First Drive")
4. Keep `visible = false` (the label is only for storing the name)

### Level Structure

Each level scene has:
- **BackgroundLayer** (TileMapLayer): For grass, water, decorations (z_index = -10)
- **RoadLayer** (TileMapLayer + RoadTileMapLayer script): For roads and parking tiles
- **LevelSettings** (Node): Level metadata container
  - **LevelName** (Label): Display name shown in menus and game over (visible = false)
  - **LevelBuildRoads** (Label): Road building configuration (visible = false)
    - `"0"` = Road building disabled
    - `"5"` = Road building enabled with 5 road cards
- **EnableBuildingLayer** (TileMapLayer, optional): Per-tile build permissions
- **HeartsUI** (instance of hearts_ui.tscn): Hearts/lives display
  - **HeartCount** (Label): Set text to configure starting hearts (e.g., "3")

### Tileset Layout (18×12 grid, 144×144 per tile)

The tileset `assets/tiles/gocarstilesSheet.png` has 216 tiles organized as follows:

**Tile Types:**
- **road**: Basic roads with road connections
- **parking road**: Single parking spots with road connections
- **multi parking road**: Parking with road + parking road connections (for multi-lane parking lots)
- **stoplight road**: Roads with stoplight spawning

**Connection Types:**
- **road connection**: Connects to roads and parking roads
- **parking road connection**: Connects to multi parking roads only

**Rows 0-3: Basic Roads and Roads with Parking Connections**

| Row | c0-c3 | c4-c7 | c8-c11 | c12-c16 |
|-----|-------|-------|--------|---------|
| **0** | Basic roads (none/E/EW/W) | Spawn road W (A-D) | Road+parking | Roads/Stoplights |
| **1** | Roads S/SE/SEW/SW | Spawn road E (A-D) | Road+parking | Roads/Stoplights |
| **2** | Roads SN/SNE/SNEW/SNW | Road+parking N | Road+parking | Parking S (plain) |
| **3** | Roads N/NE/NEW/NW | Road+parking S | Road+parking | Parking N (plain) |

**Rows 4-7: Spawn and Destination Parking (N/S facing)**

| Row | c0-c1 | c2-c17 |
|-----|-------|--------|
| **4** | Spawn road SN (A) | Spawn parking N (groups A-D, single/multi variants) |
| **5** | Spawn road SN (B) | Spawn parking S (groups A-D, single/multi variants) |
| **6** | Spawn road SN (C) | Dest parking N (groups A-D, single/multi variants) |
| **7** | Spawn road SN (D) | Dest parking S (groups A-D, single/multi variants) |

**Rows 8-11: Parking E/W facing (single and multi-parking)**

| Row | c0-c1 | c2-c9 | c10-c17 |
|-----|-------|-------|---------|
| **8** | Parking E/W (plain) | Spawn parking E/W (A-D) | Dest parking E/W (A-D) |
| **9** | Multi parking E/W +PS | Spawn multi E/W +PS (A-D) | Dest multi E/W +PS (A-D) |
| **10** | Multi parking E/W +PSN | Spawn multi E/W +PSN (A-D) | Dest multi E/W +PSN (A-D) |
| **11** | Multi parking E/W +PN | Spawn multi E/W +PN (A-D) | Dest multi E/W +PN (A-D) |

**Connection Key:**
- **E** = East (right), **W** = West (left), **N** = North (top), **S** = South (bottom)
- **P** prefix = Parking road connection (e.g., PE = parking connection east)

**Spawn Groups (A, B, C, D):**
Each spawn and destination tile belongs to a group (A, B, C, or D). Cars must park at a destination matching their spawn group, or they lose a heart.

### Multi-Parking Road System
Multi-parking roads allow building parking lots with multiple spots:
- **Left multi parking**: Has parking connection east only
- **Center multi parking**: Has parking connections east and west
- **Right multi parking**: Has parking connection west only
- **Top multi parking**: Has parking connection south only
- **Bottom multi parking**: Has parking connection north only

### Stoplight Tiles (Row 0-1, columns 14-16)
Stoplights spawn automatically from these tiles:
- **Stoplight SNEW** (r0/c15): 4-way intersection
- **Stoplight SEW** (r0/c16): T-junction (no north)
- **Stoplight SNE** (r1/c14): T-junction (no west)
- **Stoplight NEW** (r1/c15): T-junction (no south)
- **Stoplight SNW** (r1/c16): T-junction (no east)

### Level Files Location
- **Levels folder**: `scenes/levelmaps/`
- **TileSet resource**: `assets/tiles/road_tileset.tres`
- **Tileset image**: `assets/tiles/gocarstilesSheet.png`
- **Road layer script**: `scripts/map_editor/road_tilemap_layer.gd`
- **Level loader**: `scripts/core/level_loader.gd`
- **Main scene (TileMap version)**: `scenes/main_tilemap.gd`
- **Hearts UI**: `scenes/ui/hearts_ui.tscn`
- **Game data (save/load)**: `scripts/core/game_data.gd`

### Level Selector
The level selector (`scenes/menus/level_selector.gd`) automatically:
- Scans `scenes/levelmaps/` folder for `.tscn` files
- Reads the `LevelName` label from each level for display
- Shows best completion times from saved data
- Sorts levels alphabetically by filename

---

## Implemented Game Mechanics

### TileMap-Based Road System (NEW)
The game now uses Godot's TileMapLayer for roads:
- **TileMapLayer**: Native Godot tilemap for efficient rendering
- **RoadTileMapLayer script**: Adds guideline path calculations
- **RoadTileProxy**: Wrapper for Vehicle compatibility
- **Grid size**: 144x144 pixels per tile
- **Files**: `scripts/map_editor/road_tilemap_layer.gd`, `scripts/map_editor/road_tile_proxy.gd`

### Guideline Path System
Cars follow pre-calculated paths through road tiles based on tile type:
- **Through-paths**: Each tile type has predefined paths based on connections
- **Lane driving**: Paths include lane offset (25px) for right-hand traffic
- **Smooth turns**: Turn paths include corner waypoints for natural movement
- **4-directional**: Supports cardinal directions (top/bottom/left/right)
- **Path caching**: Paths cached per grid position for performance

**How it works:**
1. When a car enters a tile, it determines entry direction from where it came
2. The tile type determines available exits based on its connections
3. Car chooses exit based on queued turn commands or straight-through
4. Car follows waypoint path from entry edge to exit edge
5. On reaching exit, car transitions to next tile

**Key functions in `road_tile.gd`:**
- `get_available_exits(entry_dir)` - Returns array of valid exit directions
- `get_guideline_path(entry_dir, exit_dir)` - Returns array of world-position waypoints
- `add_connection(direction)` / `remove_connection(direction)` - Modify connections
- `mark_paths_dirty()` - Force path recalculation on next access

### Road Selection and Editing System
Players edit roads through a selection-based system:
- **Select mode**: Click on an existing road to select it (yellow highlight)
- **Preview tile**: When selected, a ghost preview shows where new road will be placed
- **Place new road**: Click on preview to place road (costs 1 card, auto-connects)
- **Connect existing**: Click on adjacent road to connect (FREE, no card cost)
- **Deselect**: Click on selected road again to exit edit mode
- **Protected roads**: Spawn road (0,3) and destination road (9,3) cannot be removed
- **Live editing**: Works during gameplay for reactive strategy

### Road Cards System
Players have a limited number of road cards to modify the map:
- **Per-level config**: Set via `LevelSettings/LevelBuildRoads` label
  - `"0"` = Road building completely disabled (no UI shown)
  - `"5"` = Road building enabled with 5 road cards
- **Placing a road**: Costs 1 road card (click on preview tile)
- **Connecting roads**: FREE (click adjacent existing road)
- **Removing a road**: Refunds 1 road card (right-click on road tile)
- **UI Display**: Road card count shown in top-left corner (hidden if disabled)

### EnableBuilding Layer (Optional)
Levels can include an `EnableBuildingLayer` TileMapLayer for per-tile build permissions:
- **Tile 0**: Cannot select, build, or remove at this position
- **Tile 1**: Can select and build, but cannot remove
- **Tile 2**: Full permissions (select, build, remove)
- If no EnableBuildingLayer exists, all tiles have full permissions when building is enabled

### Hearts System
Players have a limited number of hearts (lives):
- **Initial count**: 10 hearts (configurable per level)
- **Losing hearts**:
  - Car goes off-road (-1 heart)
  - Car collides with another car (-1 heart)
  - Car runs a red light (-1 heart)
- **Game over**: When hearts reach 0, level fails
- **UI Display**: Hearts count shown in top-left corner

### Red Light Violation System (IMPORTANT!)
Cars do NOT automatically stop at red lights - players must code the logic!
- **No auto-stop**: Cars will pass through stoplights regardless of color
- **Violation detection**: If a car passes through a stoplight while it's red, it's a violation
- **Penalty**: Running a red light costs 1 heart
- **Player responsibility**: Code must check `stoplight.is_red()` and call `car.stop()`
- **Educational goal**: Teaches conditional logic and defensive programming

```python
# REQUIRED: Players must code stoplight handling
if stoplight.is_red():
	car.stop()
else:
	car.go()
```

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
Cars spawn automatically so players can see what they're dealing with:
- **Initial spawn**: One car spawns at each spawn parking tile when level loads (before running code)
- **Continuous spawning**: After "Run Code" is pressed, new cars spawn every 15 seconds
- **Location**: Spawn parking tiles defined in the level's RoadLayer
- **Destination**: Destination parking tiles defined in the level's RoadLayer
- **Vehicle types**: Random selection from 8 types (Sedan, Estate, Sport, Micro, Pickup, Jeepney_1, Jeepney_2, Bus)
- **Naming**: car1, car2, car3, car4, etc.
- **Code Execution**: Each new car automatically runs the current code
- **Control**: Continuous spawning starts when "Run Code" is pressed, stops on reset
- **Strategy**: Your code must handle multiple cars and navigate around crashed cars

### Spawn Groups System (A, B, C, D)
Cars must park at destinations matching their spawn group:
- **Groups**: A, B, C, D (defined by spawn/destination tile type)
- **Spawn assignment**: Cars inherit the group of their spawn tile
- **Correct parking**: Car parks at destination with matching group (Group A car → Dest A)
- **Wrong parking penalty**: Parking at wrong group destination costs 1 heart but still counts as parked
- **No group**: If spawn tile has no group, car can park anywhere without penalty

**Vehicle API for spawn groups:**
```gdscript
vehicle.spawn_group           # SpawnGroup enum (A, B, C, D, NONE)
vehicle.get_spawn_group_name() # Returns "A", "B", "C", "D", or "None"
vehicle.is_at_correct_destination() # True if at matching group destination
vehicle.is_at_any_destination()     # True if at any destination
```

### Vehicle Stats Hover UI
Hovering over a vehicle displays a stats panel showing:
- **Type**: Vehicle type name (Sedan, Jeepney, Bus, etc.)
- **Group**: Spawn group (A, B, C, D, or None)
- **Speed**: Current effective speed
- **Facing**: Direction (North, South, East, West)
- **State**: Current state (Moving, Waiting, Parked, Crashed)

### Stoplight Tile Spawning
Stoplights are automatically spawned from stoplight tiles in the tilemap:
- Place stoplight tiles (row 6) in the RoadLayer
- Stoplights spawn at tile center when level loads
- Multiple stoplights supported per level
- Register with simulation engine automatically

### Car Color Palettes with Rarity System
Vehicles spawn with random colors based on a rarity system using shader-based palette swapping.

**15 Colors organized by rarity:**
| Rarity | Colors | Spawn Chance |
|--------|--------|--------------|
| Common | White, Gray, Black, Red, Beige | 60% |
| Uncommon | Green, Blue, Cyan, Orange, Brown | 30% |
| Rare | Lime, Magenta, Pink, Purple, Yellow | 10% |

**Vehicle Type Color Rules:**
| Vehicle Type | Color Selection |
|--------------|-----------------|
| Cars (Sedan, Estate, Sport, Micro, Pickup) | Rarity-weighted (60% Common, 30% Uncommon, 10% Rare) |
| Jeepneys (Jeepney_1, Jeepney_2) | Equal chance for all 15 colors |
| Bus | Always White |

**How it works:**
- When `set_random_color()` is called, the system checks vehicle type first
- Cars roll for rarity (60%/30%/10%), then pick random color from that tier
- Jeepneys pick any of the 15 colors with equal probability
- Buses are always white
- Default color is White (Common)
- Uses shader-based palette swapping for efficient rendering
- Each vehicle gets a duplicated material so colors don't affect other vehicles

**API functions (in `scripts/entities/vehicle.gd`):**
- `set_random_color()` - Assign random color based on vehicle type and rarity rules
- `set_color_palette(VehicleColor.BLUE)` - Set specific color by enum
- `set_color_palette_index(index)` - Set color by index (0-14)
- `get_color_palette()` - Get current color enum (VehicleColor)
- `get_color_palette_index()` - Get current color index (0-14)
- `get_palette_count()` - Get total number of colors (15)
- `get_color_name()` - Get color name string ("WHITE", "BLUE", "MAGENTA", etc.)
- `get_color_rarity()` - Get rarity enum (ColorRarity.COMMON/UNCOMMON/RARE)
- `get_color_rarity_name()` - Get rarity name string ("Common", "Uncommon", "Rare")

**Enums (in `scripts/entities/vehicle.gd`):**
```gdscript
enum VehicleColor {
	WHITE, GRAY, BLACK, RED, BEIGE,      # Common (indices 0-4)
	GREEN, BLUE, CYAN, ORANGE, BROWN,    # Uncommon (indices 5-9)
	LIME, MAGENTA, PINK, PURPLE, YELLOW  # Rare (indices 10-14)
}

enum ColorRarity { COMMON, UNCOMMON, RARE }
```

**Files:**
- Shader: `shaders/palette_swap.tres` (VisualShader resource)
- Palette textures: `assets/cars/Cars Color Palette/gocars palette-*.png` (15 PNG files)
- Vehicle script: `scripts/entities/vehicle.gd` (contains all color palette code)

**Where `set_random_color()` is called:**
- `scenes/main.gd` in `_spawn_new_car()` - when spawning new cars during gameplay
- `scenes/main.gd` in `_respawn_test_vehicle()` - when respawning the test vehicle
- `scripts/core/level_manager.gd` in `_spawn_vehicle()` - when loading level vehicles

### Lane Driving System
Cars drive on the left side of the road to avoid head-on collisions:
- **Lane offset**: 25 pixels from road center
- **Direction-based**: Cars going RIGHT are offset UP (negative Y)
- **Allows passing**: Two cars going opposite directions can share the same road
- **Smaller hitboxes**: Collision shapes reduced to prevent easy crashes

### Road-Only Movement
Cars must stay on road tiles:
- **Valid roads**: Any road tile placed using the RoadTile system
- **Invalid terrain**: Grass, water, or any area without a road tile
- **Detection methods**: `front_road()`, `left_road()`, `right_road()` (short API names)
- **Penalty**: Moving onto non-road areas triggers crash and heart loss
- **Guideline system**: Cars follow pre-calculated paths through tiles based on connections

---

## Implemented Features Summary

| Feature | Status | Description |
|---------|--------|-------------|
| RoadTile Scene System | ✅ | Manual road connections with connection sprites |
| Guideline Path System | ✅ | Cars follow pre-calculated paths through tiles |
| Road Selection System | ✅ | Click roads to select, click adjacent to place/connect |
| Preview Tiles | ✅ | Shows ghost preview of where road will be placed |
| Protected Roads | ✅ | Spawn and destination roads cannot be removed |
| Road Cards System | ✅ | Consumable resource for map editing (per-level config) |
| Hearts System | ✅ | Lives with crash penalties |
| Live Map Editing | ✅ | Edit roads during gameplay |
| Crashed Cars as Obstacles | ✅ | Cars stay on map when crashed (crashed sprite) |
| Automatic Car Spawning | ✅ | New car every 15 seconds (8 vehicle types) |
| Car Color Palettes | ✅ | 15 colors with rarity system + vehicle type rules |
| Lane Driving | ✅ | Cars offset for right-hand traffic (25px) |
| Collision Detection | ✅ | Manual distance-based collision (40px threshold) |
| Short API Names | ✅ | `front_road()`, `at_end()`, etc. |
| Red Light Violations | ✅ | Running red lights costs hearts |
| Vehicle Types | ✅ | 8 types with different speeds/sizes |
| Level Timer | ✅ | Timer starts on level load, stops on win |
| Best Times | ✅ | Saves and displays best completion times |
| HeartsUI Component | ✅ | Animated heart sprites with configurable count |
| Multiple Destinations | ✅ | Cars can reach any destination parking spot |
| Multi-car Start | ✅ | All spawned cars start moving when Run clicked |
| Spawn Groups (A-D) | ✅ | Cars must park at matching group destinations |
| Wrong Parking Penalty | ✅ | Parking at wrong group costs 1 heart |
| Vehicle Stats Hover | ✅ | Shows Type, Group, Speed, Facing, State on hover |
| LevelSettings Config | ✅ | Per-level name and road building configuration |
| EnableBuilding Layer | ✅ | Per-tile build/remove permissions (3 levels) |
| Stoplight Tile Spawning | ✅ | Stoplights auto-spawn from stoplight tiles |
| Negative Coordinates | ✅ | Road building works at -1 x/y positions |
| 8-Column Tileset | ✅ | New tileset with groups A-D and stoplights |

---

## HeartsUI Component

The HeartsUI component displays animated hearts for the level's lives system.

### Required Asset
Place your heart sprite sheet at: `assets/ui/heart.png`

**Sprite Layout (4 columns, 1 row):**
- Column 0: Full heart
- Column 1: Transition frame 1
- Column 2: Transition frame 2
- Column 3: Broken heart

### Using in Levels
1. Add `HeartsUI` scene instance to your level scene
2. Set the `HeartCount` child Label's text to the number of hearts (e.g., "3", "5", "10")
3. The hearts will automatically animate when lost

**Example level_01.tscn:**
```
[node name="HeartsUI" parent="." instance=ExtResource("3_hearts_ui")]

[node name="HeartCount" parent="HeartsUI" index="0"]
text = "3"
```

### HeartsUI Script API
```gdscript
hearts_ui.lose_heart()       # Animate losing one heart
hearts_ui.gain_heart()       # Restore one heart
hearts_ui.reset_hearts()     # Reset all hearts to max
hearts_ui.get_hearts()       # Get current heart count
hearts_ui.get_max_hearts()   # Get maximum hearts
hearts_ui.set_max_hearts(n)  # Set new max and reset
```

---

## Python Code Examples (Short API)

### Example 1: Basic Navigation
```python
if car.front_road():
	car.move(3)
else:
	car.turn("right")
```

### Example 2: Intersection Logic
```python
if car.front_road():
	car.go()
elif car.left_road():
	car.turn("left")
	car.go()
elif car.right_road():
	car.turn("right")
	car.go()
else:
	car.stop()
```

### Example 3: Obstacle Avoidance
```python
if car.front_crash():
	if car.left_road():
		car.turn("left")
	elif car.right_road():
		car.turn("right")
elif car.front_car():
	car.stop()
elif car.front_road():
	car.go()
```

### Example 4: Stoplight Handling
```python
# REQUIRED! Cars don't auto-stop at red lights
if stoplight.is_red():
    car.stop()
elif stoplight.is_yellow():
    car.stop()
else:
    car.go()
```

### Example 5: Full Navigation Loop
```python
while not car.at_end():
    if stoplight.is_red():
        car.stop()
    elif car.front_crash():
        if car.left_road():
            car.turn("left")
        elif car.right_road():
            car.turn("right")
    elif car.front_road():
        car.go()
    else:
        car.stop()
```

---

## Game Controls Summary

| Action | Input | Notes |
|--------|-------|-------|
| Select road | Left-click on road | Highlights road yellow, shows preview |
| Place road | Left-click on preview | Costs 1 road card, auto-connects to selected |
| Connect roads | Left-click adjacent road | FREE - no card cost, just connects |
| Deselect | Left-click selected road | Exit edit mode |
| Remove road | Right-click on road | Refunds 1 road card (except spawn/destination) |
| Run code | Run Code button or F5 | Starts car spawning every 15 seconds |
| Pause/Resume | Space | Pauses simulation and spawning |
| Reset level | R | Clears crashed cars, resets hearts, stops spawning |
| Speed up | + or = | 2x or 4x speed |
| Slow down | - | 0.5x speed |
| Step | F10 | Execute one line |
| Move camera | WASD or Arrow keys | Pan the camera around |
| Toggle help | F1 | Show/hide Python commands reference |

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
- **Defensive programming**: Must check stoplight state before proceeding (no auto-stop!)
