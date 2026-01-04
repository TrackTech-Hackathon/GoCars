# GoCars Implementation Checklist

This document tracks all implementation tasks organized by development phase.
Check off items as they are completed.

---

## Phase 1: Foundation (Core Systems Setup)

### Project Infrastructure
- [x] **TECH-001** Create folder structure (assets/, scenes/, scripts/, tests/, data/)
- [x] Set up test runner script (`run_tests.sh`)
- [x] Create main scene (`scenes/main.tscn`)

### Core Systems - Python Parser (P0)
- [x] **TECH-003** Create `scripts/core/python_parser.gd`
  - [x] **Tokenizer** - Convert source to tokens
	- [x] Keywords: if, elif, else, while, for, in, range, and, or, not, True, False, break
	- [x] Identifiers: car, stoplight, boat, user variables
	- [x] Numbers: integers and floats (0, 42, 3.14, 0.5)
	- [x] Strings: "text" and 'text'
	- [x] Operators: +, -, *, /, ==, !=, <, >, <=, >=, =
	- [x] Delimiters: (, ), :, ,
	- [x] NEWLINE, INDENT, DEDENT tokens
	- [x] Comments: # single-line comments
  - [x] **AST Builder** - Parse tokens into Abstract Syntax Tree
	- [x] Expression statements (function calls)
	- [x] Assignment statements (variable = value)
	- [x] If/elif/else statements with indented blocks
	- [x] While loop statements
	- [x] For loop statements with range()
	- [x] Break statement
	- [x] Binary expressions (arithmetic, comparison, logical)
	- [x] Unary expressions (not, -)
	- [x] Method calls (object.method(args))
  - [x] **Indentation Handler**
	- [x] Track indentation levels (4 spaces or 1 tab = 1 level)
	- [x] Emit INDENT tokens when level increases
	- [x] Emit DEDENT tokens when level decreases
	- [x] Detect mismatched indentation errors
  - [x] **Error System** - Python-style error messages
	- [x] SyntaxError with line numbers
	- [x] IndentationError for block issues
	- [x] NameError for undefined variables
	- [x] TypeError for wrong argument types
	- [x] AttributeError for invalid methods
- [x] Write tests for Python parser (`tests/python_parser.test.gd`) - 84 tests passing

### Core Systems - Python Interpreter (P0)
- [x] **TECH-002** Create `scripts/core/python_interpreter.gd`
  - [x] AST node executor (walks AST and executes)
  - [x] Variable scope management (store/retrieve variables)
  - [x] Expression evaluator (arithmetic, comparison, logical)
  - [x] Condition evaluator for if/elif/else
  - [x] While loop executor with iteration limits
  - [x] For loop executor with range()
  - [x] Break statement handler
  - [x] Infinite loop detection (10-second timeout)
  - [x] Runtime error generation
- [x] Write tests for Python interpreter (`tests/python_interpreter.test.gd`) - 63 tests passing

### Core Systems - Simulation Engine (P0)
- [x] Create `scripts/core/simulation_engine.gd`
  - [x] Command queue executor (receives commands from interpreter)
  - [x] Vehicle position management
  - [x] Velocity/movement system
  - [x] Basic collision detection (vehicle-vehicle)
  - [x] Boundary collision detection
  - [x] Timing/synchronization system
  - [x] Integrated with PythonParser and PythonInterpreter
- [ ] Write tests for simulation engine (`tests/simulation_engine.test.gd`)

### Basic Vehicle System (P0)
- [x] Create `scripts/entities/vehicle.gd`
  - [x] Implement forward movement (`go()`)
  - [x] Implement stop functionality (`stop()`)
  - [x] Implement basic physics (position, velocity, rotation)
  - [x] Add destination tracking
- [ ] Create placeholder vehicle sprite

**Phase 1 Milestone:** Car moves forward based on `car.go()` Python code input - **COMPLETE**

---

## Phase 2: Core Mechanics

### Python Language Features (P0)
- [x] **CORE-003** Implement Python language constructs
  - [x] **Variables**
	- [x] Variable assignment (x = value)
	- [x] Number, boolean, string storage
	- [x] Variable usage in expressions
	- [x] Undefined variable detection (NameError)
  - [x] **Conditionals**
	- [x] `if condition:` with indented block
	- [x] `elif condition:` clauses
	- [x] `else:` clause
	- [x] Nested conditionals
  - [x] **Comparison Operators**
	- [x] == (equal), != (not equal)
	- [x] < (less than), > (greater than)
	- [x] <= (less than or equal), >= (greater than or equal)
  - [x] **Logical Operators**
	- [x] `and` - both conditions True
	- [x] `or` - at least one condition True
	- [x] `not` - invert condition
  - [x] **While Loops**
	- [x] `while condition:` with indented block
	- [x] Break statement support
	- [x] Infinite loop protection (10s timeout)
  - [x] **For Loops**
	- [x] `for i in range(n):` syntax
	- [x] Loop variable access
	- [x] Nested loop support

### Vehicle Control Functions (P0)
- [x] **CORE-002** Complete Python Vehicle API
  - [x] **Basic Movement**
	- [x] `car.go()` - continuous forward movement
	- [x] `car.stop()` - immediate stop
	- [x] `car.turn_left()` - 90° left turn at intersection
	- [x] `car.turn_right()` - 90° right turn at intersection
	- [x] `car.wait(seconds)` - pause for N seconds (float)
  - [x] **Enhanced Movement (NEW)**
	- [x] `car.turn(direction)` - immediate 90° turn ("left" or "right")
	- [x] `car.move(tiles)` - move forward N tiles (1-100)
  - [x] **Road Detection (NEW)**
	- [x] `car.is_front_road()` - is there road ahead?
	- [x] `car.is_left_road()` - is there road to left?
	- [x] `car.is_right_road()` - is there road to right?
  - [x] **Car Detection (NEW)**
	- [x] `car.is_front_car()` - any car ahead (active or crashed)?
	- [x] `car.is_front_crashed_car()` - crashed car ahead (obstacle)?
  - [x] **Speed Control**
	- [x] `car.set_speed(value)` - speed multiplier 0.5 to 2.0
	- [x] `car.get_speed()` - returns current speed multiplier
  - [x] **State Queries (return bool)**
	- [x] `car.is_moving()` - is car currently moving?
	- [x] `car.is_blocked()` - is path obstructed?
	- [x] `car.is_at_intersection()` - is car at intersection?
	- [x] `car.is_at_destination()` - has car reached destination?
  - [x] **Distance Queries (return float)**
	- [x] `car.distance_to_destination()` - distance to destination
	- [x] `car.distance_to_intersection()` - distance to next intersection

### Traffic Light System (P0)
- [x] Create `scripts/entities/stoplight.gd`
  - [x] **Control Methods**
	- [x] `stoplight.set_red()` - change to red
	- [x] `stoplight.set_yellow()` - change to yellow
	- [x] `stoplight.set_green()` - change to green
  - [x] **State Queries (return bool)**
	- [x] `stoplight.is_red()` - is light red?
	- [x] `stoplight.is_yellow()` - is light yellow?
	- [x] `stoplight.is_green()` - is light green?
  - [x] **State Getter (return string)**
	- [x] `stoplight.get_state()` - returns "red", "yellow", or "green"
  - [x] Implement state machine transitions
  - [x] Car stopping at red lights behavior
- [ ] Create traffic light sprite (2-way and 4-way variants)
- [x] Write tests for stoplight (`tests/stoplight.test.gd`) - 7 tests passing

### Turn Mechanics
- [x] Implement intersection detection
- [x] Implement turn queuing at intersections
- [x] Handle 90-degree rotations smoothly

### Extended Game Mechanics (NEW - CORE-005)
- [x] **Road Cards System**
  - [x] Players have limited road cards (default: 10)
  - [x] Left-click to place road (costs 1 card)
  - [x] Right-click to remove road (refunds 1 card)
  - [x] Live editing during gameplay
- [x] **Hearts/Lives System**
  - [x] Players start with hearts (default: 10)
  - [x] Lose 1 heart on crash or collision
  - [x] Game over when hearts reach 0
- [x] **Crashed Cars as Obstacles**
  - [x] Crashed cars remain on map (don't disappear)
  - [x] Visual feedback (darkened/grayed)
  - [x] Vehicle state system (Active=1, Crashed=0)
- [x] **Automatic Car Spawning**
  - [x] New cars spawn every 15 seconds
  - [x] All spawned cars execute same code
  - [x] Spawning stops on reset
- [x] **Stoplight Control Panel**
  - [x] Manual UI controls (Red/Yellow/Green buttons)
  - [x] State display
- [x] **Road-Only Movement**
  - [x] Cars crash when moving off-road
  - [x] Road detection methods work correctly

### Simulation Controls (P0)
- [x] **CORE-004** Create playback control system
  - [x] Run button - execute Python code (F5 or Ctrl+Enter)
  - [x] Pause button - freeze simulation (Space)
  - [x] Resume - continue simulation (Space toggle)
  - [x] Fast-Forward 2x - double speed (+ or =)
  - [x] Fast-Forward 4x - quadruple speed (Ctrl + +)
  - [x] Slow-Motion 0.5x - half speed (-)
  - [x] Fast Retry - instant restart (R or Ctrl+R)
  - [x] Step mode - execute one line at a time (F10)
  - [x] Current line highlighting in editor

### Win/Lose Conditions (P0)
- [x] **MODE-001** Implement win condition detection
  - [x] All cars reached destination
  - [x] Trigger victory UI
- [x] Implement fail condition detection
  - [x] Car crash (collision) - uses hearts system
  - [x] Timer expired
  - [x] Car exits map boundary
  - [x] Infinite loop detected (10s timeout)
  - [x] Code error/exception
  - [x] Trigger failure UI with reason

### Level Manager (P0)
- [x] Create `scripts/core/level_manager.gd`
  - [x] Load level configurations from JSON
  - [x] Spawn vehicles at designated positions
  - [x] Spawn traffic elements
  - [x] Track win/lose states
  - [x] Calculate star ratings
  - [x] Handle level transitions

**Phase 2 Milestone:** Full gameplay loop with Python conditionals and loops functional - **COMPLETE**

---

## Phase 3: Content Creation

### Tutorial Levels - Functions (P0)
- [x] **LVL-001** Create Tutorial Map Set (T1-T5)
  - [x] **T1: "First Drive"** - teaches `car.go()`, function calls
	- [x] Layout: Straight road, single car, one destination
	- [x] Solution: `car.go()`
  - [x] **T2: "Stop Sign"** - teaches `car.stop()`, sequencing
	- [x] Layout: Road with marked stop point before destination
	- [x] Solution: `car.go()`, `car.wait(2)`, `car.stop()`, etc.
  - [x] **T3: "Turn Ahead"** - teaches `car.turn_left()`, `car.turn_right()`
	- [x] Layout: L-shaped or T-intersection road
	- [x] Solution: Movement + turn combination
  - [x] **T4: "Red Light, Green Light"** - teaches traffic light control
	- [x] Layout: Intersection with controllable stoplight
	- [x] Solution: `stoplight.set_green()`, `car.go()`, timing
  - [x] **T5: "Traffic Jam"** (Tutorial Finale) - combines all concepts
	- [x] Layout: Multiple cars, intersection with stoplight
	- [x] Solution: Multi-entity coordination

### Iloilo City Levels - Variables & Conditionals (P0)
- [x] **LVL-002** Create Iloilo City Map Set (C1-C5)
  - [x] **C1: "Smallville Plaza"** - teaches variables
	- [x] Location: Smallville, Iloilo
	- [x] Challenge: Use variables for speed control
	- [x] Example: `my_speed = 1.5`, `car.set_speed(my_speed)`
  - [x] **C2: "Esplanade Evening"** - teaches `if` statements
	- [x] Location: Iloilo Esplanade
	- [x] Challenge: React to traffic light state
	- [x] Example: `if stoplight.is_green(): car.go()`
  - [x] **C3: "Jaro Crossroads"** - teaches `if-elif-else`
	- [x] Location: Jaro, Iloilo City
	- [x] Challenge: Handle multiple light states
	- [x] Example: Full if-elif-else chain
  - [x] **C4: "La Paz Market"** - teaches logical operators
	- [x] Location: La Paz, Iloilo City
	- [x] Challenge: Multiple conditions with `and`, `or`, `not`
  - [x] **C5: "Molo Mansion Drive"** - teaches comparison operators
	- [x] Location: Molo, Iloilo City
	- [x] Challenge: Distance-based decisions
	- [x] Example: `if car.distance_to_destination() > 100:`

### Water/Port Levels - Loops (P1)
- [x] **LVL-003** Create Water/Port Map Set (W1-W5)
  - [x] **W1: "Iloilo River Port"** - teaches `while` loops
	- [x] Location: Iloilo River Port
	- [x] Challenge: Keep driving while not at destination
	- [x] Example: `while not car.is_at_destination(): car.go()`
  - [x] **W2: "Ortiz Wharf"** - teaches `while` with conditions
	- [x] Location: Ortiz Wharf, Iloilo
	- [x] Challenge: Combine while and if for stoplight handling
	- [x] Example: `while not car.is_at_destination(): if stoplight.is_red(): ...`
  - [x] **W3: "Fort San Pedro Dock"** - teaches `for` loops with `range()`
	- [x] Location: Fort San Pedro, Iloilo
	- [x] Challenge: Repeat actions N times using car.move()
	- [x] Example: `for i in range(6): car.move(1)`
  - [x] **W4: "Parola Lighthouse"** - teaches nested loops
	- [x] Location: Parola, Iloilo City
	- [x] Challenge: Use loops inside loops for sections
	- [x] Example: `for section in range(3): for step in range(2): ...`
  - [x] **W5: "Guimaras Ferry Terminal"** - teaches break statement
	- [x] Location: Guimaras Ferry Terminal, Iloilo
	- [x] Challenge: Use break to exit loop when destination reached
	- [x] Example: `while True: ... if car.is_at_destination(): break`

### Boat Mechanics (P1)
- [x] Create `scripts/entities/boat.gd`
  - [x] Implement boat capacity (configurable, default 3 cars)
  - [x] Auto-departure (when full)
  - [x] Boat states (DOCKED, DEPARTING, TRAVELING, ARRIVING)
  - [x] Vehicle boarding/disembarking system
  - [x] **Python API:**
	- [x] `boat.depart()` - force immediate departure
	- [x] `boat.is_ready()` - is boat docked and ready?
	- [x] `boat.is_full()` - is boat at capacity?
	- [x] `boat.get_passenger_count()` - number of cars on board

### Vehicle Variety (P1)
- [x] **VEH-001** Implement vehicle types
  - [x] Sedan - Speed 1.0x, Size 1.0
  - [x] SUV - Speed 0.9x, Size 1.2
  - [x] Motorcycle - Speed 1.3x, Size 0.5 (can lane split)
  - [x] Jeepney - Speed 0.7x, Size 1.5 (carries multiple passengers)
  - [x] Truck/Van - Speed 0.6x, Size 2.0 (longer stopping distance)
  - [x] Tricycle - Speed 0.7x, Size 0.7 (tight turn radius)
- [x] Implement random vehicle generation per level
- [ ] Create vehicle sprites for each type (using color tints for now)

### Level Data Format
- [x] Create `data/levels/` folder structure
- [x] Define JSON level format with Python concepts info
- [x] Create level JSON files for all 15 levels
  - [x] T1-T5: Tutorial levels (functions, sequencing)
  - [x] C1-C5: Iloilo City levels (variables, conditionals)
  - [x] W1-W5: Water/Port levels (loops, break)

**Phase 3 Milestone:** All 15 campaign levels created with Python code - **COMPLETE**

---

## Phase 4: Polish & UI

### Main Menu (P0)
- [ ] **UI-001** Create Main Menu Screen
  - [ ] Game logo with animation
  - [ ] Campaign button → Level Select
  - [ ] Infinite Mode button → Mode Start
  - [ ] Collections button → Vehicle Gallery
  - [ ] Settings button → Options
  - [ ] Credits button → Attribution
  - [ ] Exit button
  - [ ] Animated background (traffic scene)

### Gameplay Interface (P0)
- [ ] **UI-002** Create VS Code-Style HUD
  - [ ] **Left Panel: File Explorer** (120px fixed)
	- [ ] Display entities as .py files (car.py, stoplight.py, boat.py)
	- [ ] Click to select entity
	- [ ] Visual indicators for active/inactive
	- [ ] Hierarchical display for multiple entities
  - [ ] **Main View: Game World** (flexible width)
	- [ ] 2D map visualization
	- [ ] Real-time code execution visualization
	- [ ] Entity labels showing file names
	- [ ] Hover highlighting for interactive elements
  - [ ] **Bottom Panel: Python Code Editor** (200px, collapsible)
	- [ ] Text input area for Python code
	- [ ] Line numbers
	- [ ] **Python Syntax Highlighting:**
	  - [ ] Keywords (purple #C586C0): if, else, while, for, and, or, not
	  - [ ] Built-in Constants (blue #569CD6): True, False
	  - [ ] Functions/Methods (yellow #DCDCAA): go(), stop(), is_red()
	  - [ ] Strings (orange #CE9178): "red", 'green'
	  - [ ] Numbers (light green #B5CEA8): 1, 2.5, 0.5
	  - [ ] Comments (green #6A9955): # comment
	  - [ ] Variables (light blue #9CDCFE): speed, wait_time
	  - [ ] Operators (white #D4D4D4): =, ==, +, -
	- [ ] Indentation guides for blocks
	- [ ] Real-time Python error feedback
	- [ ] Current executing line highlighting
  - [ ] **Top Bar:** Level info, lives, timer
  - [ ] **Playback Controls Toolbar:**
	- [ ] Run (F5), Pause (Space), 2x (+), 4x (Ctrl++), 0.5x (-), Retry (R), Step (F10)

### Level Select Screen (P0)
- [ ] **UI-003** Create Level Select
  - [ ] Back button
  - [ ] **Tutorial section (T1-T5)** - "Learn Python Basics"
	- [ ] Concept labels: func, seq, turn, light, combo
  - [ ] **Iloilo City section (C1-C5)** - "Variables & Conditionals"
	- [ ] Concept labels: vars, if, elif, logic, comp
  - [ ] **Water/Port section (W1-W5)** - "Loops & Advanced"
	- [ ] Concept labels: while, cond, for, nest, algo
  - [ ] Level tiles showing:
	- [ ] Star ratings for completed
	- [ ] Lock icon for locked
	- [ ] Python concept taught
  - [ ] Total stars counter
  - [ ] Python Concepts progress (X/8)

### Victory/Defeat Screens (P0)
- [ ] **UI-004** Create Result Screens
  - [ ] Victory screen
	- [ ] Star rating display (1-3 stars)
	- [ ] Time and lines of code stats
	- [ ] Code efficiency bonus indicator
	- [ ] Retry button
	- [ ] Next level button
	- [ ] Level select button
  - [ ] Defeat screen
	- [ ] Python-style error display (RuntimeError, etc.)
	- [ ] Failure reason display
	- [ ] Retry button
	- [ ] Skip button (optional)
	- [ ] Level select button

### Color Scheme Implementation (VS Code Dark Theme)
- [ ] Background: Dark gray (#1E1E1E)
- [ ] Panel borders: Subtle gray (#3C3C3C)
- [ ] Text: Light gray (#D4D4D4)
- [ ] Accent: Blue (#007ACC)

### Infinite/Survival Mode (P1)
- [ ] **MODE-002** Implement Infinite Mode
  - [ ] Lives system (3 starting lives)
	- [ ] Car crash: -1 life
	- [ ] Timer expired: -1 life
	- [ ] Code error/exception: -1 life
  - [ ] Scoring system
	- [ ] +100 base per successful delivery
	- [ ] +10 per consecutive streak
	- [ ] +50 max speed bonus
	- [ ] +25 code efficiency bonus (fewer lines)
	- [ ] +15 loop usage bonus
  - [ ] Difficulty scaling per wave
	- [ ] Waves 1-3: 1-2 vehicles, generous timers, basic functions only
	- [ ] Waves 4-6: 2-3 vehicles, moderate timers, conditionals helpful
	- [ ] Waves 7-10: 3-4 vehicles, tight timers, loops recommended
	- [ ] Waves 11+: 4+ vehicles, shortest timers, complex logic required
  - [ ] Game Over screen with final score
  - [ ] High score persistence

### Vehicle Collection System (P1)
- [ ] **VEH-001** Collections Menu
  - [ ] Gallery view of vehicle types
  - [ ] Locked/unlocked states
  - [ ] Statistics display (speed, size, abilities)
  - [ ] Vehicle lore/description
  - [ ] Unlock progress tracking

### Vehicle Info Display (P2)
- [ ] **VEH-002** Interactive Info Cards
  - [ ] Trigger on click/hover
  - [ ] Vehicle model and thumbnail
  - [ ] Speed/status indicator
  - [ ] Passenger name (random Filipino name)
  - [ ] Destination info
  - [ ] Code file reference
  - [ ] Dismissible popup design

### Save System (P0)
- [ ] Create `scripts/systems/save_manager.gd`
  - [ ] Level completion status
  - [ ] Star ratings per level
  - [ ] High scores for Infinite mode
  - [ ] Vehicle collection unlocks
  - [ ] User preferences/settings
  - [ ] Auto-save on level completion

### Score Manager (P1)
- [ ] Create `scripts/systems/score_manager.gd`
  - [ ] Score calculation
  - [ ] Star rating calculation
  - [ ] Streak tracking
  - [ ] Code efficiency analysis

### Settings Menu
- [ ] Audio settings (music/SFX volume)
- [ ] Controls reference
- [ ] Accessibility options

### Credits Screen
- [ ] Team attribution
- [ ] Asset credits
- [ ] Special thanks

**Phase 4 Milestone:** Complete game with all modes and polished UI

---

## Phase 5: Testing & Submission

### Python Parser Testing
- [ ] Test all token types correctly identified
- [ ] Test AST building for all statement types
- [ ] Test indentation handling edge cases
- [ ] Test all Python-style error messages
- [ ] Test infinite loop detection

### Bug Testing
- [ ] Test all 15 campaign levels start to finish
- [ ] Test Infinite mode for 10+ waves
- [ ] Test all vehicle functions work correctly
- [ ] Test all Python syntax combinations
- [ ] Test all UI screens and navigation
- [ ] Test save/load functionality
- [ ] Test edge cases (empty code, invalid input, etc.)

### Performance Optimization
- [ ] Verify stable 60 FPS on minimum spec
- [ ] Test level load times (< 5 seconds target)
- [ ] Test code parse time (< 100ms target)
- [ ] Check memory usage (< 500MB RAM target)
- [ ] Profile and optimize bottlenecks

### Final Polish
- [ ] Game balance adjustments
- [ ] Python error message clarity review
- [ ] Visual consistency check
- [ ] Audio levels balancing
- [ ] Syntax highlighting consistency with VS Code

### Build Generation
- [ ] Create Windows executable (.exe)
- [ ] Create ZIP archive
- [ ] Verify executable size (< 200MB target)
- [ ] Test on clean Windows 10 machine

### Documentation
- [ ] Update README with final instructions
- [ ] Verify code comments are complete
- [ ] Screenshot capture for submission

### Submission Preparation
- [ ] Final repository cleanup
- [ ] Prepare 10-15 minute demo script
- [ ] Test demo flow without interruption

**Phase 5 Milestone:** Submission-ready build uploaded

---

## Advanced Features (P2 - If Time Permits)

### Advanced Python Functions
- [ ] `car.follow(target_car)` - follow another car

### Audio Assets (P2)
- [ ] Main menu music
- [ ] Gameplay ambient music
- [ ] Engine sounds (loop)
- [ ] Crash sound effect
- [ ] Success sound effect
- [ ] Failure sound effect
- [ ] Button click sound
- [ ] Level complete fanfare

### Visual Polish (P2)
- [ ] Smooth animations for vehicles
- [ ] Traffic light transition effects
- [ ] Destination arrival effects
- [ ] Crash effects
- [ ] UI hover/press states

---

## Asset Checklist

### Sprites Needed
- [ ] Sedan (4 color variants)
- [ ] SUV (3 color variants)
- [ ] Motorcycle (3 color variants)
- [ ] Jeepney (3 design variants)
- [ ] Truck (2 color variants)
- [ ] Tricycle (2 color variants)
- [ ] Boat (2 variants)
- [ ] Traffic light (2-way)
- [ ] Traffic light (4-way)
- [ ] Road tiles (straight, curved, intersections)
- [ ] Destination marker
- [ ] Spawn point marker

### Landmark Backgrounds
- [ ] Jaro Cathedral
- [ ] Iloilo Esplanade
- [ ] SM City Iloilo
- [ ] Calle Real
- [ ] Molo Church

### UI Elements
- [ ] Game logo
- [ ] Menu buttons (normal/hover/pressed)
- [ ] File icons (.py)
- [ ] Playback control icons
- [ ] Star icons (filled/empty)
- [ ] Lock icon
- [ ] Heart/life icon

---

## Progress Summary

| Phase | Status | Completion |
|-------|--------|------------|
| Phase 1: Foundation | Complete | 100% |
| Phase 2: Core Mechanics | Complete | 100% |
| Phase 3: Content Creation | Complete | 100% |
| Phase 4: Polish & UI | Not Started | 0% |
| Phase 5: Testing & Submission | Not Started | 0% |

---

## Bug Fixes Log

### January 2, 2026 - Pause/Resume Fix in Simulation Engine

**Issue:** Pressing Space pauses the game but pressing Space again doesn't resume.

**Root Cause:**
- Line 54: `process_mode = Node.PROCESS_MODE_PAUSABLE`
- Line 261: `get_tree().paused = true` when pausing
- When tree is paused, SimulationEngine is ALSO paused, so `_unhandled_input()` never receives the Space key!

**Fix Applied:**
- Changed `process_mode` from `PROCESS_MODE_PAUSABLE` to `PROCESS_MODE_ALWAYS` (line 54)

**Files Modified:**
- `scripts/core/simulation_engine.gd`

---

### January 2, 2026 - Type Casting Fix in Stoplight

**Issue:** `stoplight.gd` had type errors preventing the game from running
- Line 30-32: Variables `_red_light`, `_yellow_light`, `_green_light` were typed as `Node2D`
- Line 176: Function parameter `light_node` was typed as `Node2D`
- Problem: `ColorRect` extends `Control`, not `Node2D`, causing type mismatch errors

**Error Messages:**
```
SCRIPT ERROR: Parse Error: Expression is of type "Node2D" so it can't be of type "ColorRect".
SCRIPT ERROR: Invalid cast. Cannot convert from "Node2D" to "ColorRect".
```

**Fix Applied:**
- Changed variable types from `Node2D` to `Node` (lines 30-32)
- Changed function parameter from `Node2D` to `Node` (line 176)

**Files Modified:**
- `scripts/entities/stoplight.gd`

**Verification:**
- All stoplight tests pass (7 tests)
- Game runs without errors in headless mode
- Game launches successfully with window

---

---

### January 3, 2026 - Python Parser and Interpreter Implementation

**New Files Created:**
- `scripts/core/python_parser.gd` (~930 lines)
  - Full Python tokenizer with support for keywords, numbers, strings, operators
  - INDENT/DEDENT token generation for Python block structure
  - Complete AST builder for all statement and expression types
  - Python-style error messages (SyntaxError, IndentationError)

- `scripts/core/python_interpreter.gd` (~465 lines)
  - AST executor with variable scope management
  - Expression evaluation (arithmetic, comparison, logical)
  - Control flow (if/elif/else, while, for, break)
  - Game object method calling
  - Infinite loop detection (10-second timeout, 10000 iteration limit)
  - Runtime error generation (NameError, TypeError, AttributeError, ZeroDivisionError)

- `tests/python_parser.test.gd` (~455 lines) - 84 tests
- `tests/python_interpreter.test.gd` (~315 lines) - 63 tests

**Files Modified:**
- `scripts/core/simulation_engine.gd`
  - Added PythonParser and PythonInterpreter integration
  - New `_execute_code_python()` function

**Test Results:**
- All 3 test files pass (python_parser, python_interpreter, stoplight)
- Total: 154+ tests passing

---

### January 3, 2026 - Phase 2 Simulation Controls Complete

**New Features Implemented:**

1. **Keyboard Shortcuts**
   - F5 - Run code
   - Ctrl+Enter - Run code
   - R / Ctrl+R - Fast retry (reset level)
   - Space - Pause/Resume toggle
   - + or = - Speed up (2x)
   - Ctrl++ - Fast-forward (4x)
   - - (minus) - Slow motion (0.5x)
   - F10 - Step mode (execute one step)

2. **Current Line Highlighting**
   - Code editor highlights the currently executing line
   - Line numbers enabled in code editor
   - Execution errors show the error line

3. **Win/Lose Conditions**
   - Win: All active cars reach destination
   - Fail: Hearts reach 0 (crashes), timer expired, car leaves map, infinite loop, code errors
   - Detailed victory/defeat popups with stats

4. **Level Manager Integration**
   - Level Manager connected to main scene
   - Star rating calculation
   - Level transitions (Next button)

**Files Modified:**
- `scenes/main.gd` - Added keyboard shortcuts, line highlighting, level manager integration
- `scripts/core/simulation_engine.gd` - Added execution_line_changed signal, fixed crash handling

**Test Results:**
- All existing tests still pass
- Game runs without errors

---

---

### January 3, 2026 - Phase 3 Content Creation Complete

**New Level Files Created:**

1. **Tutorial Levels (T1-T5)** - Already existed, verified complete
   - T1: First Drive - `car.go()`
   - T2: Stop Sign - `car.stop()`, `car.wait()`
   - T3: Turn Ahead - `car.turn_left()`, `car.turn_right()`
   - T4: Red Light, Green Light - stoplight control
   - T5: Traffic Jam - multi-entity coordination

2. **Iloilo City Levels (C1-C5)** - New files created
   - C1: Smallville Plaza - variables and assignment
   - C2: Esplanade Evening - if statements
   - C3: Jaro Crossroads - if/elif/else
   - C4: La Paz Market - logical operators (and/or/not)
   - C5: Molo Mansion Drive - comparison operators

3. **Water/Port Levels (W1-W5)** - New files created
   - W1: Iloilo River Port - while loops
   - W2: Ortiz Wharf - while with conditions
   - W3: Fort San Pedro Dock - for loops with range()
   - W4: Parola Lighthouse - nested loops
   - W5: Guimaras Ferry Terminal - break statement

**New Entity Created:**
- `scripts/entities/boat.gd` (~200 lines)
  - Boat states: DOCKED, DEPARTING, TRAVELING, ARRIVING
  - Configurable capacity (default 3 vehicles)
  - Vehicle boarding/disembarking system
  - Python API: depart(), is_ready(), is_full(), get_passenger_count()
  - Signals: boat_departed, boat_arrived, vehicle_boarded, vehicle_disembarked

**Files Created:**
- `data/levels/c1.json` through `c5.json`
- `data/levels/w1.json` through `w5.json`
- `scripts/entities/boat.gd`

---

---

### January 4, 2026 - Car Off-Road Crash Bug Fix

**Issue:** Car was crashing as "off-road" even though it appeared to be on a valid road tile.

**Root Cause:**
- Mismatch between car spawn position (pixel coordinates) and road tiles (tile coordinates)
- Car spawn position was `Vector2(100, 300)` (arbitrary pixel values)
- Road was at tile row 4 (tile Y=4 means pixel Y = 4*64 = 256 to 320)
- Car Y=300 was close but not tile-aligned

**Fix Applied:**
- Aligned car spawn position to tile centers
- Tile (1, 4) center = `Vector2(1*64+32, 4*64+32)` = `Vector2(96, 288)`
- Updated `car_spawn_position` in main.gd from `Vector2(100, 300)` to `Vector2(96, 288)`
- Updated all level JSON files (C1-C5, W1-W5) to use tile-center positions:
  - Car position: `[96, 288]` (tile column 1, row 4)
  - Destination: `[736, 288]` (tile column 11, row 4) or appropriate end tiles

**Files Modified:**
- `scenes/main.gd` - car spawn position, reset position, respawn position
- `data/levels/c1.json` through `c5.json` - car and stoplight positions
- `data/levels/w1.json` through `w5.json` - car, stoplight, and intersection positions

**Coordinate Reference:**
- Tile center formula: `(tile_x * 64 + 32, tile_y * 64 + 32)`
- Default road is at tile row 4, columns 0-11
- Tile (1, 4) = (96, 288) - start position
- Tile (11, 4) = (736, 288) - end destination

---

*Last Updated: January 4, 2026*
