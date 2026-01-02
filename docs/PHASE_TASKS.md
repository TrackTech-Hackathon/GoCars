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
- [ ] **TECH-003** Create `scripts/core/python_parser.gd`
  - [ ] **Tokenizer** - Convert source to tokens
	- [ ] Keywords: if, elif, else, while, for, in, range, and, or, not, True, False, break
	- [ ] Identifiers: car, stoplight, boat, user variables
	- [ ] Numbers: integers and floats (0, 42, 3.14, 0.5)
	- [ ] Strings: "text" and 'text'
	- [ ] Operators: +, -, *, /, ==, !=, <, >, <=, >=, =
	- [ ] Delimiters: (, ), :, ,
	- [ ] NEWLINE, INDENT, DEDENT tokens
	- [ ] Comments: # single-line comments
  - [ ] **AST Builder** - Parse tokens into Abstract Syntax Tree
	- [ ] Expression statements (function calls)
	- [ ] Assignment statements (variable = value)
	- [ ] If/elif/else statements with indented blocks
	- [ ] While loop statements
	- [ ] For loop statements with range()
	- [ ] Break statement
	- [ ] Binary expressions (arithmetic, comparison, logical)
	- [ ] Unary expressions (not, -)
	- [ ] Method calls (object.method(args))
  - [ ] **Indentation Handler**
	- [ ] Track indentation levels (4 spaces or 1 tab = 1 level)
	- [ ] Emit INDENT tokens when level increases
	- [ ] Emit DEDENT tokens when level decreases
	- [ ] Detect mismatched indentation errors
  - [ ] **Error System** - Python-style error messages
	- [ ] SyntaxError with line numbers
	- [ ] IndentationError for block issues
	- [ ] NameError for undefined variables
	- [ ] TypeError for wrong argument types
	- [ ] AttributeError for invalid methods
- [ ] Write tests for Python parser (`tests/python_parser.test.gd`)

### Core Systems - Python Interpreter (P0)
- [ ] **TECH-002** Create `scripts/core/python_interpreter.gd`
  - [ ] AST node executor (walks AST and executes)
  - [ ] Variable scope management (store/retrieve variables)
  - [ ] Expression evaluator (arithmetic, comparison, logical)
  - [ ] Condition evaluator for if/elif/else
  - [ ] While loop executor with iteration limits
  - [ ] For loop executor with range()
  - [ ] Break statement handler
  - [ ] Infinite loop detection (10-second timeout)
  - [ ] Runtime error generation
- [ ] Write tests for Python interpreter (`tests/python_interpreter.test.gd`)

### Core Systems - Simulation Engine (P0)
- [ ] Create `scripts/core/simulation_engine.gd`
  - [ ] Command queue executor (receives commands from interpreter)
  - [ ] Vehicle position management
  - [ ] Velocity/movement system
  - [ ] Basic collision detection (vehicle-vehicle)
  - [ ] Boundary collision detection
  - [ ] Timing/synchronization system
- [ ] Write tests for simulation engine (`tests/simulation_engine.test.gd`)

### Basic Vehicle System (P0)
- [ ] Create `scripts/entities/vehicle.gd`
  - [ ] Implement forward movement (`go()`)
  - [ ] Implement stop functionality (`stop()`)
  - [ ] Implement basic physics (position, velocity, rotation)
  - [ ] Add destination tracking
- [ ] Create placeholder vehicle sprite

**Phase 1 Milestone:** Car moves forward based on `car.go()` Python code input

---

## Phase 2: Core Mechanics

### Python Language Features (P0)
- [ ] **CORE-003** Implement Python language constructs
  - [ ] **Variables**
	- [ ] Variable assignment (x = value)
	- [ ] Number, boolean, string storage
	- [ ] Variable usage in expressions
	- [ ] Undefined variable detection (NameError)
  - [ ] **Conditionals**
	- [ ] `if condition:` with indented block
	- [ ] `elif condition:` clauses
	- [ ] `else:` clause
	- [ ] Nested conditionals
  - [ ] **Comparison Operators**
	- [ ] == (equal), != (not equal)
	- [ ] < (less than), > (greater than)
	- [ ] <= (less than or equal), >= (greater than or equal)
  - [ ] **Logical Operators**
	- [ ] `and` - both conditions True
	- [ ] `or` - at least one condition True
	- [ ] `not` - invert condition
  - [ ] **While Loops**
	- [ ] `while condition:` with indented block
	- [ ] Break statement support
	- [ ] Infinite loop protection (10s timeout)
  - [ ] **For Loops**
	- [ ] `for i in range(n):` syntax
	- [ ] Loop variable access
	- [ ] Nested loop support

### Vehicle Control Functions (P0)
- [ ] **CORE-002** Complete Python Vehicle API
  - [ ] **Basic Movement**
	- [ ] `car.go()` - continuous forward movement
	- [ ] `car.stop()` - immediate stop
	- [ ] `car.turn_left()` - 90° left turn at intersection
	- [ ] `car.turn_right()` - 90° right turn at intersection
	- [ ] `car.wait(seconds)` - pause for N seconds (float)
  - [ ] **Speed Control**
	- [ ] `car.set_speed(value)` - speed multiplier 0.5 to 2.0
	- [ ] `car.get_speed()` - returns current speed multiplier
  - [ ] **State Queries (return bool)**
	- [ ] `car.is_moving()` - is car currently moving?
	- [ ] `car.is_blocked()` - is path obstructed?
	- [ ] `car.is_at_intersection()` - is car at intersection?
	- [ ] `car.is_at_destination()` - has car reached destination?
  - [ ] **Distance Queries (return float)**
	- [ ] `car.distance_to_destination()` - distance to destination
	- [ ] `car.distance_to_intersection()` - distance to next intersection

### Traffic Light System (P0)
- [ ] Create `scripts/entities/stoplight.gd`
  - [ ] **Control Methods**
	- [ ] `stoplight.set_red()` - change to red
	- [ ] `stoplight.set_yellow()` - change to yellow
	- [ ] `stoplight.set_green()` - change to green
  - [ ] **State Queries (return bool)**
	- [ ] `stoplight.is_red()` - is light red?
	- [ ] `stoplight.is_yellow()` - is light yellow?
	- [ ] `stoplight.is_green()` - is light green?
  - [ ] **State Getter (return string)**
	- [ ] `stoplight.get_state()` - returns "red", "yellow", or "green"
  - [ ] Implement state machine transitions
  - [ ] Car stopping at red lights behavior
- [ ] Create traffic light sprite (2-way and 4-way variants)
- [ ] Write tests for stoplight (`tests/stoplight.test.gd`)

### Turn Mechanics
- [ ] Implement intersection detection
- [ ] Implement turn queuing at intersections
- [ ] Handle 90-degree rotations smoothly

### Simulation Controls (P0)
- [ ] **CORE-004** Create playback control system
  - [ ] Run button - execute Python code (F5 or Ctrl+Enter)
  - [ ] Pause button - freeze simulation (Space)
  - [ ] Resume - continue simulation (Space toggle)
  - [ ] Fast-Forward 2x - double speed (+ or =)
  - [ ] Fast-Forward 4x - quadruple speed (Ctrl + +)
  - [ ] Slow-Motion 0.5x - half speed (-)
  - [ ] Fast Retry - instant restart (R or Ctrl+R)
  - [ ] Step mode - execute one line at a time (F10)
  - [ ] Current line highlighting in editor

### Win/Lose Conditions (P0)
- [ ] **MODE-001** Implement win condition detection
  - [ ] All cars reached destination
  - [ ] Trigger victory UI
- [ ] Implement fail condition detection
  - [ ] Car crash (collision)
  - [ ] Timer expired
  - [ ] Car exits map boundary
  - [ ] Infinite loop detected (10s timeout)
  - [ ] Code error/exception
  - [ ] Trigger failure UI with reason

### Level Manager (P0)
- [ ] Create `scripts/core/level_manager.gd`
  - [ ] Load level configurations from JSON
  - [ ] Spawn vehicles at designated positions
  - [ ] Spawn traffic elements
  - [ ] Track win/lose states
  - [ ] Calculate star ratings
  - [ ] Handle level transitions

**Phase 2 Milestone:** Full gameplay loop with Python conditionals and loops functional

---

## Phase 3: Content Creation

### Tutorial Levels - Functions (P0)
- [ ] **LVL-001** Create Tutorial Map Set (T1-T5)
  - [ ] **T1: "First Drive"** - teaches `car.go()`, function calls
	- [ ] Layout: Straight road, single car, one destination
	- [ ] Solution: `car.go()`
  - [ ] **T2: "Stop Sign"** - teaches `car.stop()`, sequencing
	- [ ] Layout: Road with marked stop point before destination
	- [ ] Solution: `car.go()`, `car.wait(2)`, `car.stop()`, etc.
  - [ ] **T3: "Turn Ahead"** - teaches `car.turn_left()`, `car.turn_right()`
	- [ ] Layout: L-shaped or T-intersection road
	- [ ] Solution: Movement + turn combination
  - [ ] **T4: "Red Light, Green Light"** - teaches traffic light control
	- [ ] Layout: Intersection with controllable stoplight
	- [ ] Solution: `stoplight.set_green()`, `car.go()`, timing
  - [ ] **T5: "Traffic Jam"** (Tutorial Finale) - combines all concepts
	- [ ] Layout: Multiple cars, intersection with stoplight
	- [ ] Solution: Multi-entity coordination

### Iloilo City Levels - Variables & Conditionals (P0)
- [ ] **LVL-002** Create Iloilo City Map Set (C1-C5)
  - [ ] **C1: "Jaro Cathedral Run"** - teaches variables
	- [ ] Location: Jaro Cathedral & Plaza
	- [ ] Challenge: Use variables for timing
	- [ ] Example: `wait_time = 2`, `car.wait(wait_time)`
  - [ ] **C2: "Esplanade Evening"** - teaches `if` statements
	- [ ] Location: Iloilo Esplanade
	- [ ] Challenge: React to traffic light state
	- [ ] Example: `if stoplight.is_green(): car.go()`
  - [ ] **C3: "SM Roundabout"** - teaches `if-elif-else`
	- [ ] Location: SM City Iloilo Area
	- [ ] Challenge: Roundabout with multiple exits
	- [ ] Example: Full if-elif-else chain
  - [ ] **C4: "Calle Real Rush Hour"** - teaches logical operators
	- [ ] Location: Calle Real Heritage District
	- [ ] Challenge: Multiple conditions with `and`, `or`, `not`
  - [ ] **C5: "Molo Church Challenge"** - teaches comparison operators
	- [ ] Location: Molo Church & Plaza
	- [ ] Challenge: Distance-based decisions
	- [ ] Example: `if car.distance_to_destination() > 10:`

### Water/Port Levels - Loops (P1)
- [ ] **LVL-003** Create Water/Port Map Set (W1-W5)
  - [ ] **W1: "River Crossing 101"** - teaches `while` loops
	- [ ] Location: Iloilo River Wharf
	- [ ] Challenge: Wait for boat using loop
	- [ ] Example: `while not boat.is_ready(): car.wait(1)`
  - [ ] **W2: "Ferry Queue"** - teaches `while` with conditions
	- [ ] Location: Fort San Pedro Area
	- [ ] Challenge: Multiple cars, queue management
	- [ ] Example: `while not car.is_at_destination():`
  - [ ] **W3: "Two-Way Traffic"** - teaches `for` loops with `range()`
	- [ ] Location: Iloilo Fishing Port
	- [ ] Challenge: Repeat actions N times
	- [ ] Example: `for i in range(3):`
  - [ ] **W4: "Land and Sea"** - teaches nested loops
	- [ ] Location: Parola Lighthouse Area
	- [ ] Challenge: Mixed land and water routes
  - [ ] **W5: "Port Master"** - teaches complex algorithms
	- [ ] Location: Combined River & Port
	- [ ] Challenge: Full port simulation combining all concepts

### Boat Mechanics (P1)
- [ ] Create `scripts/entities/boat.gd`
  - [ ] Implement boat capacity (2-3 cars)
  - [ ] Auto-departure (when full OR after 5 seconds)
  - [ ] Boat respawn (15 seconds after departure)
  - [ ] Queue system (FIFO)
  - [ ] **Python API:**
	- [ ] `boat.depart()` - force immediate departure
	- [ ] `boat.is_ready()` - is boat docked and ready?
	- [ ] `boat.is_full()` - is boat at capacity?
	- [ ] `boat.get_passenger_count()` - number of cars on board

### Vehicle Variety (P1)
- [ ] **VEH-001** Implement vehicle types
  - [ ] Sedan - Speed 1.0x, Size 1.0
  - [ ] SUV - Speed 0.9x, Size 1.2
  - [ ] Motorcycle - Speed 1.3x, Size 0.5 (can lane split)
  - [ ] Jeepney - Speed 0.7x, Size 1.5 (carries multiple passengers)
  - [ ] Truck/Van - Speed 0.6x, Size 2.0 (longer stopping distance)
  - [ ] Tricycle - Speed 0.7x, Size 0.7 (tight turn radius)
- [ ] Implement random vehicle generation per level
- [ ] Create vehicle sprites for each type

### Level Data Format
- [ ] Create `data/levels/` folder structure
- [ ] Define JSON level format with Python concepts info
- [ ] Create level JSON files for all 15 levels

**Phase 3 Milestone:** All 15 campaign levels playable with Python code

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
| Phase 1: Foundation | In Progress | 30% |
| Phase 2: Core Mechanics | Not Started | 0% |
| Phase 3: Content Creation | Not Started | 0% |
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
- All 24 tests pass (17 code_parser tests + 7 stoplight tests)
- Game runs without errors in headless mode
- Game launches successfully with window

---

*Last Updated: January 2, 2026*