# GoCars!

An educational coding-puzzle game built with Godot Engine where players write **real Python code** to control traffic flow and solve increasingly complex transportation puzzles.

**For TrackTech: CSS Hackathon 2026**

---

## Project Overview

GoCars! bridges the gap between beginner-friendly coding games and real programming. Players write actual Python syntax to control vehicles, manage traffic lights, and edit road layouts in real-time. Each puzzle teaches core programming concepts: variables, conditionals, loops, and functions. The immediate feedback from live code execution makes learning intuitive and engaging.

### Core Concept

Write actual Python code to program vehicles, control traffic lights, and manage road layouts. Watch your code execute in real-time as cars navigate, stop at intersections, and reach their destinations. Learn programming fundamentals through hands-on puzzle solving.

---

## Features & Functionality

### Core Gameplay
- **Real Python Syntax** – Write valid Python code
- **Live Execution** – See cars instantly react to your code changes
- **Traffic Simulation** – Collisions, and traffic light logic
- **Hearts System** – Gameplay with lives management

### Interactive Features
- **Real-time Code Editor** – Write and run code without recompilation
- **Multiple Vehicles** – Handle concurrent car logic and interactions
- **Traffic Lights** – Control intersection management with conditional logic
- **Vehicle Stats Display** – Hover to see vehicle type, speed, direction, and state
- **Campaign Progression** – Save progress and unlock new levels

---

## Game Modes

### Campaign Mode
Progressive level sets teaching Python fundamentals:

- **Tutorial (T1-T5)**

---

## Installation & Setup

### Prerequisites

**Required:**
- **Godot Engine 4.5.1** – [Download here](https://godotengine.org/download)
- **Git** (optional, for cloning repository)
- **Python 3.8+** (optional, for running test suite)

### Step 1: Open the Project

**Option A: Using Godot Project Manager**
1. Open Godot Engine
2. Click "Open Project"
3. Navigate to `your/project/path`
4. Click "Open"

**Option B: Command Line**
```bash
cd your/project/path
godot --path . --editor
```

### Step 2: Project Setup
1. Wait for Godot to load the project (first load takes ~30 seconds)
2. The project is already built and ready to run—no compilation needed
3. Godot automatically imports all assets

### Step 3: Run the Game

**Run in Godot Editor (with visible window):**
```bash
godot --path . --editor
# Then press Play button (F5)
```

**Run Game Directly (without editor):**
```bash
godot --path . --run
```

**Run Tests:**
```bash
./run_tests.sh
```

### Step 4: Build Executable (Optional)

To export as a standalone executable:

1. In Godot Editor: **Project → Export**
2. Click **Add Preset** and select platform:
   - **Windows Desktop** (.exe)
   - **Web** (.html)
   - **macOS** (.dmg)
   - **Linux** (.x86_64)
3. Configure export settings
4. Click **Export** and choose output location

---

## Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Game Engine** | Godot | 4.5.1 |
| **Engine Scripting** | GDScript | 3.5 |
| **Player Code** | Python (subset) | 3.9 syntax |
| **Graphics** | 2D Tilemap | Godot native |
| **UI Framework** | Godot Control Nodes | Built-in |
| **Build System** | Godot Editor | Native export |

---

### Data Flow

1. **Player Input** → Code Editor
2. **Code Parsing** → Python Parser (tokenize + AST)
3. **Execution** → Python Interpreter (line by line)
4. **Commands** → Simulation Engine (vehicle physics, collisions)
5. **State Update** → Entity System (vehicles, stoplights)
6. **Render** → Godot rendering pipeline

---

## User Guide

### How to Play a Level

1. **Write Python code** in the code editor (left side)
2. **Press F5 or "Run Code"** to execute
3. **Watch cars respond** in real-time
4. **Refine your code** and run again until all cars reach destinations

### Example: Level 1 (First Drive)

**Objective:** Make car1 reach its destination

**Python Code:**
```python
car.go()
```

That's it! The car moves forward automatically until it reaches the destination.

### Common Commands

**Movement:**
```python
car.go()              # Start moving
car.stop()            # Stop immediately
car.turn("left")      # Turn 90° left
car.turn("right")     # Turn 90° right
car.move(3)           # Move exactly 3 tiles
```

**Sensing:**
```python
if car.front_road():        # Road ahead?
    car.go()
elif car.front_car():       # Another car ahead?
    car.stop()
```

**Traffic Lights:**
```python
if stoplight.is_red():
    car.stop()
else:
    car.go()
```

**Loops:**
```python
while not car.at_end():
    car.go()
```

---

## Screenshots

### Main Menu
![Main Menu](assets/Pictures/Main%20Menu.png)

### Level Selection
![Level Selector](assets/Pictures/Level%20Selector%202.png)

### Gameplay
![Gameplay](assets/Pictures/image.png)

### Character Dialogue
![Character](assets/Pictures/maki%20talking.png)



## Level Editing Guide

### Create a New Level

1. **Copy a template level:**
   ```
   scenes/levelmaps/01Tutorial/01 Level 1.tscn
   ```

2. **Rename it** (e.g., `01 Level 6.tscn`)

3. **Open in Godot Editor** and customize:
   - Edit the TileMap to paint roads and parking spots
   - Set `LevelName` label for display name
   - Configure `HeartsUI/HeartCount` for starting lives (e.g., "3")
   - Position spawn and destination parking tiles

4. **Save** – the level auto-loads into the campaign

### Tileset Layout

The game uses an 18×12 grid tileset with:
- **Basic roads** (connections E/W/N/S)
- **Parking tiles** (spawn/destination groups A-D)
- **Stoplight tiles** (4-way intersections)
- **Multi-parking roads** (parking lot lanes)

---

## Known Limitations

### Current Version (Hackathon)
1. **Python Subset** – Not full Python (no classes, imports, list comprehensions)
2. **Single Player** – No multiplayer or competitive modes
3. **Fixed Difficulty** – No difficulty settings
4. **Limited Vehicles** – Only 8 vehicle types
5. **Mobile** – Keyboard & mouse only (no touch controls)

### Technical Limitations
- Python parser doesn't support advanced syntax (decorators, async/await)

---

## Future Improvements

### High Priority (Post-Hackathon)
- [ ] **Infinite Sandbox Mode** – Unlimited levels with random generation
- [ ] **Function Definitions** – Players can define reusable functions
- [ ] **Better Error Messages** – Line-by-line debugging with highlights
- [ ] **Sound & Music** – Professional OST and sound effects
- [ ] **Leaderboards** – Track best times and star ratings

### Medium Priority
- [ ] **Mobile Support** – Touch controls and responsive UI
- [ ] **Advanced Vehicles** – Trucks, buses with different behaviors
- [ ] **Multi-lane Roads** – Parallel roads for more complexity
- [ ] **Parking Lot Puzzles** – Advanced vehicle management scenarios
- [ ] **Level Editor UI** – Point-and-click level creation in-game

### Lower Priority
- [ ] **Multiplayer** – Cooperative puzzle solving
- [ ] **Social Features** – Share level solutions, community levels
- [ ] **Accessibility** – Colorblind mode, controller support
- [ ] **Platform Exports** – Mobile (iOS/Android), Web
- [ ] **Performance Optimization** – Support 50+ simultaneous vehicles
- [ ] **Advanced Python** – Classes, custom objects, more standard library

---

---

## Project Structure

```
GoCars/
├── README.md
├── CLAUDE.md
├── project.godot
├── run_tests.sh
│
├── scenes/
│   ├── main.tscn
│   ├── main_tilemap.tscn
│   ├── levelmaps/
│   │   ├── 01Tutorial/
│   │   └── 02Iloilo/
│   ├── entities/
│   ├── menus/
│   └── ui/
│
├── scripts/
│   ├── core/
│   │   ├── python_parser.gd
│   │   ├── python_interpreter.gd
│   │   └── simulation_engine.gd
│   ├── entities/
│   │   ├── vehicle.gd
│   │   └── stoplight.gd
│   ├── ui/
│   │   ├── code_editor_window.gd
│   │   └── completion_summary.gd
│   └── systems/
│
├── assets/
│   ├── audio/
│   ├── cars/
│   ├── fonts/
│   ├── sprites/
│   └── tiles/
│
├── data/
│   └── levels/
│
├── tests/
│   ├── python_parser.test.gd
│   ├── python_interpreter.test.gd
│   └── integration.test.gd
│
└── docs/
    └── PRD.md
```

---

## Documentation

### Primary Locations
- **README.md** (this file)
  - Location: `README.md`
  - Purpose: Quick overview and setup instructions
  - Audience: New players, developers, judges

- **CLAUDE.md**
  - Location: `CLAUDE.md`
  - Purpose: Development guide and API reference
  - Audience: Developers, contributors

- **docs/PRD.md** (Product Requirements Document)
  - Location: `docs/PRD.md`
  - Purpose: Complete specification and design doc
  - Audience: Game designers, architects

### Additional Resources
- **In-game Help (F1)** – Context-sensitive help in game
- **Code Comments** – Inline documentation in scripts
- **Example Levels** – Learn by studying tutorial levels (T1-T5)

### Submission Package Contents
- README.md (quick start)
- CLAUDE.md (development notes)
- Source code (all scripts)
- Executable (when built)
- Screenshots (main menu, level selector, gameplay, characters)
- Demo video (recording in progress)

---

## System Requirements

### Minimum Specifications
- **OS**: Windows 10, macOS 10.12, Ubuntu 16.04+
- **Processor**: Intel i5 or equivalent
- **RAM**: 2 GB
- **Storage**: 500 MB available space
- **Graphics**: DirectX 11 compatible
- **Input**: Keyboard & mouse required

### Recommended Specifications
- **RAM**: 4 GB or more
- **Graphics**: Dedicated GPU (NVIDIA/AMD)
- **Storage**: SSD for faster load times
- **Monitor**: 1080p or higher resolution
- **Processor**: Intel i7 or equivalent

---

## Credits

### Development Team

**Programmers:**
- Jorge Maverick Acidre
- Francis Gabriel Austria
- Carlos John Aristoki

**Design & Art:**
- Jake Occeña
- Jorge Maverick Acidre
- Om Shanti Limpin

**Mentor & Advisor:**
- John Christopher Mateo

### Technologies
Built with [Godot Engine 4.5.1](https://godotengine.org)
- GDScript
- Python (syntax subset)

---

## License

**GoCars!** is a private submission for **TrackTech: CSS Hackathon 2026**

All rights reserved. © 2026 Development Team

---

**Last Updated:** January 28, 2026
**Version:** 1.0 (Hackathon Submission)
