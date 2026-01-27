# Stoplight Code - Quick Reference

## Setting Stoplight Code

In the Inspector, find the Stoplight node and set the **Stoplight Code** export variable:

```python
# Example: Standard traffic light cycle
while True:
    stoplight.green()
    wait(5)
    stoplight.yellow()
    wait(2)
    stoplight.red()
    wait(5)
```

## API Reference

### Set Colors with Directions

```python
# Set specific directions
stoplight.green("north", "south")    # Make north and south green
stoplight.red("east", "west")        # Make east and west red
stoplight.yellow("north")             # Make only north yellow

# Set all directions (no arguments needed)
stoplight.green()    # All directions green
stoplight.red()      # All directions red
stoplight.yellow()   # All directions yellow
```

### Check Colors

```python
# Check global state (any direction)
stoplight.is_red()      # True if any direction is red
stoplight.is_green()    # True if any direction is green
stoplight.is_yellow()   # True if any direction is yellow

# Check specific direction
stoplight.is_red("north")      # True if north is red
stoplight.is_green("south")    # True if south is green
stoplight.is_yellow("east")    # True if east is yellow
```

### Timing

```python
wait(5)      # Pause for 5 seconds
wait(2.5)    # Pause for 2.5 seconds (decimals work!)
```

## Common Patterns

### Pattern 1: Simple 2-Way (Alternating)
```python
while True:
    stoplight.green()
    wait(5)
    stoplight.yellow()
    wait(2)
    stoplight.red()
    wait(5)
```

### Pattern 2: 4-Way Intersection (Standard)
```python
while True:
    # North-South green
    stoplight.green("north", "south")
    stoplight.red("east", "west")
    wait(5)
    
    # Yellow warning
    stoplight.yellow("north", "south")
    wait(2)
    
    # East-West green
    stoplight.green("east", "west")
    stoplight.red("north", "south")
    wait(5)
    
    # Yellow warning
    stoplight.yellow("east", "west")
    wait(2)
```

### Pattern 3: Always Green (No Wait)
```python
stoplight.green()
```

### Pattern 4: Asymmetric Timing
```python
while True:
    # Main road gets more time
    stoplight.green("north", "south")
    stoplight.red("east", "west")
    wait(7)
    
    # Side road gets less time
    stoplight.green("east", "west")
    stoplight.red("north", "south")
    wait(4)
```

### Pattern 5: With Yellow Lights on Both Sides
```python
while True:
    stoplight.green("north", "south")
    stoplight.red("east", "west")
    wait(5)
    
    stoplight.yellow("north", "south")
    stoplight.red("east", "west")
    wait(2)
    
    stoplight.red("north", "south")
    stoplight.green("east", "west")
    wait(5)
    
    stoplight.red("north", "south")
    stoplight.yellow("east", "west")
    wait(2)
```

## Preset Codes

You can use built-in preset codes instead of typing:

```gdscript
# In Godot Inspector, drag/drop these into Stoplight Code:
Stoplight.PRESET_STANDARD_4WAY    # Full 4-way with all transitions
Stoplight.PRESET_FAST_CYCLE       # Shorter timings (3s main, 1s yellow)
Stoplight.PRESET_ALL_GREEN        # Always green (no waits)
Stoplight.PRESET_ALWAYS_RED_NS    # N/S red, E/W green (asymmetric)
```

## Hover UI

When you hover your mouse near a stoplight in the game:
- A popup shows the stoplight's code
- The currently executing line is highlighted with a ▶ indicator
- A timer shows how long until the next state change
- If editable, you can click to modify the code

## Tips & Tricks

1. **Testing Timing** - Use shorter wait times during development:
   ```python
   wait(2)  # Quick 2-second cycle for testing
   wait(5)  # Full 5-second cycle for gameplay
   ```

2. **Asymmetric Intersections** - Different timing for different directions:
   ```python
   stoplight.green("north", "south")
   wait(7)  # Main road gets more time
   
   stoplight.green("east", "west")
   wait(4)  # Side road gets less time
   ```

3. **Complex Patterns** - Use variables (coming in future update):
   ```python
   main_duration = 7
   side_duration = 4
   yellow_duration = 2
   ```

4. **Debugging** - Add print statements:
   ```python
   while True:
       print("Light turning green")
       stoplight.green()
       wait(5)
       print("Light turning yellow")
       stoplight.yellow()
       wait(2)
   ```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Stoplight not changing | Make sure `wait()` is called, otherwise code runs instantly |
| Wrong directions affected | Use exact direction names: "north", "south", "east", "west" |
| Car ignores stoplight | Check if `is_red()` is being called in car code |
| Code not running | Check for syntax errors (use hover UI to see error message) |

## More Examples

### Example 1: Pedestrian Crossing
```python
# Assume east-west is pedestrian crossing
while True:
    # Car traffic
    stoplight.green("north", "south")
    stoplight.red("east", "west")
    wait(8)
    
    # Pedestrian crossing
    stoplight.red("north", "south")
    stoplight.green("east", "west")
    wait(4)
```

### Example 2: Rush Hour Timing
```python
while True:
    # Morning: favor northbound
    stoplight.green("north")
    stoplight.red("south")
    wait(6)
    
    # Allow other directions
    stoplight.green("east", "west")
    stoplight.red("north", "south")
    wait(4)
```

### Example 3: Multi-Phase Signal
```python
while True:
    # Phase 1: N-S protected left turn
    stoplight.green("north", "south")
    stoplight.red("east", "west")
    wait(5)
    
    # Phase 2: N-S yellow clearance
    stoplight.yellow("north", "south")
    stoplight.red("east", "west")
    wait(2)
    
    # Phase 3: E-W protected left turn
    stoplight.green("east", "west")
    stoplight.red("north", "south")
    wait(5)
    
    # Phase 4: E-W yellow clearance
    stoplight.yellow("east", "west")
    stoplight.red("north", "south")
    wait(2)
```
