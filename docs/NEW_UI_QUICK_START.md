# New UI Quick Start Guide

## Enabling the New UI

1. Open `scenes/main.gd`
2. Find the line: `var use_new_ui: bool = false`
3. Change it to: `var use_new_ui: bool = true`
4. Save and run the game

## Keyboard Shortcuts

### Window Controls
- **Ctrl+1** - Toggle Code Editor window
- **Ctrl+2** - Toggle Documentation (README) window
- **Ctrl+3** - Toggle Skill Tree window

### Code Editor
- **Ctrl+N** - Create new file
- **Ctrl+S** - Save current file
- **F5** or **Ctrl+Enter** - Run code
- **F2** - Rename file (coming soon)

### Window Operations
- **Drag title bar** - Move window
- **Drag edges/corners** - Resize window
- **[−] button** - Minimize window
- **[×] button** - Close window
- **Click window** - Bring to front

## File Explorer

### Creating Files
1. Click **[+ File]** button in file explorer
2. Enter filename (e.g., `helpers.py`)
3. File appears in tree and opens in editor

### Creating Folders
1. Click **[+ Folder]** button in file explorer
2. Enter folder name (e.g., `modules`)
3. Folder appears in tree

### Deleting Files/Folders
1. Right-click on file or folder in tree
2. Select "Delete" from context menu
3. Confirm deletion

## Using the Import System

### Step 1: Create a helper module

Create a file called `helpers.py`:

```python
def avoid_crash():
    if car.front_crash():
        if car.left_road():
            car.turn("left")
        elif car.right_road():
            car.turn("right")

def navigate():
    if car.front_road():
        car.go()
    else:
        car.stop()
```

### Step 2: Import and use in main.py

In `main.py`:

```python
from helpers import avoid_crash, navigate

while not car.at_end():
    avoid_crash()
    navigate()
```

### Step 3: Run the code

Click **[▶ Run]** or press **F5**

## Window Persistence

Your window positions and sizes are automatically saved to:
- `user://window_settings.json`

They will be restored the next time you run the game.

## Status Bar

The status bar at the bottom of the Code Editor shows:
- **Ln X, Col Y** - Current cursor position
- **filename.py** - Current file name
- **✓ Saved** or **● Modified** - File save status

## Speed Control

Use the speed dropdown **[1x ▼]** to change simulation speed:
- **0.5x** - Slow motion
- **1.0x** - Normal speed (default)
- **2.0x** - 2x speed
- **4.0x** - 4x speed

## Tips

1. **Auto-save:** Files are automatically saved before running code
2. **Multi-file projects:** Create as many files as you need
3. **Organize with folders:** Use folders like `modules/` to organize code
4. **Documentation:** Press **Ctrl+2** to see full Python command reference
5. **Window layout:** Arrange windows however you like - positions are saved

## Troubleshooting

### Windows don't appear
- Press **Ctrl+1** to open Code Editor
- Check that `use_new_ui = true` in `scenes/main.gd`

### Can't see a window
- It might be off-screen - delete `user://window_settings.json` to reset positions

### Code doesn't run
- Make sure you saved the file (**Ctrl+S**)
- Check the main.py file is selected in file explorer

### Import errors
- Check that the module file exists in the file explorer
- Verify the import statement matches the filename
- For nested modules, use: `from modules.helpers import function_name`

## Default Files

When you first enable the new UI, these files are created automatically:

1. **main.py** - Your main code file
2. **README.md** - Documentation (read-only in file explorer)

You can create additional files as needed for your project.

## Example Multi-File Project

```
/ (root)
├── main.py          # Main code
├── helpers.py       # Helper functions
└── modules/
    ├── navigation.py   # Navigation logic
    └── safety.py       # Safety checks
```

**main.py:**
```python
from helpers import avoid_crash
from modules.navigation import find_path

while not car.at_end():
    avoid_crash()
    find_path()
```

**helpers.py:**
```python
def avoid_crash():
    if car.front_crash():
        if car.left_road():
            car.turn("left")
```

**modules/navigation.py:**
```python
def find_path():
    if car.front_road():
        car.go()
    elif car.left_road():
        car.turn("left")
```

## Enjoy!

You now have a professional multi-file Python development environment in GoCars. Happy coding!
