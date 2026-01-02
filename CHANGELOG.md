# Changelog - GoCars Game Updates

## [Update 3] - 2026-01-03 - Crash Obstacle System

### 🚗 Major Gameplay Changes

#### Crashed Cars Stay as Obstacles
- **Breaking Change**: Cars no longer disappear when they crash
- Crashed cars remain on the map with darkened sprite (50% gray modulate)
- Creates dynamic puzzle where players must code around obstacles
- Placeholder for future crashed car sprite

#### Vehicle State System
- Added `vehicle_state` property: 0 = Crashed, 1 = Active
- Crashed cars (state 0) stop all movement and become static obstacles
- Active cars (state 1) can move and execute code
- Crashed cars detected in `_physics_process` to skip movement

### 🚙 Automatic Car Spawning
- **NEW**: Cars automatically spawn every 15 seconds after running code
- Spawn location: (100, 300) facing RIGHT
- Destination: (700, 300)
- Each new car gets unique ID: car1, car2, car3, etc.
- All spawned cars execute the current code in the editor
- Creates continuous traffic that must navigate around crashed cars

### 🛣️ Live Map Editing
- **Breaking Change**: Map editing NOW works during gameplay!
- Players can place/remove roads while simulation is running
- Build alternate routes when cars crash
- Strategic resource management with road cards
- Enables reactive puzzle solving

### 🔍 New Car Detection Methods
- `car.is_front_car()` - Detect ANY car (active or crashed) ahead
- `car.is_front_crashed_car()` - Detect specifically crashed cars ahead
- Detection range: 32 pixels (half a tile)
- Essential for navigating around obstacles

### 🐛 Bug Fixes
- **Fixed**: Reset crash when vehicle was deleted/crashed
  - Added `is_instance_valid()` check before calling reset
  - Spawn new vehicle if current one is invalid
  - Clear all crashed cars on reset
- **Fixed**: Simulation engine accessing freed vehicles
  - Added validity checks in `_check_vehicle_boundaries()`
  - Clean up invalid vehicles from dictionary

### 📝 Updated Systems
- **Collision Detection**: Different behavior for crashed vs active cars
  - Active hits active: both crash
  - Active hits crashed: only active crashes
  - Crashed cars stay as obstacles
- **Reset Behavior**: R key now clears all crashed cars
- **Spawning Control**: Starts on run, stops on simulation end/reset

### 📁 New Documentation
- `docs/UPDATE_3_CRASH_SYSTEM.md` - Complete crash system guide
- Updated `docs/NEW_FEATURES.md` - Crash obstacles, spawning, live editing
- Updated `docs/PYTHON_API_REFERENCE.md` - New detection methods and examples

---

## [Update 2] - 2026-01-03

### Added
- **Stoplight Control Panel** - UI panel in top-right with manual stoplight controls
  - Red, Yellow, Green buttons to change stoplight state
  - Current state display
  - Located at position (800, 20) on screen

### Fixed
- **Vehicle Deletion Crash** - Fixed crash when car went off-road
  - Issue: Simulation engine accessed freed vehicle's `global_position`
  - Solution: Added `is_instance_valid()` check in `_check_vehicle_boundaries()`
  - Solution: Changed `queue_free()` to `call_deferred("queue_free")` to delay deletion
  - Result: No more crashes when cars go off-road or collide

### Changed
- Updated instructions label to show correct Python syntax:
  - `if car.is_front_road():` instead of `if Front(Road):`
  - `if car.is_left_road():` instead of `if Left(Road):`
  - `if car.is_right_road():` instead of `if Right(Road):`

---

## [Update 1] - 2026-01-03

### Added
- **TileMapLayer System** - Migrated from old TileMap to new TileMapLayer
  - Grass tiles (column 0) and Road tiles (columns 1-16)
  - Default map with 20x20 grass field and horizontal road path

- **Maps Folder** - Created `maps/` directory for custom map development
  - Added README.md with instructions for creating maps

- **Road Card System** - Consumable resource for map editing
  - Start with 10 road cards (configurable)
  - Left-click to place road (-1 card)
  - Right-click to remove road (+1 card)
  - UI display in top-left corner
  - Map editing disabled during simulation

- **Hearts System** - Lives/health system
  - Start with 10 hearts (configurable)
  - Lose 1 heart when car goes off-road
  - Lose 1 heart when cars collide
  - Game over when hearts reach 0
  - UI display in top-left corner

- **Enhanced Vehicle API** - New Python methods for cars
  - `car.turn("left")` / `car.turn("right")` - Immediate turns
  - `car.move(N)` - Move N tiles forward
  - `car.is_front_road()` - Check if road ahead
  - `car.is_left_road()` - Check if road to left
  - `car.is_right_road()` - Check if road to right

- **Road-Only Movement** - Cars must stay on roads
  - Moving onto grass triggers off-road crash
  - Car deleted, 1 heart lost

- **Car Collision System** - Enhanced crash detection
  - Both cars deleted when they collide
  - 1 heart lost per collision
  - Uses `call_deferred()` to prevent mid-physics crashes

### Changed
- **CodeParser** - Added support for new methods
  - String parameter support for `turn()` method
  - Accepts "left" or "right" as parameter
  - Integer parameter support for `move()` method

- **SimulationEngine** - Updated vehicle function calls
  - Added handlers for all new vehicle methods
  - Query functions return values but don't modify state

### Documentation
- Created `docs/NEW_FEATURES.md` - Complete guide to all new features
- Created `maps/README.md` - Map creation instructions

---

## File Structure

```
GoCars/
├── CHANGELOG.md               # This file
├── scenes/
│   ├── main.tscn             # Updated with TileMapLayer, hearts/cards UI, stoplight panel
│   └── main.gd               # Map editing, hearts, cards, stoplight control
├── scripts/
│   ├── core/
│   │   ├── simulation_engine.gd   # Vehicle boundary checking fix
│   │   └── code_parser.gd         # New method parsing
│   └── entities/
│       └── vehicle.gd        # New methods, road detection, crash handling
├── maps/
│   └── README.md             # Map creation guide
└── docs/
    └── NEW_FEATURES.md       # Feature documentation
```

---

## How to Test

1. **Open the game** in Godot editor
2. **Edit the map**: Left-click to place roads, right-click to remove
3. **Control stoplight**: Use buttons in top-right panel
4. **Write Python code**:
   ```python
   car.go()
   if car.is_front_road():
       car.move(5)
   else:
       car.turn("left")
   ```
5. **Run the code** and watch the car move
6. **Observe**:
   - Hearts decrease when car crashes or goes off-road
   - Car is deleted on crash
   - Stoplight panel shows current state

---

## Known Issues

None currently! The vehicle deletion crash has been fixed.

---

## Next Development Steps

1. Replace debug tileset with final artwork
2. Implement Python if/else conditionals for road checking
3. Create tutorial levels teaching new mechanics
4. Add map save/load functionality
5. Design puzzle levels using road card constraints
