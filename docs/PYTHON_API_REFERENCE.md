# Python API Reference - GoCars

## Car Object Methods

### Movement Commands

#### `car.go()`
Start moving forward continuously until stopped.
```python
car.go()  # Car moves forward
```

#### `car.stop()`
Stop the car immediately.
```python
car.stop()  # Car stops
```

#### `car.move(tiles)`
Move forward a specific number of tiles.
- **Parameter**: `tiles` (int, 1-100)
```python
car.move(1)   # Move 1 tile forward
car.move(5)   # Move 5 tiles forward
```

#### `car.wait(seconds)`
Pause movement for a specified duration.
- **Parameter**: `seconds` (int, 1-60)
```python
car.wait(2)   # Wait for 2 seconds
```

---

### Turning Commands

#### `car.turn(direction)`
Turn 90 degrees in the specified direction immediately.
- **Parameter**: `direction` (string, "left" or "right")
```python
car.turn("left")   # Turn 90° counter-clockwise
car.turn("right")  # Turn 90° clockwise
```

#### `car.turn_left()`
Queue a left turn at the next intersection (legacy method).
```python
car.turn_left()  # Turn left at intersection
```

#### `car.turn_right()`
Queue a right turn at the next intersection (legacy method).
```python
car.turn_right()  # Turn right at intersection
```

---

### Road Detection Methods

#### `car.is_front_road()`
Check if there's a road tile directly in front of the car.
- **Returns**: `True` if road exists, `False` otherwise
```python
if car.is_front_road():
    car.go()
else:
    car.stop()
```

#### `car.is_left_road()`
Check if there's a road tile to the left of the car.
- **Returns**: `True` if road exists, `False` otherwise
```python
if car.is_left_road():
    car.turn("left")
```

#### `car.is_right_road()`
Check if there's a road tile to the right of the car.
- **Returns**: `True` if road exists, `False` otherwise
```python
if car.is_right_road():
    car.turn("right")
```

---

### Car Detection Methods (NEW!)

#### `car.is_front_car()`
Check if there's **ANY car** (active or crashed) directly in front.
- **Returns**: `True` if any vehicle detected, `False` otherwise
- **Detection Range**: 32 pixels (half a tile)
```python
if car.is_front_car():
    car.stop()  # Stop to avoid collision
else:
    car.go()
```

#### `car.is_front_crashed_car()`
Check specifically for **crashed cars** (obstacles) in front.
- **Returns**: `True` if crashed car detected, `False` otherwise
- **Detection Range**: 32 pixels (half a tile)
- **Use Case**: Navigate around static obstacles
```python
if car.is_front_crashed_car():
    # Try to find alternate route
    if car.is_left_road():
        car.turn("left")
    elif car.is_right_road():
        car.turn("right")
    else:
        car.stop()  # Wait for player to build a road
```

---

### Speed Control

#### `car.set_speed(multiplier)`
Set the car's speed multiplier.
- **Parameter**: `multiplier` (float, 0.5-2.0)
```python
car.set_speed(0.5)  # Half speed
car.set_speed(1.0)  # Normal speed
car.set_speed(2.0)  # Double speed
```

---

## Stoplight Object Methods

### State Change Commands

#### `stoplight.set_red()`
Change the stoplight to red.
```python
stoplight.set_red()  # Cars will stop
```

#### `stoplight.set_yellow()`
Change the stoplight to yellow.
```python
stoplight.set_yellow()  # Warning state
```

#### `stoplight.set_green()`
Change the stoplight to green.
```python
stoplight.set_green()  # Cars can go
```

---

### State Query Methods

#### `stoplight.get_state()`
Get the current state of the stoplight.
- **Returns**: String ("red", "yellow", or "green")
```python
state = stoplight.get_state()
# state will be "red", "yellow", or "green"
```

#### `stoplight.is_red()`
Check if the stoplight is red.
- **Returns**: `True` if red, `False` otherwise
```python
if stoplight.is_red():
    car.stop()
```

#### `stoplight.is_yellow()`
Check if the stoplight is yellow.
- **Returns**: `True` if yellow, `False` otherwise
```python
if stoplight.is_yellow():
    car.stop()
```

#### `stoplight.is_green()`
Check if the stoplight is green.
- **Returns**: `True` if green, `False` otherwise
```python
if stoplight.is_green():
    car.go()
```

---

## Complete Examples

### Example 1: Simple Navigation
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

### Example 3: Stoplight Awareness
```python
# React to stoplight state
if stoplight.is_green():
    car.go()
else:
    car.stop()
```

### Example 4: Complex Path Finding
```python
# Move along a path with turns
car.go()
car.move(5)

if car.is_left_road():
    car.turn("left")
    car.move(3)

if car.is_right_road():
    car.turn("right")
    car.move(2)

car.stop()
```

### Example 5: Obstacle Avoidance (NEW!)
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

### Example 6: Multi-Car Strategy (NEW!)
```python
# Code runs on every spawned car (every 15 seconds)
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

## Error Messages

### Common Errors

**Invalid parameter type:**
```
turn('forward') - value must be one of: left, right
```

**Out of range:**
```
move(150) - value must be between 1 and 100
```

**Unknown method:**
```
car.fly() is not available
```

**Missing parameter:**
```
car.turn() requires a parameter
```

---

## Notes

### Execution Model
- All commands execute sequentially
- **Code runs on EVERY spawned car** (every 15 seconds)
- Same code handles multiple cars simultaneously
- Plan for different car positions and states

### Detection Ranges
- Road detection: 64 pixels (1 tile) in specified direction
- Car detection: 32 pixels (half a tile, ~touching distance)
- Crashed car detection: 32 pixels (half a tile)

### Crash Mechanics (UPDATED!)
- Cars must stay on road tiles (columns 1-16) or they crash
- **Crashed cars DON'T disappear** - they remain as obstacles
- Crashed cars have darkened sprite (50% gray)
- Active car hitting crashed car: only active car crashes
- Active car hitting active car: both crash
- Crashing costs 1 heart
- Game over when hearts reach 0

### Vehicle States
- **State 1 (Active)**: Car moves, executes code, detectable by `is_front_car()`
- **State 0 (Crashed)**: Car stops, stays on map, detectable by `is_front_crashed_car()`

---

## Supported Python Features

### Currently Supported:
- Function calls with parameters
- String literals ("left", "right")
- Integer literals (1, 2, 3, etc.)
- Comments (`# comment`)

### Not Yet Supported (Future):
- `if/elif/else` statements
- `while` loops
- `for` loops
- Variables
- Comparison operators (`==`, `!=`, `<`, `>`, etc.)
- Logical operators (`and`, `or`, `not`)

---

## UI Controls

**Map Editing (ALWAYS ENABLED!):**
- Left-click: Place road (-1 card) - **Works during gameplay**
- Right-click: Remove road (+1 card) - **Works during gameplay**
- Build alternate routes when cars crash!

**Stoplight Control:**
- Stoplight panel: Red/Yellow/Green buttons (top-right corner)

**Simulation Controls:**
- Run Code button: Start simulation and car spawning
- Space: Pause/Resume (pauses spawning too)
- R: Reset level (clears crashed cars, stops spawning)
- +/-: Adjust speed (2x, 4x, 0.5x)

**Car Spawning (NEW!):**
- Automatic: New car every 15 seconds after running code
- Each car executes the current code
- Stops when simulation ends or reset pressed

---

## Resources

- Hearts: Lives remaining (lose on crash)
- Road Cards: Tiles you can place/remove
- Both displayed in top-left corner of screen
