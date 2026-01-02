# GoCars Implementation Checklist

This document tracks all implementation tasks organized by development phase.
Check off items as they are completed.

---

## Phase 1: Foundation (Core Systems Setup)

### Project Infrastructure
- [x] **TECH-001** Create folder structure (assets/, scenes/, scripts/, tests/, data/)
- [x] Set up test runner script (`run_tests.sh`)
- [x] Create main scene (`scenes/main.tscn`)

### Core Systems - Code Parser (P0)
- [x] **TECH-003** Create `scripts/core/code_parser.gd`
  - [x] Implement line tokenizer (split by `.` and `()`)
  - [x] Implement object identifier validation
  - [x] Implement function name validation
  - [x] Implement parameter extraction and validation
  - [x] Implement error message system with clear messages
  - [x] Create command queue for valid commands
- [x] Write tests for code parser (`tests/code_parser.test.gd`)

### Core Systems - Simulation Engine (P0)
- [x] **TECH-002** Create `scripts/core/simulation_engine.gd`
  - [x] Implement command queue executor
  - [x] Implement vehicle position management
  - [x] Implement velocity/movement system
  - [x] Implement basic collision detection (vehicle-vehicle)
  - [ ] Implement boundary collision detection
  - [x] Implement timing/synchronization system
- [ ] Write tests for simulation engine

### Basic Vehicle System (P0)
- [x] Create `scripts/entities/vehicle.gd`
  - [x] Implement forward movement (`go()`)
  - [x] Implement stop functionality (`stop()`)
  - [x] Implement basic physics (position, velocity, rotation)
  - [x] Add destination tracking
- [ ] Create placeholder vehicle sprite

**Phase 1 Milestone:** Car moves forward based on `car.go()` code input

---

## Phase 2: Core Mechanics

### Vehicle Control Functions (P0)
- [x] **CORE-002** Complete basic movement functions
  - [x] `car.go()` - continuous forward movement
  - [x] `car.stop()` - immediate stop
  - [x] `car.turn_left()` - 90 degree left turn at intersection
  - [x] `car.turn_right()` - 90 degree right turn at intersection
  - [x] `car.wait(seconds)` - pause for N seconds

### Traffic Light System (P0)
- [x] Create `scripts/entities/stoplight.gd`
  - [x] Implement state machine (red, yellow, green)
  - [x] `stoplight.set_red()`
  - [x] `stoplight.set_green()`
  - [x] `stoplight.set_yellow()`
  - [x] `stoplight.get_state()` - returns current state
- [x] Create traffic light sprite (2-way and 4-way variants)
- [x] Implement car stopping at red lights

### Turn Mechanics
- [x] Implement intersection detection
- [x] Implement turn queuing at intersections
- [x] Handle 90-degree rotations smoothly

### Simulation Controls (P0)
- [x] **CORE-003** Create playback control system
  - [x] Play button (execute code) - Space key
  - [x] Pause button (freeze simulation) - Space toggle
  - [x] Fast-Forward 2x - `+` or `=` key
  - [x] Fast-Forward 4x - hold `++`
  - [x] Slow-Motion 0.5x - `-` key
  - [x] Fast Retry (instant restart) - `R` key
  - [x] Step-by-Step mode (optional) - `S` key

### Win/Lose Conditions (P0)
- [x] **MODE-001** Implement win condition detection
  - [x] All cars reached destination
  - [x] Trigger victory UI
- [x] Implement fail condition detection
  - [x] Car crash (collision)
  - [x] Timer expired
  - [x] Car exits map boundary
  - [x] Trigger failure UI

### Level Manager (P0)
- [x] Create `scripts/core/level_manager.gd`
  - [x] Load level configurations from JSON
  - [x] Spawn vehicles at designated positions
  - [x] Spawn traffic elements
  - [x] Track win/lose states
  - [x] Calculate star ratings
  - [x] Handle level transitions

**Phase 2 Milestone:** Full gameplay loop functional with all basic mechanics

---

## Phase 3: Content Creation

### Tutorial Levels (P0)
- [ ] **LVL-001** Create Tutorial Map Set
  - [ ] **T1: "First Drive"** - teaches `car.go()`
	- [ ] Layout: Straight road, single car, one destination
	- [ ] Solution: Single function call
  - [ ] **T2: "Stop Sign"** - teaches `car.stop()`
	- [ ] Layout: Road with marked stop point
	- [ ] Solution: Sequenced go() and stop()
  - [ ] **T3: "Turn Ahead"** - teaches turns
	- [ ] Layout: L-shaped or T-intersection
	- [ ] Solution: Movement + turn combination
  - [ ] **T4: "Red Light, Green Light"** - teaches traffic lights
	- [ ] Layout: Intersection with stoplight
	- [ ] Solution: Light control + car sequencing
  - [ ] **T5: "Traffic Jam"** - combines all concepts
	- [ ] Layout: Multiple cars, intersection with stoplight
	- [ ] Solution: Multi-entity coordination

### Iloilo City Levels (P0)
- [ ] **LVL-002** Create Iloilo City Map Set
  - [ ] **C1: "Jaro Cathedral Run"**
	- [ ] Single car, simple intersection
	- [ ] Jaro Cathedral landmark background
  - [ ] **C2: "Esplanade Evening"**
	- [ ] Two cars, timing coordination
	- [ ] Esplanade landmark background
  - [ ] **C3: "SM Roundabout"**
	- [ ] Roundabout navigation
	- [ ] Circular intersection logic
  - [ ] **C4: "Calle Real Rush Hour"**
	- [ ] Multiple traffic lights, 3+ cars
	- [ ] Multi-stoplight coordination
  - [ ] **C5: "Molo Church Challenge"**
	- [ ] Complex intersection network
	- [ ] All mechanics at scale

### Boat Mechanics (P1)
- [ ] Create `scripts/entities/boat.gd`
  - [ ] Implement boat capacity (2-3 cars)
  - [ ] Auto-departure (when full OR after 5 seconds)
  - [ ] Boat respawn (15 seconds after departure)
  - [ ] Queue system (FIFO)
  - [ ] `boat.depart()` - force departure
  - [ ] `boat.get_capacity()` - returns passenger count

### Water/Port Levels (P1)
- [ ] **LVL-003** Create Water/Port Map Set
  - [ ] **W1: "River Crossing 101"**
	- [ ] 1 car, 1 boat
	- [ ] Basic timing introduction
  - [ ] **W2: "Ferry Queue"**
	- [ ] 3 cars, 1 boat
	- [ ] Queue management
  - [ ] **W3: "Two-Way Traffic"**
	- [ ] 2 boats, 4 cars
	- [ ] Bidirectional boat travel
  - [ ] **W4: "Land and Sea"**
	- [ ] Mixed land routes and water crossings
  - [ ] **W5: "Port Master"**
	- [ ] Multiple boats, land intersections, 6+ cars

### Vehicle Variety (P1)
- [ ] **VEH-001** Implement vehicle types
  - [ ] Sedan - Speed 1.0x, Size 1.0
  - [ ] SUV - Speed 0.9x, Size 1.2
  - [ ] Motorcycle - Speed 1.3x, Size 0.5
  - [ ] Jeepney - Speed 0.7x, Size 1.5
  - [ ] Truck/Van - Speed 0.6x, Size 2.0
  - [ ] Tricycle - Speed 0.7x, Size 0.7
- [ ] Implement random vehicle generation per level
- [ ] Create vehicle sprites for each type

### Level Data Format
- [ ] Create `data/levels/` folder structure
- [ ] Define JSON level format
- [ ] Create level JSON files for all 15 levels

**Phase 3 Milestone:** All 15 campaign levels playable

---

## Phase 4: Polish & UI

### Main Menu (P0)
- [ ] **UI-001** Create Main Menu Screen
  - [ ] Game logo with animation
  - [ ] Campaign button -> Level Select
  - [ ] Infinite Mode button -> Mode Start
  - [ ] Collections button -> Vehicle Gallery
  - [ ] Settings button -> Options
  - [ ] Credits button -> Attribution
  - [ ] Exit button
  - [ ] Animated background (traffic scene)

### Gameplay Interface (P0)
- [ ] **UI-002** Create VS Code-Style HUD
  - [ ] Left Panel: File Explorer (120px fixed)
	- [ ] Display entities as .py files
	- [ ] Click to select entity
	- [ ] Visual indicators for active/inactive
  - [ ] Main View: Game World (flexible width)
	- [ ] 2D map visualization
	- [ ] Real-time code execution visualization
	- [ ] Entity labels
  - [ ] Bottom Panel: Code Editor (200px, collapsible)
	- [ ] Text input area
	- [ ] Line numbers
	- [ ] Syntax highlighting
	- [ ] Real-time error feedback
  - [ ] Top Bar: Level info, lives, timer
  - [ ] Playback controls toolbar

### Level Select Screen (P0)
- [ ] **UI-003** Create Level Select
  - [ ] Back button
  - [ ] Tutorial section (T1-T5)
  - [ ] Iloilo City section (C1-C5)
  - [ ] Water/Port section (W1-W5)
  - [ ] Level tiles showing:
	- [ ] Star ratings for completed
	- [ ] Lock icon for locked
  - [ ] Total stars counter

### Victory/Defeat Screens (P0)
- [ ] **UI-004** Create Result Screens
  - [ ] Victory screen
	- [ ] Star rating display
	- [ ] Time and lines of code stats
	- [ ] Retry button
	- [ ] Next level button
	- [ ] Level select button
  - [ ] Defeat screen
	- [ ] Failure reason display
	- [ ] Retry button
	- [ ] Skip button (optional)
	- [ ] Level select button

### Color Scheme Implementation
- [ ] Background: Dark gray (#1E1E1E)
- [ ] Panel borders: Subtle gray (#3C3C3C)
- [ ] Text: Light gray (#D4D4D4)
- [ ] Syntax: Functions blue (#569CD6), strings orange (#CE9178)
- [ ] Accent: Blue (#007ACC)

### Infinite/Survival Mode (P1)
- [ ] **MODE-002** Implement Infinite Mode
  - [ ] Lives system (3 starting lives)
  - [ ] Scoring system
	- [ ] +100 base per delivery
	- [ ] +10 per consecutive streak
	- [ ] +50 max speed bonus
	- [ ] +25 no-code-edit bonus
  - [ ] Difficulty scaling per wave
	- [ ] Waves 1-3: 1-2 vehicles, generous timers
	- [ ] Waves 4-6: 2-3 vehicles, moderate timers
	- [ ] Waves 7-10: 3-4 vehicles, tight timers
	- [ ] Waves 11+: 4+ vehicles, shortest timers
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

### Score Manager (P1)
- [ ] Create `scripts/systems/score_manager.gd`
  - [ ] Score calculation
  - [ ] Star rating calculation
  - [ ] Streak tracking

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

### Bug Testing
- [ ] Test all 15 campaign levels start to finish
- [ ] Test Infinite mode for 10+ waves
- [ ] Test all vehicle functions work correctly
- [ ] Test all UI screens and navigation
- [ ] Test save/load functionality
- [ ] Test edge cases (empty code, invalid input, etc.)

### Performance Optimization
- [ ] Verify stable 60 FPS on minimum spec
- [ ] Test level load times (< 5 seconds target)
- [ ] Check memory usage (< 500MB RAM target)
- [ ] Profile and optimize bottlenecks

### Final Polish
- [ ] Game balance adjustments
- [ ] Error message clarity review
- [ ] Visual consistency check
- [ ] Audio levels balancing

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

### Advanced Functions
- [ ] `car.speed(value)` - speed multiplier 0.5 to 2.0
- [ ] `car.follow(target_car)` - follow another car
- [ ] Conditional helper functions
  - [ ] `car.at_intersection()` - returns boolean
  - [ ] `car.distance_to(dest)` - returns float
  - [ ] `car.is_blocked()` - returns boolean
  - [ ] `stoplight.is_red()` - returns boolean
  - [ ] `stoplight.is_green()` - returns boolean

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
| Phase 3: Content Creation | Not Started | 0% |
| Phase 4: Polish & UI | Not Started | 0% |
| Phase 5: Testing & Submission | Not Started | 0% |

---

*Last Updated: January 2, 2026*
