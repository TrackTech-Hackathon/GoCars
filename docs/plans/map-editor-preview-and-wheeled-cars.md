# Implementation Plan: Map Editor Preview & Wheeled Cars

## Overview
This plan covers two main features:
1. Update map editor preview to show a single tile following the mouse cursor
2. Create 6 car types with animated wheel rotation based on the wheeled-vehicle-template

---

## Part 1: Map Editor Preview Update

### Current State
- Map editor shows 8 preview tiles around a selected road (all visible at once)
- Tiles are 48x48 pixels (TILE_SIZE = 48)
- Preview tiles use RoadTile scene with 144x144 combo sprites

### New Requirements
- **Tile sizes are now 3x larger**: Main tile = 144x144, Combo sprites = 432x432
- **Single preview tile** follows the mouse cursor
- Preview shows in the direction the mouse is relative to the selected road
- Only one preview visible at a time (the one closest to mouse position)

### Files to Modify
1. `scenes/map_editor/map_editor.gd` - Update TILE_SIZE and preview logic
2. `scenes/map_editor/road_tile.gd` - No changes needed (logic stays the same)
3. `scenes/map_editor/road_tile.tscn` - Update sizes and textures to new assets

### Implementation Steps

#### Step 1.1: Update map_editor.gd
- Change `TILE_SIZE` from 48 to 144
- Modify `_update_previews()` to only show the preview closest to mouse cursor
- Add mouse position tracking to determine which direction preview to show

```gdscript
# Changes in map_editor.gd:
const TILE_SIZE: int = 144  # Was 48

func _update_previews() -> void:
    if not road_tool_enabled or not has_selection:
        _hide_all_previews()
        return

    # Get mouse position and determine closest preview direction
    var mouse_pos = get_global_mouse_position()
    var selected_world_pos = _tile_to_world(selected_pos) + Vector2(TILE_SIZE/2, TILE_SIZE/2)
    var direction_to_mouse = mouse_pos - selected_world_pos

    # Find the direction that best matches where mouse is
    var best_dir = _get_closest_direction(direction_to_mouse)

    # Hide all previews, then show only the one in best direction
    _hide_all_previews()

    if best_dir != "":
        var preview = preview_tiles[best_dir]
        var neighbor_pos = selected_pos + DIRECTIONS[best_dir]
        preview.position = _tile_to_world(neighbor_pos)
        # ... set connections as before
        preview.visible = true
```

#### Step 1.2: Update road_tile.tscn
- Update MainSprite size/region to 144x144
- Update ComboSprites positions and region_rect to 432x432 each
- Update collision shape size to 144x144
- Change texture references to new tileset files:
  - `gocarsTile1.png` for main tile
  - `gocarstilesSheet.png` for combo sprites

**New structure for combo sprites in the 432x432 sheet:**
```
Layout of gocarstilesSheet.png (3x3 grid of 432x432 tiles):
[TopLeft]    [Top]    [TopRight]
[Left]     [Center]    [Right]
[BottomLeft][Bottom][BottomRight]

Region rects:
- TopLeft:     (0, 0, 432, 432)
- Top:         (432, 0, 432, 432)
- TopRight:    (864, 0, 432, 432)
- Left:        (0, 432, 432, 432)
- Center:      (432, 432, 432, 432) - not used
- Right:       (864, 432, 432, 432)
- BottomLeft:  (0, 864, 432, 432)
- Bottom:      (432, 864, 432, 432)
- BottomRight: (864, 864, 432, 432)
```

---

## Part 2: Wheeled Cars System

### Current State
- Vehicle class exists in `scripts/entities/vehicle.gd`
- Uses CharacterBody2D with simple sprite
- No wheel animation
- 6 vehicle types defined in enum (SEDAN, SUV, MOTORCYCLE, JEEPNEY, TRUCK, TRICYCLE)

### New Requirements
- Create 6 cars using the `gocars.png` spritesheet (6 columns, 1 row)
- Each car has 4 animated wheels that rotate based on movement
- Wheel rotation speed proportional to car velocity
- Wheels are separate sprites that can be positioned per car type

### Reference: godot-wheeled-vehicle-template
The template uses:
- `Vehicle.gd` - RigidBody2D managing wheel groups
- `Wheel.gd` - Sprite with rotation based on steering/driving input
- Key concepts: wheel rotation based on velocity, steering angle interpolation

### Files to Create/Modify
1. `scenes/entities/wheel.gd` - New script for wheel rotation logic
2. `scenes/entities/wheel.tscn` - New scene for a single wheel sprite
3. `scenes/entities/vehicle.tscn` - Update to include 4 wheel instances
4. `scripts/entities/vehicle.gd` - Add wheel management and rotation logic

### Implementation Steps

#### Step 2.1: Create Wheel Script (`scenes/entities/wheel.gd`)
```gdscript
extends Sprite2D
class_name Wheel

## A wheel sprite that rotates based on vehicle movement
## Wheels spin forward/backward based on velocity

# Wheel configuration
@export var wheel_radius: float = 8.0  # Radius in pixels (for rotation calculation)
@export var is_front_wheel: bool = false  # Front wheels can steer

# Parent vehicle reference
var vehicle: Vehicle = null

# Visual rotation (spinning)
var spin_rotation: float = 0.0

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    if vehicle == null:
        return

    # Calculate wheel spin based on vehicle velocity
    var velocity_magnitude = vehicle.velocity.length()

    # Spin the wheel (rotation around its axle)
    # Circumference = 2 * PI * radius
    # Rotations = distance / circumference
    var spin_speed = velocity_magnitude / (2.0 * PI * wheel_radius)

    # Determine spin direction (forward = positive velocity projection)
    var forward = -global_transform.y.normalized()
    var velocity_dot = vehicle.velocity.dot(vehicle.direction)
    if velocity_dot < 0:
        spin_speed = -spin_speed

    # Apply spin rotation (visual only, around Z axis for 2D)
    spin_rotation += spin_speed * delta * 2.0 * PI

    # The wheel texture rotates to show spinning
    # For a 2D top-down view, we might instead scale or offset the texture
    # For now, we'll use a simple approach: modulate or animate frame if spritesheet
```

#### Step 2.2: Create Wheel Scene (`scenes/entities/wheel.tscn`)
- Sprite2D node with wheel texture
- Attach wheel.gd script
- Small circular sprite (~16x16 pixels)

#### Step 2.3: Update Vehicle Scene Structure
Each vehicle will have:
```
Vehicle (CharacterBody2D)
├── Sprite2D (car body from gocars.png, specific column)
├── CollisionShape2D
├── Wheels (Node2D container)
│   ├── WheelFL (front-left)
│   ├── WheelFR (front-right)
│   ├── WheelBL (back-left)
│   └── WheelBR (back-right)
```

#### Step 2.4: Update Vehicle.gd
Add wheel management:
```gdscript
# Add to vehicle.gd

# Wheel references
var wheels: Array[Wheel] = []

func _ready() -> void:
    # ... existing code ...

    # Find and register wheels
    var wheels_container = get_node_or_null("Wheels")
    if wheels_container:
        for wheel in wheels_container.get_children():
            if wheel is Wheel:
                wheel.vehicle = self
                wheels.append(wheel)

# Wheel positions per vehicle type (relative to center)
const WHEEL_POSITIONS: Dictionary = {
    VehicleType.SEDAN: {
        "FL": Vector2(-12, -20),
        "FR": Vector2(12, -20),
        "BL": Vector2(-12, 20),
        "BR": Vector2(12, 20)
    },
    # ... other types
}
```

#### Step 2.5: Car Sprite Regions from gocars.png
The `gocars.png` has 6 columns, each ~32 pixels wide (based on image):
```
Column 0: Car type 1 (red car)
Column 1: Car type 2
Column 2: Car type 3
Column 3: Car type 4
Column 4: Car type 5
Column 5: Car type 6 (gray/white car)
```

Each car type maps to a column in the spritesheet.

#### Step 2.6: Create 6 Vehicle Variant Scenes (Optional)
Could create separate .tscn files for each car type, or use a single scene with configurable sprite regions.

---

## Implementation Order

1. **Map Editor Preview** (Part 1)
   - Update TILE_SIZE in map_editor.gd
   - Update road_tile.tscn with new sizes and textures
   - Implement single-preview-follows-mouse logic

2. **Wheeled Cars** (Part 2)
   - Create wheel.gd script
   - Create wheel.tscn scene
   - Update vehicle.gd with wheel management
   - Update vehicle.tscn with wheel nodes
   - Configure wheel positions per vehicle type
   - Set up sprite regions from gocars.png

---

## Testing

### Map Editor Tests
- Verify tile placement works at new 144x144 size
- Verify only one preview shows at a time
- Verify preview follows mouse direction
- Verify combo sprites display correctly at 432x432

### Wheeled Car Tests
- Verify wheels spin when car moves
- Verify spin direction matches movement direction
- Verify spin speed is proportional to velocity
- Test all 6 car types
