# Feature Specification: Advanced Code Editor & Module System
## GoCars Update — Inspired by "The Farmer Was Replaced"

---

**Document Version:** 3.0  
**Date:** January 2026  
**Feature Priority:** P1 (High)  
**Estimated Complexity:** Medium-High  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Inspiration & Design Philosophy](#2-inspiration--design-philosophy)
3. [Feature Overview](#3-feature-overview)
4. [User Interface Specifications](#4-user-interface-specifications)
5. [Code Module System](#5-code-module-system)
6. [Documentation Window (README)](#6-documentation-window-readme)
7. [Technical Requirements](#7-technical-requirements)
8. [Implementation Plan](#8-implementation-plan)
9. [API Reference Updates](#9-api-reference-updates)
10. [User Stories](#10-user-stories)
11. [Acceptance Criteria](#11-acceptance-criteria)

---

## 1. Executive Summary

### What We're Building

Transform GoCars' code editor into a **floating window system** inspired by The Farmer Was Replaced, featuring:
- **Floating Code Editor Window** with integrated **file explorer sidebar** and **Run/Pause/Reset controls**
- **Floating README/Documentation Window** teaching gameplay and Python functions
- **Top-right toolbar buttons** to open/reopen windows (like The Farmer Was Replaced)
- **Skill Tree button** (UI only for now — future feature)
- **Import/module system** allowing players to write reusable, modular code
- **Easy file management** (create, rename, delete files) within the explorer
- **Draggable, resizable, minimizable windows** over the game world

### Key Design Decisions

1. **Run/Pause/Reset buttons are INSIDE the Code Editor window** — not in a global toolbar
2. **Top-right corner has 3 toolbar buttons** (like The Farmer Was Replaced):
   - `[+]` — Open Code Editor window
   - `[i]` — Open README/Docs window  
   - `[🌳]` — Open Skill Tree (button only, future feature)
3. **Single Code Editor window** with file explorer inside (not one window per file)

---

## 2. Inspiration & Design Philosophy

### The Farmer Was Replaced — What We're Adopting

From the reference images:
- ✅ **Top-right toolbar buttons** `[+] [i] [^^]` to open windows
- ✅ **Floating, draggable windows** over the game world
- ✅ **Window controls** (minimize `−`, close `×`)
- ✅ **Skill tree** accessible via toolbar button
- ✅ **Dark theme** with syntax highlighting
- ✅ **Game world visible** behind windows

### Toolbar Buttons (Top-Right Corner)

From The Farmer Was Replaced screenshot:
```
                                              [+] [i] [🌳]
                                               │   │   │
                    Opens new code window ─────┘   │   │
                    Opens info/docs window ────────┘   │
                    Opens skill/unlock tree ───────────┘
```

**GoCars adaptation:**
- `[+]` — Opens/reopens the **Code Editor** window
- `[i]` — Opens/reopens the **README** window
- `[🌳]` — Opens **Skill Tree** (button only for now, placeholder)

---

## 3. Feature Overview

### 3.1 Window Types

| Window | Purpose | Opened By | Can Close? |
|--------|---------|-----------|------------|
| **Code Editor** | Write/edit code with explorer + Run/Pause/Reset | `[+]` button | Yes (reopen via button) |
| **README / Docs** | Documentation, API reference | `[i]` button | Yes (reopen via button) |
| **Skill Tree** | Unlock progression (future) | `[🌳]` button | Yes |
| **Game World** | Background — traffic simulation | Always visible | N/A |

### 3.2 Core Features

| Feature | Description | Priority |
|---------|-------------|----------|
| **Toolbar Buttons** | Top-right `[+] [i] [🌳]` to open windows | P0 |
| **Floating Windows** | Draggable, resizable windows over game | P0 |
| **Code Editor + Explorer** | Single editor with file navigation sidebar | P0 |
| **Run/Pause/Reset in Editor** | Playback controls inside Code Editor window | P0 |
| **Multi-File Support** | Create, edit, save multiple .py files | P0 |
| **Import System** | `from module import function` syntax | P0 |
| **README Window** | Floating documentation panel | P0 |
| **Skill Tree Button** | Opens skill tree (UI placeholder) | P1 |
| **File Management** | Create, rename, delete files in explorer | P1 |
| **Window Controls** | Minimize, close, resize, drag | P1 |

### 3.3 File System Structure

```
📁 level_workspace/
├── 📄 main.py           # Entry point — runs when player clicks "Run"
├── 📄 README.md         # Opens in separate README window
├── 📂 my_modules/       # Player-created folder
│   ├── 📄 navigation.py
│   └── 📄 helpers.py
└── 📂 examples/         # Game-provided examples (read-only)
    └── 📄 basic_drive.py
```

---

## 4. User Interface Specifications

### 4.1 Overall Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  🚗 GoCars                           ❤️ 10   🎴 10        [+] [i] [🌳]     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                         ═══════════════════════════════                     │
│   ┌─[README]─────[−][×]┐      ║                   ║                         │
│   │ # GoCars Guide     │ 🚗 → ║       🚦          ║ → 🏁                    │
│   │                    │      ║                   ║                         │
│   │ ## How to Play     │ ═══════════════════════════════                    │
│   │ 1. Write code      │                                                    │
│   │ 2. Click Run       │           [GAME WORLD]                             │
│   │ 3. Watch cars!     │                                                    │
│   │                    │                                                    │
│   │ ## Car Commands    │  ┌─[Code Editor]─────────────────────────[−][×]┐   │
│   │ • car.go()         │  │ [▶ Run] [⏸ Pause] [🔄 Reset]   Speed [1x▼] │   │
│   │ • car.stop()       │  ├─────────────────────────────────────────────┤   │
│   │ • car.turn()       │  │ ┌──────────┬──────────────────────────────┐ │   │
│   │                    │  │ │ 📁 FILES │  1 │ # main.py               │ │   │
│   │ ## Imports         │  │ │          │  2 │                         │ │   │
│   │ from x import y    │  │ │ 📄 main◀ │  3 │ from helpers import x   │ │   │
│   │                    │  │ │ 📄 helpers│  4 │                         │ │   │
│   │ ## Stoplight       │  │ │ 📂 mods/ │  5 │ while not car.at_end(): │ │   │
│   │ • is_red()         │  │ │  └─ nav  │  6 │     car.go()            │ │   │
│   │ • is_green()       │  │ │          │  7 │                         │ │   │
│   └────────────────────┘  │ │ [+File]  │                              │ │   │
│                           │ │ [+Folder]│                              │ │   │
│                           │ └──────────┴──────────────────────────────┘ │   │
│                           │ Ln 5, Col 4 │ main.py │ Saved ✓             │   │
│                           └─────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Top-Right Toolbar Buttons

**Location:** Top-right corner of the game screen (not inside any window)

**Layout:**
```
                                                    [+]  [i]  [🌳]
                                                     │    │    │
                                                     │    │    └─ Skill Tree
                                                     │    └─ README/Docs
                                                     └─ Code Editor
```

**Button Specifications:**

| Button | Icon | Tooltip | Action |
|--------|------|---------|--------|
| `[+]` | Plus sign | "Open Code Editor" | Opens/focuses Code Editor window |
| `[i]` | Info/letter i | "Open Documentation" | Opens/focuses README window |
| `[🌳]` | Tree icon | "Open Skill Tree" | Opens Skill Tree (placeholder for now) |

**Button Behavior:**
- If window is **closed** → Opens the window
- If window is **open but behind** → Brings window to front
- If window is **minimized** → Restores the window
- If window is **already focused** → Does nothing (or minimizes, optional)

**Visual Style (matching The Farmer Was Replaced):**
```
┌─────┐ ┌─────┐ ┌─────┐
│  +  │ │  i  │ │ 🌳  │
└─────┘ └─────┘ └─────┘
   ↑        ↑       ↑
 Olive/   Olive/  Olive/
 Yellow   Yellow  Yellow
 background like TFWR
```

### 4.3 Code Editor Window (Floating)

**Window Title:** `Code Editor`

**Key Change:** Run/Pause/Reset buttons are **inside this window**, not in a global toolbar!

**Layout:**
```
┌─[Code Editor]────────────────────────────────────────────────────[−][×]┐
│                                                                        │
│  [▶ Run]  [⏸ Pause]  [🔄 Reset]                      Speed: [1x ▼]    │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│┌────────────┬─────────────────────────────────────────────────────────┐│
││ 📁 FILES   │  1 │ # main.py                                          ││
││            │  2 │ from helpers import smart_turn                     ││
││ 📄 main.py◀│  3 │                                                    ││
││ 📄 helpers │  4 │ while not car.at_end():                            ││
││ 📂 modules/│  5 │     if stoplight.is_red():                         ││
││  └─ nav.py │  6 │         car.stop()                                 ││
││            │  7 │     elif car.front_crash():                        ││
││ ─────────  │  8 │         smart_turn(car)                            ││
││ [+ File]   │  9 │     else:                                          ││
││ [+ Folder] │ 10 │         car.go()                                   ││
││            │ 11 │                                                    ││
│└────────────┴─────────────────────────────────────────────────────────┘│
│ Ln 5, Col 8 │ main.py │ ✓ Saved                                        │
└────────────────────────────────────────────────────────────────────────┘
```

**Components:**

| Component | Description |
|-----------|-------------|
| **Title Bar** | "Code Editor", drag handle, minimize `[−]`, close `[×]` |
| **Control Bar** | `[▶ Run]` `[⏸ Pause]` `[🔄 Reset]` + Speed dropdown |
| **File Explorer (Left)** | Tree view of files, click to open in editor |
| **Code Editor (Right)** | Text editor with line numbers, syntax highlighting |
| **Status Bar (Bottom)** | Current line/column, filename, save status |

**Control Bar Buttons:**

| Button | Shortcut | Action |
|--------|----------|--------|
| `[▶ Run]` | F5 or Ctrl+Enter | Execute code, start simulation |
| `[⏸ Pause]` | Space | Pause/resume simulation |
| `[🔄 Reset]` | R or Ctrl+R | Reset level, clear crashed cars |
| `Speed [1x▼]` | +/- | Dropdown: 0.5x, 1x, 2x, 4x |

**Window Controls:**
| Button | Action |
|--------|--------|
| `[−]` (Minimize) | Collapse window (reopen via `[+]` toolbar button) |
| `[×]` (Close) | Hide window (reopen via `[+]` toolbar button) |

**File Explorer Features:**
- 📄 File icons for `.py` files
- 📂 Folder icons (expandable/collapsible)
- ◀ Arrow or highlight indicates currently open file
- Right-click context menu: Rename, Delete, Duplicate
- `[+ File]` button creates new `.py` file
- `[+ Folder]` button creates new folder

### 4.4 README / Documentation Window (Floating)

**Window Title:** `README` or `Documentation`

**Layout:**
```
┌─[README]───────────────────────────[−][×]┐
│                                          │
│  # GoCars — Code Your Way Through Traffic│
│                                          │
│  ## 🎮 How to Play                       │
│  1. Write Python code in the editor      │
│  2. Click **Run** (or press F5)          │
│  3. Watch your car navigate!             │
│                                          │
│  ## 🚗 Car Commands                      │
│  ┌─────────────────────────────────────┐ │
│  │ car.go()      # Start moving        │ │
│  │ car.stop()    # Stop immediately    │ │
│  │ car.turn("left")  # Turn left 90°   │ │
│  │ car.turn("right") # Turn right 90°  │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ## 🚦 Stoplight                         │
│  • stoplight.is_red() → True/False       │
│  • stoplight.is_green() → True/False     │
│                                          │
│  ⚠️ Cars DON'T auto-stop at red lights!  │
│                                          │
│  ## 📦 Creating Modules                  │
│  ┌─────────────────────────────────────┐ │
│  │ # helpers.py                        │ │
│  │ def smart_turn(vehicle):            │ │
│  │     if vehicle.left_road():         │ │
│  │         vehicle.turn("left")        │ │
│  └─────────────────────────────────────┘ │
│                                          │
│  ┌─────────────────────────────────────┐ │
│  │ # main.py                           │ │
│  │ from helpers import smart_turn      │ │
│  │ smart_turn(car)                     │ │
│  └─────────────────────────────────────┘ │
│                                          │
└──────────────────────────────────────────┘
```

**Reopening:** Click `[i]` button in top-right toolbar

### 4.5 Skill Tree Window (Placeholder)

**Window Title:** `Skill Tree` or `Unlocks`

**For Now:** Just the button `[🌳]` in toolbar. When clicked:
- Opens a placeholder window with message: "Skill Tree coming soon!"
- Or shows the unlock tree UI (if implementing now)

**Future Feature:** Unlock tree like The Farmer Was Replaced showing:
- Crops/items to unlock (in GoCars: vehicle types, road types, abilities)
- Programming concepts (loops, functions, imports)
- Progress tracking (0/10 completed, etc.)

```
┌─[Skill Tree]──────────────────────────────────────[−][×]┐
│                                                         │
│     [🥕 Carrots]          [print()]        [1 + 1]      │
│        0/10                  ✓                ✓         │
│          │                   │                │         │
│     ─────┼───────────────────┼────────────────┼─────    │
│          │                   │                │         │
│    [🌾]  │  [🥬]       [set_speed()]    [(x,y)]         │
│    0/9   │  0/10           ✓               ✓            │
│          │                                              │
│                    (More unlocks...)                    │
│                                                         │
│              🎁 372  (unlock currency)                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 4.6 Window Management

**Behaviors:**
- Windows can overlap (z-order: click to bring to front)
- Windows can be dragged anywhere on screen
- Windows can be resized from edges/corners
- Closed windows can be reopened via toolbar buttons
- Window positions saved between sessions

**Toolbar Button States:**
- Window **closed** → Button normal state
- Window **open** → Button could show "active" indicator (optional)

---

## 5. Code Module System

### 5.1 Import Syntax

```python
# ✅ Supported import styles
from helpers import smart_turn           # Import specific function
from helpers import smart_turn, wait_for # Import multiple functions
from modules.pathfind import find_path   # Import from subfolder
import helpers                           # Import entire module

# ❌ NOT supported
from helpers import *                    # Wildcard imports
import helpers as h                      # Aliased imports
```

### 5.2 Module Resolution

When player writes `from helpers import smart_turn`:

1. **Search Order:**
   - Same directory as importing file
   - Root workspace directory
   - Subfolders (e.g., `modules/`)

2. **File Matching:**
   - `from helpers import x` → looks for `helpers.py`
   - `from modules.nav import x` → looks for `modules/nav.py`

### 5.3 Function Definitions

Players can define functions in module files:

```python
# helpers.py
def smart_turn(vehicle):
    """Turn toward an available road."""
    if vehicle.left_road():
        vehicle.turn("left")
    elif vehicle.right_road():
        vehicle.turn("right")
    else:
        vehicle.stop()

def wait_for_green(vehicle, light):
    """Wait until stoplight is green."""
    while light.is_red():
        vehicle.stop()
    vehicle.go()
```

```python
# main.py
from helpers import smart_turn, wait_for_green

car.go()
if car.front_crash():
    smart_turn(car)
wait_for_green(car, stoplight)
```

### 5.4 Passing Game Objects

Game objects (`car`, `stoplight`, `boat`) must be passed as parameters:

```python
# ✅ Correct — pass car as parameter
def smart_turn(vehicle):
    if vehicle.left_road():
        vehicle.turn("left")

# main.py
smart_turn(car)  # Pass 'car' to function

# ❌ Wrong — can't access 'car' directly in module
def smart_turn():
    if car.left_road():  # ERROR: 'car' is not defined
        car.turn("left")
```

### 5.5 Error Messages

| Error Type | Example | Message |
|------------|---------|---------|
| `ModuleNotFoundError` | `from xyz import a` | `ModuleNotFoundError: No module named 'xyz'` |
| `ImportError` | `from helpers import unknown` | `ImportError: cannot import name 'unknown' from 'helpers'` |
| `SyntaxError` | Bad function syntax | `SyntaxError: invalid syntax (helpers.py, line 5)` |
| `CircularImportError` | A imports B, B imports A | `CircularImportError: circular import between 'a' and 'b'` |

---

## 6. Documentation Window (README)

### 6.1 Content Structure

```markdown
# GoCars — Code Your Way Through Traffic

## 🎮 How to Play
1. Write Python code in the Code Editor
2. Click **Run** (or press F5)
3. Watch your cars navigate the traffic!
4. Reach the destination 🏁 without crashing

## 📍 Level Objective
[Dynamic per level]

## 🚗 Car Commands

### Movement
| Command | Description |
|---------|-------------|
| `car.go()` | Start moving forward |
| `car.stop()` | Stop immediately |
| `car.turn("left")` | Turn left 90° |
| `car.turn("right")` | Turn right 90° |
| `car.move(N)` | Move forward N tiles |
| `car.wait(N)` | Wait N seconds |

### Detection
| Command | Returns |
|---------|---------|
| `car.front_road()` | True if road ahead |
| `car.left_road()` | True if road to left |
| `car.right_road()` | True if road to right |
| `car.front_car()` | True if car ahead |
| `car.front_crash()` | True if crashed car ahead |
| `car.at_end()` | True if at destination |

## 🚦 Stoplight Commands
| Command | Description |
|---------|-------------|
| `stoplight.is_red()` | True if light is red |
| `stoplight.is_yellow()` | True if light is yellow |
| `stoplight.is_green()` | True if light is green |
| `stoplight.set_red()` | Change to red |
| `stoplight.set_green()` | Change to green |

⚠️ **Warning:** Cars do NOT auto-stop at red lights!
You must code: `if stoplight.is_red(): car.stop()`

## 📦 Import System

### Creating a Module
```python
# helpers.py
def smart_turn(vehicle):
    if vehicle.left_road():
        vehicle.turn("left")
    elif vehicle.right_road():
        vehicle.turn("right")
```

### Using a Module
```python
# main.py
from helpers import smart_turn

car.go()
smart_turn(car)
```

## 💡 Tips
- Always pass `car` or `stoplight` as parameters to your functions
- Use `while not car.at_end():` to loop until destination
- Crashed cars become obstacles — check with `car.front_crash()`
```

---

## 7. Technical Requirements

### 7.1 New Scripts to Create

| File | Purpose |
|------|---------|
| `scripts/ui/toolbar.gd` | Top-right toolbar with [+] [i] [🌳] buttons |
| `scripts/ui/floating_window.gd` | Base class for draggable/resizable windows |
| `scripts/ui/code_editor_window.gd` | Code editor with explorer + Run/Pause/Reset |
| `scripts/ui/file_explorer.gd` | File tree component |
| `scripts/ui/readme_window.gd` | Documentation viewer window |
| `scripts/ui/skill_tree_window.gd` | Skill tree placeholder window |
| `scripts/core/module_loader.gd` | Import resolution and loading |
| `scripts/core/virtual_filesystem.gd` | In-memory file system |

### 7.2 New Scenes to Create

| Scene | Description |
|-------|-------------|
| `scenes/ui/toolbar.tscn` | Top-right toolbar with buttons |
| `scenes/ui/floating_window.tscn` | Base floating window template |
| `scenes/ui/code_editor_window.tscn` | Code editor window instance |
| `scenes/ui/readme_window.tscn` | README window instance |
| `scenes/ui/skill_tree_window.tscn` | Skill tree window (placeholder) |
| `scenes/ui/file_tree_item.tscn` | Single file/folder entry |

### 7.3 Toolbar Implementation

```gdscript
# scripts/ui/toolbar.gd
extends HBoxContainer

signal open_code_editor_requested
signal open_readme_requested
signal open_skill_tree_requested

@onready var code_editor_btn: Button = $CodeEditorBtn
@onready var readme_btn: Button = $ReadmeBtn
@onready var skill_tree_btn: Button = $SkillTreeBtn

func _ready() -> void:
    code_editor_btn.pressed.connect(_on_code_editor_pressed)
    readme_btn.pressed.connect(_on_readme_pressed)
    skill_tree_btn.pressed.connect(_on_skill_tree_pressed)
    
    # Tooltips
    code_editor_btn.tooltip_text = "Open Code Editor"
    readme_btn.tooltip_text = "Open Documentation"
    skill_tree_btn.tooltip_text = "Open Skill Tree"

func _on_code_editor_pressed() -> void:
    open_code_editor_requested.emit()

func _on_readme_pressed() -> void:
    open_readme_requested.emit()

func _on_skill_tree_pressed() -> void:
    open_skill_tree_requested.emit()
```

### 7.4 Floating Window Base Class

```gdscript
# scripts/ui/floating_window.gd
extends Panel
class_name FloatingWindow

signal minimized
signal closed
signal focused

@export var window_title: String = "Window"
@export var can_close: bool = true
@export var can_minimize: bool = true
@export var can_resize: bool = true
@export var min_size: Vector2 = Vector2(200, 150)

var is_dragging: bool = false
var is_resizing: bool = false
var drag_offset: Vector2

@onready var title_bar: Panel = $TitleBar
@onready var title_label: Label = $TitleBar/Title
@onready var minimize_btn: Button = $TitleBar/MinimizeBtn
@onready var close_btn: Button = $TitleBar/CloseBtn
@onready var content: Control = $Content

func _ready() -> void:
    title_label.text = window_title
    minimize_btn.visible = can_minimize
    close_btn.visible = can_close
    minimize_btn.pressed.connect(_on_minimize)
    close_btn.pressed.connect(_on_close)

func _on_minimize() -> void:
    minimized.emit()
    visible = false

func _on_close() -> void:
    closed.emit()
    visible = false

func show_window() -> void:
    visible = true
    # Bring to front
    if get_parent():
        get_parent().move_child(self, -1)
    focused.emit()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed:
            # Bring to front when clicked
            if get_parent():
                get_parent().move_child(self, -1)
            focused.emit()
```

### 7.5 Code Editor Window with Controls

```gdscript
# scripts/ui/code_editor_window.gd
extends FloatingWindow

signal run_requested
signal pause_requested
signal reset_requested
signal speed_changed(speed: float)

@onready var run_btn: Button = $Content/ControlBar/RunBtn
@onready var pause_btn: Button = $Content/ControlBar/PauseBtn
@onready var reset_btn: Button = $Content/ControlBar/ResetBtn
@onready var speed_dropdown: OptionButton = $Content/ControlBar/SpeedDropdown
@onready var file_explorer: Control = $Content/HSplit/FileExplorer
@onready var code_edit: CodeEdit = $Content/HSplit/CodeEdit
@onready var status_bar: Label = $Content/StatusBar

var virtual_fs: VirtualFileSystem
var current_file: String = "main.py"

func _ready() -> void:
    super._ready()
    window_title = "Code Editor"
    
    run_btn.pressed.connect(_on_run)
    pause_btn.pressed.connect(_on_pause)
    reset_btn.pressed.connect(_on_reset)
    speed_dropdown.item_selected.connect(_on_speed_selected)
    
    # Setup speed options
    speed_dropdown.add_item("0.5x", 0)
    speed_dropdown.add_item("1x", 1)
    speed_dropdown.add_item("2x", 2)
    speed_dropdown.add_item("4x", 3)
    speed_dropdown.select(1)  # Default 1x

func _on_run() -> void:
    run_requested.emit()

func _on_pause() -> void:
    pause_requested.emit()

func _on_reset() -> void:
    reset_requested.emit()

func _on_speed_selected(index: int) -> void:
    var speeds = [0.5, 1.0, 2.0, 4.0]
    speed_changed.emit(speeds[index])
```

### 7.6 Main Scene Window Manager

```gdscript
# In main.gd or window_manager.gd

var code_editor_window: FloatingWindow
var readme_window: FloatingWindow
var skill_tree_window: FloatingWindow

func _ready() -> void:
    # Connect toolbar signals
    toolbar.open_code_editor_requested.connect(_on_open_code_editor)
    toolbar.open_readme_requested.connect(_on_open_readme)
    toolbar.open_skill_tree_requested.connect(_on_open_skill_tree)

func _on_open_code_editor() -> void:
    code_editor_window.show_window()

func _on_open_readme() -> void:
    readme_window.show_window()

func _on_open_skill_tree() -> void:
    skill_tree_window.show_window()
```

---

## 8. Implementation Plan

### Phase 1: Toolbar & Window System (2-3 days)

| Task | Estimate |
|------|----------|
| Create `toolbar.gd` with 3 buttons | 2 hours |
| Create `floating_window.gd` base class | 4 hours |
| Implement drag functionality | 2 hours |
| Implement resize functionality | 3 hours |
| Implement minimize/close | 2 hours |
| Window z-ordering (bring to front) | 1 hour |
| Connect toolbar to window manager | 2 hours |

**Milestone:** Toolbar buttons open/close floating windows

### Phase 2: Code Editor Window (3-4 days)

| Task | Estimate |
|------|----------|
| Create `code_editor_window.gd` | 3 hours |
| Add Run/Pause/Reset control bar | 2 hours |
| Add Speed dropdown | 1 hour |
| Create `virtual_filesystem.gd` | 3 hours |
| Create `file_explorer.gd` component | 4 hours |
| Integrate explorer into code editor | 3 hours |
| File selection → editor content | 2 hours |
| Create/rename/delete file UI | 4 hours |

**Milestone:** Code Editor with working controls and file explorer

### Phase 3: Module/Import System (4-5 days)

| Task | Estimate |
|------|----------|
| Add `from`/`import` tokens to parser | 2 hours |
| Add ImportStatement AST node | 3 hours |
| Add `def` function definition parsing | 4 hours |
| Add `return` statement parsing | 2 hours |
| Create `module_loader.gd` | 4 hours |
| Update interpreter for imports | 5 hours |
| User function call execution | 4 hours |
| Circular import detection | 2 hours |
| Import error messages | 2 hours |

**Milestone:** Can import functions from other files

### Phase 4: README Window (2 days)

| Task | Estimate |
|------|----------|
| Create `readme_window.gd` | 3 hours |
| Basic markdown rendering | 4 hours |
| Code block syntax highlighting | 2 hours |
| Scrollable content | 1 hour |

**Milestone:** README window shows formatted documentation

### Phase 5: Skill Tree Placeholder (0.5 days)

| Task | Estimate |
|------|----------|
| Create `skill_tree_window.gd` | 1 hour |
| Add placeholder content | 1 hour |
| Connect to toolbar button | 0.5 hours |

**Milestone:** Skill Tree button works (placeholder content)

### Phase 6: Polish & Integration (2 days)

| Task | Estimate |
|------|----------|
| Keyboard shortcuts | 2 hours |
| Syntax highlighting for imports | 2 hours |
| Error underlines | 2 hours |
| Window position persistence | 3 hours |
| Save/load workspace | 3 hours |

---

## 9. Keyboard Shortcuts

| Shortcut | Action | Context |
|----------|--------|---------|
| `F5` | Run code | Global / Code Editor |
| `Ctrl+Enter` | Run code | Code Editor |
| `Space` | Pause/Resume | Global |
| `R` | Reset level | Global |
| `Ctrl+R` | Reset level | Global |
| `+` / `=` | Speed up | Global |
| `-` | Slow down | Global |
| `Ctrl+1` | Open Code Editor | Global |
| `Ctrl+2` | Open README | Global |
| `Ctrl+3` | Open Skill Tree | Global |
| `Ctrl+N` | New file | Code Editor |
| `Ctrl+S` | Save file | Code Editor |
| `F2` | Rename file | File Explorer |

---

## 10. User Stories

### US-01: Opening Windows via Toolbar
**As a** player  
**I want to** click toolbar buttons to open windows  
**So that** I can access code editor, docs, or skill tree anytime

**Steps:**
1. Click `[+]` button → Code Editor window opens
2. Click `[i]` button → README window opens
3. Click `[🌳]` button → Skill Tree opens (placeholder)

### US-02: Running Code from Editor Window
**As a** player  
**I want to** click Run inside the Code Editor  
**So that** all controls are in one place

**Steps:**
1. Open Code Editor via `[+]` button
2. Write code in editor
3. Click `[▶ Run]` button inside window
4. Watch car execute code
5. Click `[⏸ Pause]` to pause
6. Click `[🔄 Reset]` to restart

### US-03: Reopening Closed Window
**As a** player  
**I want to** reopen a window I closed  
**So that** I don't lose access to features

**Steps:**
1. Close Code Editor with `[×]`
2. Click `[+]` toolbar button
3. Code Editor reappears with my code intact

---

## 11. Acceptance Criteria

### Critical (P0)

- [ ] Top-right toolbar has `[+]` `[i]` `[🌳]` buttons
- [ ] `[+]` button opens/reopens Code Editor window
- [ ] `[i]` button opens/reopens README window
- [ ] `[🌳]` button opens Skill Tree (placeholder OK)
- [ ] Code Editor window has Run/Pause/Reset buttons inside
- [ ] Code Editor window has Speed dropdown
- [ ] Code Editor has integrated file explorer sidebar
- [ ] Clicking file in explorer opens it in editor
- [ ] `from module import function` works
- [ ] `def function_name(params):` creates callable functions
- [ ] Floating windows can be dragged
- [ ] Floating windows can be closed and reopened via toolbar
- [ ] main.py runs when clicking Run button

### Important (P1)

- [ ] Floating windows can be resized
- [ ] Floating windows can be minimized
- [ ] Create new file via explorer button
- [ ] Rename/delete files
- [ ] Syntax highlighting for imports
- [ ] Window positions persist between sessions
- [ ] Keyboard shortcuts work (F5, Space, R)

### Nice to Have (P2)

- [ ] Skill Tree shows actual unlock progress
- [ ] Window snapping to edges
- [ ] Active indicator on toolbar buttons
- [ ] Drag-and-drop file reordering

---

## Appendix: Visual Reference

### Full Game Layout with Toolbar

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  🚗 GoCars                           ❤️ 10   🎴 10        [+] [i] [🌳]     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─[README]─────[−][×]┐       ═══════════════════════════════              │
│   │ # GoCars Guide     │            ║               ║                       │
│   │                    │       🚗 → ║      🚦       ║ → 🏁                  │
│   │ ## Car Commands    │            ║               ║                       │
│   │ • car.go()         │       ═══════════════════════════════              │
│   │ • car.stop()       │                                                    │
│   │                    │                 [GAME WORLD]                       │
│   └────────────────────┘                                                    │
│                                                                             │
│            ┌─[Code Editor]────────────────────────────────────────[−][×]┐   │
│            │ [▶ Run] [⏸ Pause] [🔄 Reset]              Speed: [1x ▼]   │   │
│            ├────────────────────────────────────────────────────────────┤   │
│            │ ┌──────────┬─────────────────────────────────────────────┐ │   │
│            │ │ 📁 FILES │  1 │ # main.py                              │ │   │
│            │ │          │  2 │                                        │ │   │
│            │ │ 📄 main◀ │  3 │ from helpers import smart_turn        │ │   │
│            │ │ 📄 helpers│  4 │                                        │ │   │
│            │ │          │  5 │ car.go()                               │ │   │
│            │ │ [+File]  │  6 │ smart_turn(car)                        │ │   │
│            │ └──────────┴─────────────────────────────────────────────┘ │   │
│            │ Ln 5, Col 4 │ main.py │ ✓                                  │   │
│            └────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Toolbar Button Detail

```
Top-right corner of screen:
                                                         ┌─────┬─────┬─────┐
                                                         │  +  │  i  │ 🌳  │
                                                         └─────┴─────┴─────┘
                                                            │     │     │
                                    Open Code Editor ───────┘     │     │
                                    Open README/Docs ─────────────┘     │
                                    Open Skill Tree ────────────────────┘
```

---

**End of Feature Specification**
