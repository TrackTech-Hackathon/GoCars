# Update 3: Crashed Car Obstacle System

## Overview
Major gameplay update! Cars no longer disappear when they crash - they remain as obstacles on the road, forcing players to code around them. This creates a dynamic puzzle where players must build alternate routes.

---

## 🚗 New Crash Mechanics

### Crashed Cars Stay on the Map
- **Before**: Cars were deleted when they crashed
- **After**: Cars remain as darkened obstacles (gray tint)
- **Visual**: Crashed cars have 50% darker sprite (modulate = 0.5, 0.5, 0.5)
- **Future**: Placeholder for crashed car sprite (TODO)

### Vehicle State System
Every vehicle has a `vehicle_state` property:
- **State 1**: Normal/Active - Car functions normally
- **State 0**: Crashed - Car stops all movement, becomes an obstacle

### What Causes Crashes
1. **Off-road** - Car moves onto grass tile → Crashes
2. **Car-to-Car** - Active car hits active car → Both crash
3. **Hit crashed car** - Active car hits crashed car → Active car crashes

---

## 🔄 Automatic Car Spawning

### Spawning System
- **When**: Starts when you run code
- **Interval**: Every 15 seconds
- **Location**: Position (100, 300) facing RIGHT
- **Destination**: Position (700, 300)
- **ID**: Cars are numbered: car1, car2, car3, etc.

### Code Execution on Spawn
- New cars **automatically** execute the current code in the editor
- This means your code must handle multiple cars simultaneously
- Plan for different scenarios as more cars spawn

---

## 🛠️ Road Editing During Gameplay

### NEW: Edit While Running!
- **Before**: Map editing disabled during simulation
- **After**: You can place/remove roads WHILE code is running!

### Strategic Gameplay
1. Run your code
2. Car crashes? Build an alternate route!
3. Place roads to guide future spawned cars
4. Remove blocked roads to force new paths

### Resource Management
- Still costs road cards to place roads
- Still refunds road cards when removing roads
- Hearts decrease on crashes as before

---

## 🔍 New Detection Methods

### Python API Additions

#### `car.is_front_car()`
Check if there's **any** car (active or crashed) in front.
```python
if car.is_front_car():
    car.stop()  # Stop before hitting the car
```

#### `car.is_front_crashed_car()`
Check specifically for **crashed** cars in front.
```python
if car.is_front_crashed_car():
    # Try to go around the crashed car
    if car.is_left_road():
        car.turn("left")
    elif car.is_right_road():
        car.turn("right")
```

---

## 🎮 Gameplay Loop

### Example Scenario:

**1. Initial State**
```
Hearts: 10
Road Cards: 10
Cars: 1 active car
```

**2. Run Code**
```python
car.go()
```

**3. Car Crashes** (went off-road)
```
Hearts: 9
Crashed cars on map: 1 (darkened sprite at crash location)
```

**4. Player Edits Map** (while code is still running!)
- Uses 3 road cards to build alternate route
- Road Cards: 7

**5. New Car Spawns** (15 seconds later)
- Executes same `car.go()` code
- Takes the new route you built
- Avoids the crashed car

**6. Repeat**
- Every 15 seconds, a new car spawns
- Each car must navigate around all crashed cars
- Player keeps editing roads to guide them

---

## 💡 Strategy Tips

### Defensive Coding
```python
# Check for obstacles before moving
if car.is_front_road() and not car.is_front_car():
    car.go()
else:
    # Find alternate route
    if car.is_left_road():
        car.turn("left")
    elif car.is_right_road():
        car.turn("right")
```

### Handle Crashed Cars
```python
# Navigate around crashed cars
if car.is_front_crashed_car():
    car.stop()
    if car.is_left_road():
        car.turn("left")
        car.go()
```

### Plan for Spawns
- Your code runs on EVERY new car
- Design code that works for cars in different positions
- Account for crashed cars from previous cars

---

## 🔧 Reset Behavior

### What Happens on Reset (R key)
1. Simulation stops
2. Car spawning stops
3. **All crashed cars are removed**
4. Test vehicle respawns if crashed
5. Hearts reset to 10
6. Map stays as-is (roads you placed remain)

---

## 📝 Technical Details

### Vehicle State Property
```gdscript
var vehicle_state: int = 1  # 1 = active, 0 = crashed
```

### Crash Function (Internal)
```gdscript
func _on_crash() -> void:
    stop()
    vehicle_state = 0  # Mark as crashed
    modulate = Color(0.5, 0.5, 0.5, 1.0)  # Darken sprite
    crashed.emit(vehicle_id)
    # Car stays in scene, does not queue_free()
```

### Collision Detection
```gdscript
# If we hit a crashed car (state 0), only this car crashes
if other_vehicle.vehicle_state == 0:
    _on_crash()
    return

# If both cars active (state 1), both crash
if vehicle_state == 1 and other_vehicle.vehicle_state == 1:
    _on_crash()
    other_vehicle._on_crash()
```

### Vehicle Group
All vehicles are in the "vehicles" group for detection:
```gdscript
func _ready():
    add_to_group("vehicles")
```

---

## 🎯 Updated Python API

### Complete List of Car Methods

**Movement:**
- `car.go()` - Start moving
- `car.stop()` - Stop immediately
- `car.move(N)` - Move N tiles
- `car.turn("left")` / `car.turn("right")` - Turn 90°
- `car.wait(seconds)` - Pause

**Road Detection:**
- `car.is_front_road()` - Check if road ahead
- `car.is_left_road()` - Check if road to left
- `car.is_right_road()` - Check if road to right

**Car Detection (NEW):**
- `car.is_front_car()` - Check if ANY car ahead
- `car.is_front_crashed_car()` - Check if CRASHED car ahead

---

## 🐛 Bug Fixes

### Fixed: Reset Crash
- **Issue**: Pressing R crashed when test vehicle was deleted
- **Fix**: Added `is_instance_valid()` check before accessing vehicle
- **Behavior**: If vehicle crashed, a new one spawns on reset

---

## 📊 Updated Instructions UI

```
Instructions:
- car.go() / car.stop() / car.turn(left) / car.turn(right) / car.move(N) / car.wait(N)
- if car.is_front_road(): / if car.is_front_car(): / if car.is_front_crashed_car():
- Click tiles to place/remove roads (costs road cards) - NOW WORKS DURING GAMEPLAY!
- Space: pause/resume | R: reset | +/-: speed | S: step
```

---

## 🚀 Example Complete Solution

```python
# Navigate around obstacles and crashed cars
if car.is_front_car() or car.is_front_crashed_car():
    # Obstacle ahead, try to turn
    if car.is_left_road():
        car.turn("left")
    elif car.is_right_road():
        car.turn("right")
    else:
        car.stop()  # Stuck, wait for player to build a road
elif car.is_front_road():
    car.go()
else:
    # Dead end, try turning
    if car.is_left_road():
        car.turn("left")
    elif car.is_right_road():
        car.turn("right")
```

---

## 📁 Modified Files

**Core Systems:**
- `scripts/entities/vehicle.gd` - Vehicle state system, crash behavior, car detection
- `scripts/core/code_parser.gd` - Added `is_front_car`, `is_front_crashed_car`
- `scripts/core/simulation_engine.gd` - Call new detection methods
- `scenes/main.gd` - Car spawning, reset fix, keep editing enabled
- `scenes/main.tscn` - Updated instructions

**New Features:**
- Vehicle state property (0 = crashed, 1 = active)
- Vehicle group system for detection
- Car spawning timer and spawn function
- Clear crashed cars on reset
- Edit roads during gameplay

---

## 🎊 Ready to Play!

The game now features:
- ✅ Crashed cars become permanent obstacles
- ✅ Cars spawn every 15 seconds
- ✅ Edit roads during gameplay
- ✅ Detect cars and crashed cars in code
- ✅ Strategic puzzle gameplay
- ✅ No more crashes on reset!

Build your code to handle the chaos! 🏎️💥🛣️
