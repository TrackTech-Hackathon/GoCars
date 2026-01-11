# Code Editor Button Fixes

## Overview
Fixed the Reset, Pause, and Speed control buttons in the Code Editor window to work properly.

## Changes Made

### 1. Reset Button Fix
**File**: `scenes/main.gd` (line 1213-1215)

**Problem**: Reset button only called `simulation_engine.reset()` which didn't fully reset the game state (hearts, cars, stoplight, etc.)

**Solution**: Changed to call `_do_fast_retry()` which performs a complete reset:
- Resets simulation engine
- Clears all spawned cars
- Respawns test vehicle
- Resets stoplight to initial state
- Resets hearts to initial value
- Resets car ID counter
- Disables car spawning
- Marks road paths as dirty for recalculation
- Updates UI status

```gdscript
func _on_window_manager_reset() -> void:
	"""Handle reset request from new UI - same as fast retry"""
	_do_fast_retry()
```

### 2. Speed Control Fix
**File**: `scenes/main.gd` (line 1217-1221)

**Problem**: Speed changes only took effect if simulation was running, due to `Engine.time_scale` only being updated in `simulation_engine.set_speed()` when `current_state == State.RUNNING`

**Solution**: Apply `Engine.time_scale` immediately in the handler:
```gdscript
func _on_window_manager_speed_changed(speed: float) -> void:
	"""Handle speed change from new UI - instant update"""
	simulation_engine.speed_multiplier = speed
	Engine.time_scale = speed  # Apply immediately
	_update_speed_label()
```

This ensures speed changes take effect instantly, whether the simulation is running or not.

### 3. Pause Button (Already Working)
**File**: `scenes/main.gd` (line 1209-1211)

The pause button was already working correctly:
```gdscript
func _on_window_manager_pause() -> void:
	"""Handle pause request from new UI"""
	simulation_engine.toggle_pause()
```

## Testing
All three buttons now work correctly:
- **Reset**: Fully resets game state like the original retry button (R key)
- **Pause**: Toggles pause/resume (same as Space key)
- **Speed**: Changes game speed instantly (0.5x, 1x, 2x, 4x)

## Files Modified
1. `scenes/main.gd` - Fixed `_on_window_manager_reset()` and `_on_window_manager_speed_changed()`
