# New Features - Game Mechanics Update

## Overview

This update introduces a tile-based road system, consumable resources (road cards), and enhanced vehicle control.

---

## 1. TileMapLayer System

The game now uses Godot's `TileMapLayer` for rendering roads and terrain.

- **Grass tiles**: Column 0 in the tileset
- **Road tiles**: Columns 1-16 in the tileset (auto-connecting)
- Players can edit the map by placing/removing roads

---

## 2. Road Cards System

Players have a limited number of road cards to modify the map.

### Mechanics:
- **Initial count**: 10 road cards (configurable per level)
- **Placing a road**: Costs 1 road card
  - Left-click on a grass tile to place a road
  - Cannot place if no cards remaining
- **Removing a road**: Refunds 1 road card
  - Right-click on a road tile to remove it
  - Converts back to grass

### UI Display:
- Road card count shown in top-left: `Road Cards: 10`

---

## 3. Hearts System

Players have a limited number of hearts (lives).

### Mechanics:
- **Initial count**: 10 hearts (configurable per level)
- **Losing hearts**:
  - Car goes off-road (not on a road tile): -1 heart
  - Car collides with another car: -1 heart (both cars crash)
- **Game over**: When hearts reach 0, level fails

### UI Display:
- Hearts count shown in top-left: `Hearts: 10`

---

## 4. Enhanced Vehicle Control

### New Python Methods:

#### `car.turn(direction)`
Turn the car left or right immediately (no intersection required).

```python
car.turn("left")   # Turn 90 degrees left
car.turn("right")  # Turn 90 degrees right
```

#### `car.move(tiles)`
Move the car a specific number of tiles forward.

```python
car.move(3)  # Move forward 3 tiles
car.move(1)  # Move forward 1 tile
```

#### Road Detection Methods:

```python
if car.is_front_road():  # Check if road is in front
    car.go()

if car.is_left_road():   # Check if road is to the left
    car.turn("left")

if car.is_right_road():  # Check if road is to the right
    car.turn("right")
```

---

## 5. Crash Detection & Obstacle System

### NEW: Crashed Cars Stay as Obstacles!
- **Before**: Cars disappeared when they crashed
- **After**: Crashed cars remain on the map as obstacles
- **Visual**: Crashed cars are darkened (50% gray tint via modulate)
- **Future**: Placeholder for crashed car sprite

### Vehicle State System:
- **State 1 (Active)**: Car moves and executes code normally
- **State 0 (Crashed)**: Car stops all movement, becomes a static obstacle

### Off-Road Crashes:
- Cars must stay on road tiles (columns 1-16)
- Moving onto grass (column 0) triggers a crash
- Car stops, turns gray, loses 1 heart
- **Car stays on the map as an obstacle**

### Car-to-Car Collisions:
- **Active car hits active car**: Both crash and turn gray, 1 heart lost
- **Active car hits crashed car**: Active car crashes, 1 heart lost
- **Crashed car hit by active car**: Only the active car crashes
- **All crashed cars stay on the map**

---

## 6. Map Editing During Gameplay

### NEW: Always Enabled!
- **Before**: Map editing disabled during simulation
- **After**: Edit roads WHILE code is running!
- Left-click to place roads (consumes 1 card)
- Right-click to remove roads (refunds 1 card)

### Strategic Gameplay:
- Car crashes? Build an alternate route immediately!
- Guide future spawned cars around obstacles
- React to dynamic situations in real-time
- Manage limited road cards wisely

---

## Example Level Flow

1. **Level starts**:
   - Hearts: 10
   - Road Cards: 10
   - Initial road layout displayed

2. **Player edits map**:
   - Places additional roads to create a path
   - Road Cards: 7 (used 3 cards)

3. **Player writes code**:
   ```python
   car.go()
   if car.is_front_road():
       car.move(5)
   else:
       car.turn("left")
   ```

4. **Simulation runs**:
   - Car moves along roads
   - If car goes off-road: -1 heart, car deleted
   - If car collides: -1 heart, both cars deleted

5. **Level complete** or **retry**:
   - Can edit map again before next attempt

---

## 7. Automatic Car Spawning

### NEW: Cars Spawn Every 15 Seconds!
When you run code, the game automatically spawns new cars at regular intervals.

### Spawning Details:
- **Interval**: Every 15 seconds after simulation starts
- **Location**: Position (100, 300) facing RIGHT
- **Destination**: Position (700, 300)
- **Naming**: car1, car2, car3, car4, etc.
- **Code Execution**: Each new car automatically runs the current code

### Gameplay Impact:
- Your code must handle multiple cars simultaneously
- Plan for cars at different positions
- Account for crashed cars from previous spawns
- Continuous traffic creates dynamic challenges

### Spawning Control:
- **Starts**: When you press "Run Code"
- **Stops**: When simulation ends or you press Reset
- **Reset**: Clears all crashed cars and restarts spawn timer

---

## 8. Enhanced Car Detection

### NEW Python Methods:

#### `car.is_front_car()`
Check if there's **ANY** car (active or crashed) directly in front.
```python
if car.is_front_car():
    car.stop()  # Avoid hitting any car
```

#### `car.is_front_crashed_car()`
Check specifically for **CRASHED** cars in front.
```python
if car.is_front_crashed_car():
    # Navigate around the crashed car
    if car.is_left_road():
        car.turn("left")
    elif car.is_right_road():
        car.turn("right")
```

### Use Cases:
- **Obstacle avoidance**: Detect crashed cars and route around them
- **Collision prevention**: Stop before hitting active cars
- **Path planning**: Choose routes based on car positions

---

## 9. Stoplight Control Panel

A UI panel allows players to manually control the stoplight state during editing (before/after simulation).

### Features:
- **Set Red** button - Change stoplight to red
- **Set Yellow** button - Change stoplight to yellow
- **Set Green** button - Change stoplight to green
- **State display** - Shows current stoplight color

### Location:
- Top-right corner of the screen
- Panel displays: "Stoplight Control" with three buttons
- Current state shown below buttons

---

## Controls Summary

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

---

## File Changes

### Modified Files:
- `scenes/main.tscn` - TileMapLayer, hearts/road cards UI, stoplight panel
- `scenes/main.gd` - Hearts, road cards, map editing, **car spawning system**, reset fix
- `scripts/entities/vehicle.gd` - **Vehicle state system**, crash obstacles, car detection methods
- `scripts/core/simulation_engine.gd` - Updated to call new vehicle methods, validity checks
- `scripts/core/code_parser.gd` - Added `is_front_car`, `is_front_crashed_car` parsing

### New Folders:
- `maps/` - Developer folder for custom map creation

### New Documentation:
- `docs/UPDATE_3_CRASH_SYSTEM.md` - Complete crash obstacle system guide

---

## Bug Fixes

### 1. Vehicle Deletion Crash Fix
- **Issue**: Game crashed when vehicle was deleted after going off-road
- **Cause**: Simulation engine tried to access deleted vehicle's position
- **Fix**:
  - Added `is_instance_valid()` check before accessing vehicle properties
  - Use `call_deferred("queue_free")` to delay deletion until after physics frame
  - Clean up invalid vehicles from the simulation engine's vehicle dictionary

### 2. Reset Crash Fix
- **Issue**: Pressing R crashed when test vehicle was deleted/crashed
- **Cause**: Attempted to call `reset()` on freed vehicle instance
- **Fix**:
  - Check `is_instance_valid()` and vehicle state before calling reset
  - Spawn new vehicle if current one is crashed or invalid
  - Clear all crashed cars on reset using `_clear_all_crashed_cars()`

---

## Next Steps

1. **Create actual tileset**: Replace debug tileset with final artwork
2. **Crashed car sprite**: Add dedicated crashed car sprite (currently using darkened normal sprite)
3. **Level design**: Create puzzles using:
   - Road cards + hearts as constraints
   - Crashed cars as dynamic obstacles
   - Car spawning for continuous traffic
4. **Tutorial levels**: Teach mechanics progressively:
   - Basic movement (T1-T5)
   - Crash avoidance with `is_front_car()`
   - Route planning with `is_front_crashed_car()`
   - Live road editing strategy
5. **Save/Load maps**: Implement map serialization for level persistence
6. **Python conditionals**: Implement if/else statement support for full logic
7. **Win condition**: Define when level is complete with multiple cars
