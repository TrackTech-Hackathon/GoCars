# Product Requirements Document (PRD)
# GoCars: Code Your Way Through Traffic

---

**Document Version:** 2.0  
**Date:** January 2026  
**Team Name:** [Team Name]  
**Event:** TrackTech: CSS Hackathon 2026  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Overview](#2-product-overview)
3. [Target Users and Personas](#3-target-users-and-personas)
4. [Feature Requirements](#4-feature-requirements)
5. [Technical Requirements](#5-technical-requirements)
6. [User Interface Specifications](#6-user-interface-specifications)
7. [Content Requirements](#7-content-requirements)
8. [Non-Functional Requirements](#8-non-functional-requirements)
9. [User Stories](#9-user-stories)
10. [Development Roadmap](#10-development-roadmap)
11. [Risk Assessment](#11-risk-assessment)
12. [Success Metrics](#12-success-metrics)
13. [Appendices](#13-appendices)

---

## 1. Executive Summary

### Product Vision

GoCars is an innovative educational coding-puzzle game that transforms the intimidating world of programming into an engaging traffic management adventure. By combining the strategic depth of Mini Motorways with the programming-based gameplay of The Farmer Was Replaced, GoCars creates a unique learning environment where players write **real Python code** to control vehicles, traffic lights, and other traffic elements.

### Problem Statement

Traditional programming education often fails to engage beginners, presenting coding concepts in abstract, text-heavy formats that feel disconnected from real-world applications. Many students abandon their coding journey before grasping fundamental concepts like functions, conditionals, loops, and variables. There exists a significant gap between "learn to code" games that oversimplify concepts and actual programming environments that overwhelm newcomers.

### Solution Overview

GoCars bridges this gap by providing a VS Code-inspired interface where players write **actual Python syntax** to solve traffic puzzles. The game progressively introduces programming concepts—from basic function calls to conditionals (`if/else`), loops (`while/for`), and variables—through carefully designed levels, allowing players to see immediate visual feedback as their code controls vehicles navigating through realistic traffic scenarios inspired by Iloilo City, Philippines.

### Key Differentiators

- **Real Python Syntax:** Players write actual Python code, not simplified pseudo-code
- **Progressive Concept Introduction:** Functions → Variables → Conditionals → Loops
- **Authentic Coding Experience:** VS Code-inspired interface familiarizes players with real development environments
- **Local Cultural Integration:** Features actual Iloilo landmarks, creating cultural relevance and pride
- **Dual Learning Paths:** Campaign mode for structured learning; Infinite mode for skill mastery
- **Immediate Visual Feedback:** Code execution visualized in real-time traffic simulation

### Success Metrics for Hackathon

- All core features functional and demonstrable on Demo Day
- Zero game-breaking bugs during 10-15 minute presentation
- Positive judge feedback across all six judging criteria
- Complete 15-level campaign with progressive difficulty

---

## 2. Product Overview

### 2.1 Basic Information

| Attribute | Details |
|-----------|---------|
| **Game Name** | GoCars |
| **Tagline** | "Code Your Way Through Traffic" |
| **Game Engine** | Godot 4.5.1 |
| **Genre** | Educational Coding-Puzzle / Traffic Simulation |
| **Platform** | PC (Windows executable) |
| **Target Audience** | Students (high school to undergraduate), beginner programmers, puzzle game enthusiasts |
| **Code Language** | Python (subset) |

### 2.2 Core Concept

GoCars teaches fundamental programming concepts through intuitive traffic control mechanics. Players interact with a **Python code editor** to control vehicles, manage traffic lights, and coordinate multi-vehicle scenarios across increasingly complex urban environments. The game teaches real programming skills that transfer directly to actual Python development.

### 2.3 Primary Goals

1. **Educational Excellence:** Teach fundamental programming concepts (functions, variables, conditionals, loops) through engaging gameplay
2. **Real Python Skills:** Use actual Python syntax so skills transfer to real programming
3. **Traffic Management Awareness:** Demonstrate real-world traffic management and urban planning principles
4. **Accessibility:** Create an approachable entry point to coding for non-programmers
5. **Cultural Showcase:** Feature Iloilo's landmarks and celebrate local heritage

### 2.4 SMART Objectives

| Objective | Measurement |
|-----------|-------------|
| Players complete tutorial understanding 8+ Python concepts | Post-tutorial assessment or level completion rate |
| Campaign mode teaches progressive difficulty across 15 levels | Level completion analytics |
| Players can write conditionals and loops by level 10 | Code analysis in later levels |
| Infinite mode provides replayability with score-based challenges | Session replay rate and high score distribution |
| All core features functional and bug-free by Demo Day | QA testing pass rate of 100% for critical paths |

---

## 3. Target Users and Personas

### Persona 1: The Curious Student

| Attribute | Details |
|-----------|---------|
| **Name** | Maria Santos |
| **Age** | 14-18 |
| **Background** | High school student with no coding experience |
| **Goals** | Learn Python programming basics in a fun, non-intimidating way |
| **Pain Points** | Traditional coding tutorials feel boring and overwhelming |
| **Motivations** | Enjoys puzzle games; curious about technology careers |
| **Success Criteria** | Completes tutorial levels; understands functions, variables, and conditionals |

### Persona 2: The Aspiring Developer

| Attribute | Details |
|-----------|---------|
| **Name** | Juan Dela Cruz |
| **Age** | 18-22 |
| **Background** | College student learning Python in formal education |
| **Goals** | Practice algorithmic thinking in creative contexts |
| **Pain Points** | Wants to apply coding skills beyond homework assignments |
| **Motivations** | Seeks engaging ways to reinforce classroom learning |
| **Success Criteria** | Achieves 3-star ratings using optimal algorithms; uses loops effectively |

### Persona 3: The Puzzle Enthusiast

| Attribute | Details |
|-----------|---------|
| **Name** | Alex Reyes |
| **Age** | 16-25 |
| **Background** | Avid strategy and puzzle game player |
| **Goals** | Find challenging gameplay with satisfying "eureka" moments |
| **Pain Points** | Many puzzle games lack depth or become repetitive |
| **Motivations** | Enjoys optimization challenges and competing with self |
| **Success Criteria** | Masters Infinite mode; achieves top leaderboard scores with efficient code |

### Persona 4: The Educator

| Attribute | Details |
|-----------|---------|
| **Name** | Prof. Elena Villanueva |
| **Age** | 25-45 |
| **Background** | Teacher or instructor seeking educational tools |
| **Goals** | Find engaging, age-appropriate ways to introduce Python programming |
| **Pain Points** | Existing tools are either too simple or too complex |
| **Motivations** | Wants students to develop computational thinking skills |
| **Success Criteria** | Can use game as supplementary teaching material for Python classes |

---

## 4. Feature Requirements

### 4.1 Core Gameplay Mechanics

#### CORE-001: Code Editor System

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |
| **Description** | VS Code-inspired interface for writing Python vehicle control code |

**Components:**

**Left Panel (File Explorer):**
- Display controllable entities as .py files (car.py, stoplight.py, boat.py)
- Click to select/edit specific entity's code
- Visual indicators for active/inactive files
- Hierarchical display for multiple entities of same type

**Bottom Panel (Code Editor):**
- Text input area for writing **Python code**
- Collapsible/expandable panel (toggle with keyboard shortcut)
- **Full Python syntax highlighting** (keywords, strings, numbers, comments)
- Real-time error feedback for invalid commands
- Line numbers for reference
- **Indentation guides** for blocks (if/else, while, for)

**Main View (Game World):**
- 2D cartoon-style map visualization
- Real-time code execution visualization
- Hover highlighting for interactive elements
- Entity labels showing associated file names

**Acceptance Criteria:**
- [ ] File explorer displays all controllable entities for current level
- [ ] Code editor accepts and parses Python syntax
- [ ] Python keywords highlighted correctly (if, else, while, for, def, etc.)
- [ ] Code execution reflects immediately in game world
- [ ] Panel can be toggled open/closed via UI button or keyboard
- [ ] Syntax errors display clear, actionable error messages
- [ ] Indentation is enforced for block structures

---

#### CORE-002: Python Vehicle Control API

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |
| **Description** | Complete Python API reference for player-accessible functions |

**Basic Movement Functions:**

```python
# Movement
car.go()              # Moves car forward continuously until stopped
car.stop()            # Stops car movement immediately
car.turn_left()       # Turns car 90° left at next intersection
car.turn_right()      # Turns car 90° right at next intersection
car.wait(seconds)     # Pauses car for specified duration (float)

# Example
car.go()
car.wait(2.5)
car.turn_left()
car.go()
```

**Enhanced Movement Functions (NEW):**

```python
# Immediate Turns (no intersection required)
car.turn("left")      # Turns car 90° left immediately
car.turn("right")     # Turns car 90° right immediately

# Tile-Based Movement
car.move(tiles)       # Moves car forward N tiles (1-100)

# Example
car.turn("left")      # Turn immediately
car.move(5)           # Move forward 5 tiles
```

**Road Detection Functions (NEW):**

```python
# Road Detection (returns bool)
car.is_front_road()   # Returns True if road tile ahead
car.is_left_road()    # Returns True if road tile to the left
car.is_right_road()   # Returns True if road tile to the right

# Example: Navigate maze
if car.is_front_road():
	car.go()
elif car.is_left_road():
	car.turn("left")
	car.go()
elif car.is_right_road():
	car.turn("right")
	car.go()
```

**Car Detection Functions (NEW):**

```python
# Car Detection (returns bool)
car.is_front_car()          # Returns True if ANY car ahead (active or crashed)
car.is_front_crashed_car()  # Returns True if CRASHED car ahead (obstacle)

# Example: Avoid obstacles
if car.is_front_crashed_car():
	if car.is_left_road():
		car.turn("left")
	elif car.is_right_road():
		car.turn("right")
elif car.is_front_car():
	car.stop()  # Wait for car to move
else:
	car.go()
```

**Traffic Light Functions:**

```python
# Traffic Light Control
stoplight.set_red()       # Sets traffic light to red
stoplight.set_green()     # Sets traffic light to green
stoplight.set_yellow()    # Sets traffic light to yellow

# Traffic Light State (returns string)
state = stoplight.get_state()    # Returns "red", "green", or "yellow"

# Example
stoplight.set_green()
car.go()
car.wait(3)
stoplight.set_red()
```

**Conditional Helper Functions (Return Boolean):**

```python
# Car State Queries
car.is_at_intersection()    # Returns True if car is at intersection
car.is_at_destination()     # Returns True if car reached destination
car.is_blocked()            # Returns True if path is obstructed
car.is_moving()             # Returns True if car is currently moving

# Traffic Light State Queries
stoplight.is_red()          # Returns True if light is red
stoplight.is_green()        # Returns True if light is green
stoplight.is_yellow()       # Returns True if light is yellow

# Distance (returns float)
car.distance_to_destination()   # Returns distance to destination
car.distance_to_intersection()  # Returns distance to next intersection
```

**Advanced Functions (Later Levels):**

```python
# Speed Control
car.set_speed(value)     # Sets speed multiplier (0.5 to 2.0)
speed = car.get_speed()  # Returns current speed multiplier

# Following
car.follow(other_car)    # Follow another car maintaining safe distance

# Boat Functions
boat.depart()            # Force boat departure regardless of capacity
count = boat.get_passenger_count()  # Returns number of cars on boat
boat.is_full()           # Returns True if boat is at capacity
```

---

#### CORE-003: Python Language Features

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |
| **Description** | Supported Python language constructs |

**Variables:**

```python
# Variable assignment
speed = 1.5
wait_time = 3
is_ready = True
light_state = stoplight.get_state()

# Using variables
car.set_speed(speed)
car.wait(wait_time)
```

**Conditionals (if/elif/else):**

```python
# Basic if statement
if stoplight.is_red():
	car.stop()

# If-else
if car.is_at_intersection():
	car.turn_left()
else:
	car.go()

# If-elif-else
if stoplight.is_red():
	car.stop()
elif stoplight.is_yellow():
	car.stop()
else:
	car.go()

# Nested conditions
if car.is_at_intersection():
	if stoplight.is_green():
		car.go()
	else:
		car.stop()
```

**Comparison Operators:**

```python
# Supported operators
==    # Equal to
!=    # Not equal to
<     # Less than
>     # Greater than
<=    # Less than or equal
>=    # Greater than or equal

# Examples
if car.distance_to_destination() < 5:
	car.stop()

if car.get_speed() >= 1.5:
	car.set_speed(1.0)
```

**Logical Operators:**

```python
# Supported operators
and   # Both conditions must be True
or    # At least one condition must be True
not   # Inverts the condition

# Examples
if stoplight.is_green() and not car.is_blocked():
	car.go()

if car.is_at_destination() or car.is_blocked():
	car.stop()
```

**While Loops:**

```python
# Basic while loop
while not car.is_at_destination():
	car.go()

# While with condition
while car.distance_to_destination() > 10:
	car.go()
	car.wait(0.5)

# While with break
while True:
	car.go()
	if car.is_at_intersection():
		break
car.turn_left()
```

**For Loops (with range):**

```python
# Repeat action N times
for i in range(3):
	car.go()
	car.wait(1)
	car.stop()

# Using loop variable
for i in range(5):
	car.wait(i)  # Waits 0, 1, 2, 3, 4 seconds

# Nested loops
for i in range(2):
	for j in range(3):
		car.go()
		car.wait(1)
```

**Comments:**

```python
# This is a single-line comment
car.go()  # Inline comment

# Multi-line comments use multiple #
# Line 1
# Line 2
```

**NOT Supported (to keep it simple):**

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
```

---

#### CORE-004: Simulation Controls

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |
| **Description** | Playback controls for code execution and simulation |

**Control Set:**

| Control | Function | Keyboard Shortcut |
|---------|----------|-------------------|
| Run | Execute Python code and run simulation | F5 or Ctrl+Enter |
| Pause | Freeze simulation state | Space |
| Resume | Continue simulation | Space (toggle) |
| Fast-Forward (2x) | Double speed execution | + or = |
| Fast-Forward (4x) | Quadruple speed execution | Ctrl + + |
| Slow-Motion (0.5x) | Half speed for debugging | - |
| Fast Retry | Instant level restart | R or Ctrl+R |
| Step (optional) | Execute one line at a time | F10 |

**UI Placement:** Top-center toolbar with icon buttons

**Acceptance Criteria:**
- [ ] All playback controls function as specified
- [ ] Speed changes apply smoothly without stuttering
- [ ] Fast Retry resets all entities to starting positions
- [ ] Current executing line is highlighted in editor
- [ ] Keyboard shortcuts work when code editor is not focused

---

#### CORE-005: Extended Game Mechanics (NEW)

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |
| **Description** | Additional gameplay mechanics for strategic depth |

**Road Cards System:**
- Players have a limited number of road cards (default: 10)
- Left-click on grass to place a road tile (costs 1 card)
- Right-click on road to remove it (refunds 1 card)
- **Live editing**: Roads can be placed/removed DURING gameplay
- UI displays remaining road cards in top-left corner

**Hearts/Lives System:**
- Players start with limited hearts (default: 10)
- Lose 1 heart when:
  - Car crashes (moves onto non-road tile)
  - Car collides with another car
- Game over when hearts reach 0
- UI displays remaining hearts in top-left corner

**Crashed Cars as Obstacles:**
- When a car crashes, it does NOT disappear
- Crashed cars become permanent obstacles on the map
- Visual: Crashed cars are darkened (50% gray modulate)
- Vehicle States:
  - State 1 (Active): Car moves and executes code normally
  - State 0 (Crashed): Car stops all movement, becomes static obstacle
- Players must navigate around crashed cars

**Automatic Car Spawning:**
- After pressing "Run", new cars spawn at regular intervals
- Spawn interval: Every 15 seconds
- All spawned cars execute the same Python code
- Naming: car1, car2, car3, etc.
- Spawning stops on level reset

**Stoplight Control Panel:**
- Manual UI controls for stoplights in top-right corner
- Buttons: Set Red, Set Yellow, Set Green
- Displays current stoplight state

**Road-Only Movement:**
- Cars can only move on road tiles (tileset columns 1-16)
- Moving onto grass (column 0) triggers a crash
- Use road detection methods to check paths before moving

**Acceptance Criteria:**
- [x] Road cards system functional with live editing
- [x] Hearts system tracks crashes and triggers game over
- [x] Crashed cars remain as visible obstacles
- [x] Cars spawn automatically every 15 seconds
- [x] Stoplight control panel allows manual control
- [x] Cars crash when moving off-road

---

### 4.2 Game Modes

#### MODE-001: Campaign/Puzzle Mode

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |
| **Description** | Story-driven progression teaching Python concepts |

**Learning Progression:**

| Level Set | Python Concepts Introduced |
|-----------|---------------------------|
| Tutorial (T1-T5) | Functions, basic sequencing |
| Iloilo City (C1-C5) | Variables, conditionals (if/else) |
| Water/Port (W1-W5) | Loops (while, for), complex logic |

**Objectives:**
- Navigate car(s) to designated destination(s)
- Avoid collisions between vehicles
- Complete within time limit (if applicable)

**Win Condition:** All cars reach their designated destinations without crashes

**Fail Conditions:**
- Any car crashes into another vehicle or obstacle
- Timer expires before all cars reach destinations
- Car exits map boundary
- Infinite loop detected (safety timeout)

**Level Structure:**

| Set | Levels | Focus |
|-----|--------|-------|
| Tutorial | T1-T5 (5 levels) | Basic functions |
| Iloilo City | C1-C5 (5 levels) | Variables & Conditionals |
| Water/Port | W1-W5 (5 levels) | Loops & Advanced Logic |

**Progression System:**
- Levels unlock sequentially upon completion
- Star rating system (1-3 stars) based on performance:
  - 1 Star: Level completed
  - 2 Stars: Completed with efficient code (under line limit)
  - 3 Stars: Completed with optimal solution

**Acceptance Criteria:**
- [ ] All 15 levels are playable from start to finish
- [ ] Star ratings calculate correctly based on criteria
- [ ] Level progression saves between sessions
- [ ] Win/fail states trigger appropriate UI feedback
- [ ] Infinite loop protection triggers after 10 seconds

---

#### MODE-002: Infinite/Survival Mode

| Attribute | Details |
|-----------|---------|
| **Priority** | P1 (High) |
| **Description** | Endless challenge mode requiring efficient Python code |

**Objective:** Survive escalating traffic challenges as long as possible

**Lives System:**
- Starting lives: 3
- Life loss conditions:
  - Car crash: -1 life
  - Car fails to reach destination before timer: -1 life
  - Code error/exception: -1 life
- Game Over: All 3 lives lost

**Scoring System:**

| Action | Points |
|--------|--------|
| Successful delivery | +100 base |
| Consecutive success bonus | +10 per streak |
| Speed bonus (fast completion) | +50 max |
| Code efficiency bonus (fewer lines) | +25 |
| Using loops effectively | +15 |

**Difficulty Scaling (per wave):**
- Wave 1-3: 1-2 vehicles, generous timers, basic functions only
- Wave 4-6: 2-3 vehicles, moderate timers, conditionals helpful
- Wave 7-10: 3-4 vehicles, tight timers, loops recommended
- Wave 11+: 4+ vehicles, shortest timers, complex logic required

**Acceptance Criteria:**
- [ ] Lives system functions correctly
- [ ] Score accumulates and displays in real-time
- [ ] Difficulty scales progressively
- [ ] High scores persist locally between sessions
- [ ] Game Over screen displays final score and statistics

---

### 4.3 Level Design Specifications

#### LVL-001: Tutorial Map Set (Functions)

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |
| **Purpose** | Teach basic Python functions |

**Level T1: "First Drive"**
- **Teaches:** `car.go()`, function calls
- **Layout:** Straight road, single car, one destination marker
- **Obstacles:** None
- **Solution:**
```python
car.go()
```

**Level T2: "Stop Sign"**
- **Teaches:** `car.stop()`, sequencing
- **Layout:** Road with marked stop point before destination
- **Challenge:** Must stop at specific location then proceed
- **Solution:**
```python
car.go()
car.wait(2)
car.stop()
car.wait(1)
car.go()
```

**Level T3: "Turn Ahead"**
- **Teaches:** `car.turn_left()`, `car.turn_right()`
- **Layout:** L-shaped or T-intersection road
- **Challenge:** Navigate corner to reach destination
- **Solution:**
```python
car.go()
car.wait(2)
car.turn_left()
car.go()
```

**Level T4: "Red Light, Green Light"**
- **Teaches:** `stoplight.set_green()`, timing
- **Layout:** Intersection with controllable traffic light
- **Challenge:** Coordinate car timing with light changes
- **Solution:**
```python
stoplight.set_green()
car.go()
car.wait(3)
stoplight.set_red()
```

**Level T5: "Traffic Jam" (Tutorial Finale)**
- **Combines:** All previous concepts
- **Layout:** Multiple cars, intersection with stoplight
- **Challenge:** Sequence multiple vehicles without collision
- **Solution:**
```python
stoplight.set_green()
car1.go()
car1.wait(3)
stoplight.set_red()
car2.go()
```

---

#### LVL-002: Iloilo City Map Set (Variables & Conditionals)

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |
| **Purpose** | Teach variables and conditionals |

**Level C1: "Jaro Cathedral Run"**
- **Teaches:** Variables
- **Location:** Jaro Cathedral & Plaza
- **Challenge:** Use variables for timing
- **Example Solution:**
```python
wait_time = 2
car.go()
car.wait(wait_time)
car.turn_right()
car.go()
```

**Level C2: "Esplanade Evening"**
- **Teaches:** `if` statements, boolean queries
- **Location:** Iloilo Esplanade
- **Challenge:** React to traffic light state
- **Example Solution:**
```python
if stoplight.is_green():
	car.go()
else:
	car.stop()
	stoplight.set_green()
	car.go()
```

**Level C3: "SM Roundabout"**
- **Teaches:** `if-elif-else`, multiple conditions
- **Location:** SM City Iloilo Area
- **Challenge:** Roundabout with multiple exits
- **Example Solution:**
```python
car.go()
if car.is_at_intersection():
	if stoplight.is_red():
		car.stop()
	elif stoplight.is_yellow():
		car.stop()
	else:
		car.turn_right()
		car.go()
```

**Level C4: "Calle Real Rush Hour"**
- **Teaches:** Logical operators (`and`, `or`, `not`)
- **Location:** Calle Real Heritage District
- **Challenge:** Multiple traffic lights, complex conditions
- **Example Solution:**
```python
if stoplight1.is_green() and not car.is_blocked():
	car.go()
elif stoplight2.is_green() or car.is_at_destination():
	car.stop()
```

**Level C5: "Molo Church Challenge"**
- **Teaches:** Combined conditionals, comparison operators
- **Location:** Molo Church & Plaza
- **Challenge:** Distance-based decisions
- **Example Solution:**
```python
if car.distance_to_destination() > 10:
	car.set_speed(1.5)
	car.go()
elif car.distance_to_destination() > 5:
	car.set_speed(1.0)
	car.go()
else:
	car.stop()
```

---

#### LVL-003: Water/Port Map Set (Loops)

| Attribute | Details |
|-----------|---------|
| **Priority** | P1 (High) |
| **Purpose** | Teach loops and advanced logic |

**Unique Mechanics:**

| Mechanic | Details |
|----------|---------|
| Boat Capacity | 2-3 cars per boat |
| Auto-Departure | Boat departs when full OR after 5 seconds |
| Boat Respawn | New boat arrives 15 seconds after departure |
| Queue System | Cars wait in line for boats (FIFO) |

**Level W1: "River Crossing 101"**
- **Teaches:** `while` loops
- **Location:** Iloilo River Wharf
- **Challenge:** Wait for boat using loop
- **Example Solution:**
```python
while not boat.is_ready():
	car.wait(1)
car.go()
```

**Level W2: "Ferry Queue"**
- **Teaches:** `while` with conditions
- **Location:** Fort San Pedro Area
- **Challenge:** Multiple cars, queue management
- **Example Solution:**
```python
while not car.is_at_destination():
	if boat.is_ready():
		car.go()
	else:
		car.wait(1)
```

**Level W3: "Two-Way Traffic"**
- **Teaches:** `for` loops with `range()`
- **Location:** Iloilo Fishing Port
- **Challenge:** Repeat actions multiple times
- **Example Solution:**
```python
for i in range(3):
	car.go()
	car.wait(2)
	car.stop()
	car.wait(1)
```

**Level W4: "Land and Sea"**
- **Teaches:** Nested loops and conditions
- **Location:** Parola Lighthouse Area
- **Challenge:** Mixed land and water routes
- **Example Solution:**
```python
for i in range(2):
	while not car.is_at_intersection():
		car.go()
	if i == 0:
		car.turn_left()
	else:
		car.turn_right()
```

**Level W5: "Port Master"**
- **Teaches:** Complex algorithms combining all concepts
- **Location:** Combined River & Port
- **Challenge:** Full port simulation
- **Example Solution:**
```python
destination_reached = False
while not destination_reached:
	if car.is_blocked():
		car.wait(1)
	elif car.is_at_intersection():
		if stoplight.is_green():
			car.turn_right()
		else:
			car.stop()
	else:
		car.go()
	destination_reached = car.is_at_destination()
```

---

### 4.4 Vehicle System

#### VEH-001: Vehicle Collection System

| Attribute | Details |
|-----------|---------|
| **Priority** | P1 (High) |
| **Description** | Variety of controllable vehicles with unique attributes |

**Vehicle Types:**

| Vehicle | Speed | Size | Special Ability |
|---------|-------|------|-----------------|
| Sedan (Standard) | 1.0x | 1.0 unit | None |
| SUV | 0.9x | 1.2 units | None |
| Motorcycle | 1.3x | 0.5 units | Can lane split (optional) |
| Jeepney | 0.7x | 1.5 units | Carries multiple passengers |
| Truck/Van | 0.6x | 2.0 units | Longer stopping distance |
| Tricycle | 0.7x | 0.7 units | Tight turn radius |

**Vehicle Properties Accessible via Code:**

```python
# Read-only properties
car.speed           # Base speed multiplier
car.size            # Vehicle size
car.name            # Vehicle name/ID

# Methods
car.get_speed()     # Returns current speed
car.set_speed(1.5)  # Set speed (0.5 to 2.0)
```

---

## 5. Technical Requirements

### 5.1 Technology Stack

#### TECH-001: Development Stack

| Component | Technology |
|-----------|------------|
| Game Engine | Godot 4.5.1 |
| Programming Language | GDScript |
| Player Code Language | Python (subset) |
| Target Platform | Windows PC (.exe) |
| Version Control | GitHub/GitLab (public repository) |
| Documentation | In-repo README + inline code comments |
| Build Output | Standalone .exe + .zip archive |

**Minimum System Requirements:**

| Requirement | Specification |
|-------------|---------------|
| OS | Windows 10 or later |
| RAM | 4GB minimum |
| Storage | 500MB available space |
| Graphics | Integrated graphics (Intel HD 4000+) |
| Display | 1280x720 minimum resolution |

---

### 5.2 Architecture Overview

#### TECH-002: System Architecture

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |

**Core Systems:**

**1. Python Parser**
- Parses actual Python syntax (subset)
- Tokenizes: keywords, identifiers, operators, literals
- Builds Abstract Syntax Tree (AST)
- Validates against game API
- Handles indentation for blocks
- Returns structured errors for invalid input

**2. Python Interpreter**
- Executes AST nodes sequentially
- Manages variable scope
- Evaluates expressions and conditions
- Executes loops with iteration limits
- Handles control flow (if/else, while, for, break)
- Infinite loop detection (10-second timeout)

**3. Simulation Engine**
- Executes commands from interpreter
- Manages vehicle physics (position, velocity, rotation)
- Handles collision detection (vehicle-vehicle, vehicle-boundary)
- Controls traffic light state machines
- Manages timing and synchronization

**4. Level Manager**
- Loads level configurations from data files
- Spawns vehicles and traffic elements at designated positions
- Tracks win/lose condition states
- Manages scoring and star rating calculations
- Handles level transitions

**5. UI Controller**
- Renders VS Code-style interface panels
- Handles user input (keyboard, mouse)
- Updates HUD elements (score, lives, timer)
- Manages panel states (expanded/collapsed)
- Displays notifications and feedback
- **Syntax highlighting for Python code**

**6. Save System**
- Stores level completion status and star ratings
- Saves high scores for Infinite mode
- Tracks vehicle collection unlocks
- Persists user preferences/settings

---

### 5.3 Python Parser Specifications

#### TECH-003: Python Parser System

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |

**Supported Python Syntax:**

```
program        → statement*
statement      → simple_stmt | compound_stmt
simple_stmt    → expression_stmt | assignment
compound_stmt  → if_stmt | while_stmt | for_stmt

expression_stmt → expression NEWLINE
assignment      → IDENTIFIER '=' expression NEWLINE

if_stmt    → 'if' expression ':' NEWLINE INDENT statement+ DEDENT
			 ('elif' expression ':' NEWLINE INDENT statement+ DEDENT)*
			 ('else' ':' NEWLINE INDENT statement+ DEDENT)?

while_stmt → 'while' expression ':' NEWLINE INDENT statement+ DEDENT
for_stmt   → 'for' IDENTIFIER 'in' 'range' '(' expression ')' ':' 
			 NEWLINE INDENT statement+ DEDENT

expression → or_expr
or_expr    → and_expr ('or' and_expr)*
and_expr   → not_expr ('and' not_expr)*
not_expr   → 'not' not_expr | comparison
comparison → term (comp_op term)*
comp_op    → '==' | '!=' | '<' | '>' | '<=' | '>='
term       → factor (('+' | '-') factor)*
factor     → unary (('*' | '/') unary)*
unary      → '-' unary | call
call       → primary ('.' IDENTIFIER '(' arguments? ')')*
primary    → NUMBER | STRING | 'True' | 'False' | IDENTIFIER | '(' expression ')'
arguments  → expression (',' expression)*
```

**Tokenization:**

| Token Type | Examples |
|------------|----------|
| KEYWORD | if, elif, else, while, for, in, range, and, or, not, True, False, break |
| IDENTIFIER | car, stoplight, boat, my_var, speed |
| NUMBER | 0, 42, 3.14, 0.5 |
| STRING | "red", 'green' |
| OPERATOR | +, -, *, /, ==, !=, <, >, <=, >=, = |
| DELIMITER | (, ), :, , |
| NEWLINE | Line ending |
| INDENT | Indentation increase |
| DEDENT | Indentation decrease |
| COMMENT | # This is a comment |

**Indentation Rules:**
- Each indentation level = 4 spaces (or 1 tab converted to 4 spaces)
- INDENT token emitted when indentation increases
- DEDENT token emitted when indentation decreases
- Mismatched indentation produces clear error

**Error Types and Messages:**

| Error Type | Example Message |
|------------|-----------------|
| SyntaxError | "SyntaxError: expected ':' after if condition (line 3)" |
| IndentationError | "IndentationError: expected an indented block (line 5)" |
| NameError | "NameError: 'car2' is not defined (line 7)" |
| TypeError | "TypeError: car.wait() requires a number, got string (line 2)" |
| AttributeError | "AttributeError: 'car' has no method 'fly' (line 4)" |
| RuntimeError | "RuntimeError: infinite loop detected (exceeded 10s)" |

**Example Valid Code:**

```python
# Variables and basic calls
speed = 1.5
car.set_speed(speed)
car.go()

# Conditionals
if stoplight.is_red():
	car.stop()
elif stoplight.is_yellow():
	car.stop()
else:
	car.go()

# While loop
while not car.is_at_destination():
	if car.is_blocked():
		car.wait(1)
	else:
		car.go()

# For loop
for i in range(3):
	car.go()
	car.wait(1)
	car.turn_left()
```

---

## 6. User Interface Specifications

### 6.1 Main Menu Screen

#### UI-001: Main Menu

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |

**Layout Description:**

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                      [GOCARS LOGO]                          │
│                 "Code Your Way Through Traffic"             │
│                                                             │
│                      ┌──────────────┐                       │
│                      │   Campaign   │                       │
│                      └──────────────┘                       │
│                      ┌──────────────┐                       │
│                      │ Infinite Mode│                       │
│                      └──────────────┘                       │
│                      ┌──────────────┐                       │
│                      │ Collections  │                       │
│                      └──────────────┘                       │
│                      ┌──────────────┐                       │
│                      │   Settings   │                       │
│                      └──────────────┘                       │
│                      ┌──────────────┐                       │
│                      │   Credits    │                       │
│                      └──────────────┘                       │
│                      ┌──────────────┐                       │
│                      │     Exit     │                       │
│                      └──────────────┘                       │
│                                                             │
│  [Animated background: Traffic flowing through Iloilo]      │
└─────────────────────────────────────────────────────────────┘
```

---

### 6.2 Gameplay Interface

#### UI-002: In-Game HUD

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |

**Layout Description (VS Code-Inspired):**

```
┌─────────────────────────────────────────────────────────────────────┐
│ [☰ Menu]  Level: T1 - First Drive         [♥♥♥ Lives] [⏱ 0:45]    │
├───────────┬─────────────────────────────────────────────────────────┤
│           │                                                         │
│  FILES    │                                                         │
│           │              G A M E   W O R L D                        │
│ 📄 car.py │                                                         │
│           │         [2D Map with vehicles, roads,                   │
│ 📄 stop.. │          destinations, and traffic elements]            │
│           │                                                         │
│ 📄 boat.. │                                                         │
│           │                                                         │
│           ├─────────────────────────────────────────────────────────┤
│           │  CODE EDITOR (Python)                     [▼ Collapse]  │
│           │  ┌─────────────────────────────────────────────────┐    │
│           │  │ 1 │ # Control your car with Python!             │    │
│           │  │ 2 │ if stoplight.is_green():                    │    │
│           │  │ 3 │     car.go()                                │    │
│           │  │ 4 │ else:                                       │    │
│           │  │ 5 │     car.stop()                              │    │
│           │  └─────────────────────────────────────────────────┘    │
│           │                                                         │
│           │  [▶ Run (F5)]  [⏸ Pause]  [⏩ 2x]  [🔄 Retry (R)]      │
└───────────┴─────────────────────────────────────────────────────────┘
```

**Syntax Highlighting Colors:**

| Element | Color | Example |
|---------|-------|---------|
| Keywords | Purple (#C586C0) | if, else, while, for, and, or, not |
| Built-in Constants | Blue (#569CD6) | True, False |
| Functions/Methods | Yellow (#DCDCAA) | go(), stop(), is_red() |
| Strings | Orange (#CE9178) | "red", 'green' |
| Numbers | Light Green (#B5CEA8) | 1, 2.5, 0.5 |
| Comments | Green (#6A9955) | # This is a comment |
| Variables | Light Blue (#9CDCFE) | speed, wait_time |
| Operators | White (#D4D4D4) | =, ==, +, - |

---

### 6.3 Level Select Screen

#### UI-003: Level Select

| Attribute | Details |
|-----------|---------|
| **Priority** | P0 (Critical) |

**Layout Description:**

```
┌─────────────────────────────────────────────────────────────┐
│  [← Back]              SELECT LEVEL                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  TUTORIAL - Learn Python Basics                             │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                   │
│  │ T1  │ │ T2  │ │ T3  │ │ T4  │ │ T5  │                   │
│  │ ★★★ │ │ ★★☆ │ │ ★☆☆ │ │ 🔒  │ │ 🔒  │                   │
│  │func │ │seq  │ │turn │ │light│ │combo│                   │
│  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                   │
│                                                             │
│  ILOILO CITY - Variables & Conditionals                     │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                   │
│  │ C1  │ │ C2  │ │ C3  │ │ C4  │ │ C5  │                   │
│  │ 🔒  │ │ 🔒  │ │ 🔒  │ │ 🔒  │ │ 🔒  │                   │
│  │vars │ │ if  │ │elif │ │logic│ │comp │                   │
│  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                   │
│                                                             │
│  WATER & PORT - Loops & Advanced                            │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                   │
│  │ W1  │ │ W2  │ │ W3  │ │ W4  │ │ W5  │                   │
│  │ 🔒  │ │ 🔒  │ │ 🔒  │ │ 🔒  │ │ 🔒  │                   │
│  │while│ │cond │ │ for │ │nest │ │algo │                   │
│  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘                   │
│                                                             │
│  Total Stars: 6/45          Python Concepts: 3/8            │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Content Requirements

### 7.1 Level Summary

| Set | Count | Levels | Python Concepts | Status |
|-----|-------|--------|-----------------|--------|
| Tutorial | 5 | T1-T5 | Functions, sequencing | P0 (Critical) |
| Iloilo City | 5 | C1-C5 | Variables, conditionals | P0 (Critical) |
| Water/Port | 5 | W1-W5 | Loops (while, for) | P1 (High) |
| **Total** | **15** | — | **8+ concepts** | — |

### 7.2 Python Concepts Progression

| Level | New Concept | Builds On |
|-------|-------------|-----------|
| T1 | Function calls | — |
| T2 | Sequencing, wait() | T1 |
| T3 | Turns | T1, T2 |
| T4 | Traffic light control | T1-T3 |
| T5 | Multiple entities | T1-T4 |
| C1 | Variables | T1-T5 |
| C2 | if statements | C1 |
| C3 | if-elif-else | C2 |
| C4 | and, or, not | C3 |
| C5 | Comparison operators | C4 |
| W1 | while loops | C1-C5 |
| W2 | while with conditions | W1 |
| W3 | for loops with range() | W2 |
| W4 | Nested loops | W3 |
| W5 | Complex algorithms | All |

---

## 8. Non-Functional Requirements

### NFR-001: Performance Requirements

| Metric | Target |
|--------|--------|
| Level Load Time | < 5 seconds |
| Frame Rate | Stable 60 FPS on minimum spec |
| Code Parse Time | < 100ms for typical solution |
| Memory Usage | < 500MB RAM |
| Executable Size | < 200MB |
| Input Latency | < 100ms response |

### NFR-002: Usability Requirements

| Metric | Target |
|--------|--------|
| Tutorial Completion Time | < 20 minutes for new players |
| Average Level Playtime | 3-10 minutes |
| Text Readability | Clear at 1080p resolution |
| Color Accessibility | All information distinguishable without color alone |
| Error Messages | Clear, actionable, Python-style messages |
| Syntax Highlighting | Consistent with VS Code Python theme |

### NFR-003: Reliability Requirements

| Requirement | Description |
|-------------|-------------|
| Stability | No game-breaking bugs or crashes |
| Infinite Loop Protection | 10-second timeout with clear message |
| Save System | Auto-save on level completion |
| Error Handling | Graceful recovery from invalid code |
| Exit | Clean exit functionality (no orphan processes) |

---

## 9. User Stories

### US-001: Write Python Code

**As a** player  
**I want to** write Python code like `car.go()` and see immediate results  
**So that** I learn real Python syntax while playing

**Acceptance Criteria:**
- [ ] Python syntax is accepted (not pseudo-code)
- [ ] Syntax highlighting matches Python conventions
- [ ] Errors show Python-style messages (SyntaxError, NameError, etc.)
- [ ] Code executes and affects game world

---

### US-002: Use Conditionals

**As a** player  
**I want to** write `if`, `elif`, and `else` statements  
**So that** I can make decisions based on game state

**Acceptance Criteria:**
- [ ] `if stoplight.is_red():` syntax works
- [ ] `elif` and `else` blocks execute correctly
- [ ] Indentation is required and enforced
- [ ] Boolean expressions evaluate correctly

---

### US-003: Use Loops

**As a** player  
**I want to** write `while` and `for` loops  
**So that** I can repeat actions without copying code

**Acceptance Criteria:**
- [ ] `while condition:` loops work correctly
- [ ] `for i in range(n):` loops work correctly
- [ ] Loop body must be indented
- [ ] Infinite loops are detected and stopped

---

### US-004: Use Variables

**As a** player  
**I want to** create variables like `speed = 1.5`  
**So that** I can store and reuse values

**Acceptance Criteria:**
- [ ] Variable assignment `x = value` works
- [ ] Variables can store numbers, booleans, strings
- [ ] Variables can be used in expressions
- [ ] Undefined variables produce NameError

---

### US-005: See Helpful Errors

**As a** beginner  
**I want to** see Python-style error messages with line numbers  
**So that** I can understand and fix my mistakes

**Acceptance Criteria:**
- [ ] Errors include line numbers
- [ ] Errors use Python naming (SyntaxError, IndentationError, etc.)
- [ ] Error messages explain what's wrong
- [ ] Erroneous line is highlighted in editor

---

### US-006: Learn Progressively

**As a** student  
**I want to** levels introduce one concept at a time  
**So that** I'm not overwhelmed by too much at once

**Acceptance Criteria:**
- [ ] Tutorial levels teach only functions
- [ ] Iloilo levels introduce conditionals gradually
- [ ] Water levels introduce loops gradually
- [ ] Each level has a hint showing the new concept

---

## 10. Development Roadmap

### Timeline Overview

**Total Duration:** 40 days (December 15, 2025 – January 24, 2026)

```
Dec 15 ──────────────────────────────────────────────────── Jan 24
   │ Phase 1 │ Phase 2 │   Phase 3   │ Phase 4 │ Phase 5 │ Demo
   │ (7 days)│ (9 days)│  (10 days)  │ (8 days)│ (5 days)│ Day
   └─────────┴─────────┴─────────────┴─────────┴─────────┴──────
```

---

### Phase 1: Foundation (December 15-22) — 7 Days

**Focus:** Python parser foundation

**Deliverables:**

| Task | Duration |
|------|----------|
| Project setup and repository creation | Day 1 |
| Python tokenizer (keywords, operators, indentation) | Days 1-3 |
| Basic AST builder (expressions, assignments) | Days 3-5 |
| Simple command executor | Days 5-6 |
| Basic vehicle movement system | Days 6-7 |

**Milestone:** Car moves based on `car.go()` Python code

---

### Phase 2: Core Mechanics (December 23-31) — 9 Days

**Focus:** Complete Python interpreter and game mechanics

**Deliverables:**

| Task | Duration |
|------|----------|
| Conditionals parser (if/elif/else) | Days 1-2 |
| Loop parser (while, for) | Days 2-3 |
| Variable system | Days 3-4 |
| Traffic light system | Days 4-5 |
| Turn mechanics at intersections | Days 5-6 |
| Playback controls | Days 6-7 |
| Win/lose conditions | Days 7-9 |

**Milestone:** Full gameplay with Python conditionals and loops

---

### Phase 3: Content Creation (January 1-10) — 10 Days

**Deliverables:**

| Task | Duration |
|------|----------|
| Tutorial levels T1-T5 (functions) | Days 1-3 |
| Iloilo levels C1-C5 (conditionals) | Days 3-6 |
| Boat mechanics implementation | Days 5-7 |
| Water levels W1-W5 (loops) | Days 7-9 |
| Vehicle types | Days 9-10 |

**Milestone:** All 15 levels playable with Python code

---

### Phase 4: Polish & UI (January 11-18) — 8 Days

**Deliverables:**

| Task | Duration |
|------|----------|
| VS Code-style interface with Python highlighting | Days 1-3 |
| Main menu and navigation | Days 3-4 |
| Level select with concept indicators | Days 4-5 |
| Collections system | Days 5-6 |
| Infinite mode | Days 6-8 |

**Milestone:** Complete game with polished UI

---

### Phase 5: Testing & Submission (January 19-23) — 5 Days

**Deliverables:**

| Task | Duration |
|------|----------|
| Python parser edge case testing | Days 1-2 |
| Performance optimization | Days 2-3 |
| Final polish | Days 3-4 |
| Build generation (.exe) | Day 4 |
| Documentation and submission | Day 5 |

**Milestone:** Submission-ready build

---

## 11. Risk Assessment

### Risk Matrix

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Python parser complexity | High | High | Start with minimal syntax, expand gradually |
| Indentation handling bugs | High | Medium | Thorough testing, clear error messages |
| Scope creep | Medium | High | Strict MVP definition |
| Infinite loop edge cases | Medium | High | Multiple detection methods, timeout |
| Performance with loops | Low | Medium | Iteration limits, profiling |

### MVP Definition (If Time Short)

**Must Have:**
- Basic function calls (go, stop, turn, wait)
- `if/else` conditionals
- `while` loops
- 8 levels minimum (T1-T5, C1-C3)

**Can Cut:**
- `for` loops (while can substitute)
- `elif` (can use nested if)
- Water/boat levels
- Infinite mode
- Advanced functions (speed, follow)

---

## 12. Success Metrics

### Educational Effectiveness

| Metric | Target |
|--------|--------|
| Players write valid Python after tutorial | 90%+ |
| Players use conditionals by level C5 | 85%+ |
| Players use loops by level W5 | 80%+ |
| Code transfers to real Python | Syntactically valid |

### Hackathon Criteria Alignment

| Criterion (Weight) | How GoCars Addresses It |
|--------------------|-------------------------|
| **Originality (20%)** | Real Python in a puzzle game; unique concept |
| **Functionality (20%)** | Full Python interpreter; intuitive feedback |
| **Technical (20%)** | Custom Python parser; AST interpreter |
| **Design (20%)** | VS Code aesthetic; Python syntax highlighting |
| **Completeness (10%)** | 15 levels; full Python subset |
| **Educational (10%)** | Teaches real Python; transferable skills |

---

## 13. Appendices

### Appendix A: Complete Python API Reference

#### Car Object

```python
# Movement
car.go()                    # Start moving forward
car.stop()                  # Stop immediately
car.turn_left()             # Queue left turn
car.turn_right()            # Queue right turn
car.wait(seconds)           # Wait for seconds (float)

# Speed
car.set_speed(multiplier)   # Set speed (0.5 to 2.0)
car.get_speed()             # Get current speed → float

# State queries (return bool)
car.is_moving()             # Is car currently moving?
car.is_blocked()            # Is path blocked?
car.is_at_intersection()    # Is car at intersection?
car.is_at_destination()     # Has car reached destination?

# Distance queries (return float)
car.distance_to_destination()    # Distance to destination
car.distance_to_intersection()   # Distance to next intersection
```

#### Stoplight Object

```python
# Control
stoplight.set_red()         # Change to red
stoplight.set_yellow()      # Change to yellow
stoplight.set_green()       # Change to green

# State queries (return bool)
stoplight.is_red()          # Is light red?
stoplight.is_yellow()       # Is light yellow?
stoplight.is_green()        # Is light green?

# Get state (return string)
stoplight.get_state()       # Returns "red", "yellow", or "green"
```

#### Boat Object

```python
# Control
boat.depart()               # Force immediate departure

# State queries
boat.is_ready()             # Is boat docked and ready?
boat.is_full()              # Is boat at capacity?
boat.get_passenger_count()  # Number of cars on board → int
```

### Appendix B: Supported Python Syntax Summary

| Feature | Syntax | Supported |
|---------|--------|-----------|
| Variables | `x = 5` | ✅ |
| Numbers | `1`, `3.14` | ✅ |
| Strings | `"text"`, `'text'` | ✅ |
| Booleans | `True`, `False` | ✅ |
| Comments | `# comment` | ✅ |
| Arithmetic | `+`, `-`, `*`, `/` | ✅ |
| Comparison | `==`, `!=`, `<`, `>`, `<=`, `>=` | ✅ |
| Logical | `and`, `or`, `not` | ✅ |
| If statement | `if x:` | ✅ |
| Elif | `elif x:` | ✅ |
| Else | `else:` | ✅ |
| While loop | `while x:` | ✅ |
| For loop | `for i in range(n):` | ✅ |
| Break | `break` | ✅ |
| Function calls | `obj.method()` | ✅ |
| Function defs | `def func():` | ❌ |
| Classes | `class X:` | ❌ |
| Imports | `import x` | ❌ |
| Lists | `[1, 2, 3]` | ❌ |
| Dictionaries | `{"a": 1}` | ❌ |
| Try/except | `try:` | ❌ |
| Lambda | `lambda x: x` | ❌ |

---

**End of Document**
