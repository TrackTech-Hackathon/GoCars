# Advanced Features Testing Guide

## Overview
This guide shows you how to test all the advanced editor features that have been integrated into GoCars.

---

## How to Access the Advanced Features

### Opening the Code Editor
**Keyboard Shortcut:** `Ctrl+1`

The code editor will now spawn **centered on screen** (not anchored to top-left) and can be moved around by dragging the title bar.

---

## 🎯 Feature List & Testing Instructions

### 1. ✅ Python Syntax Highlighting
**Location:** Code editor window
**What it does:** Colors Python code like VS Code

**Test it:**
1. Press `Ctrl+1` to open code editor
2. Type this code:
```python
# This is a comment
if car.front_road():
    speed = 1.5
    car.set_speed(speed)
    car.go()
else:
    car.stop()
```

**Expected result:**
- Comments are green
- Keywords (`if`, `else`) are purple
- Functions (`front_road`, `set_speed`, `go`, `stop`) are yellow
- Strings are orange (if you add any)
- Numbers are light green
- Variables are light blue

---

### 2. ✅ IntelliSense (Auto-Complete)
**Location:** Code editor window
**What it does:** Shows smart suggestions as you type

**Test it:**
1. In code editor, type: `car.`
2. Wait 0.3 seconds
3. IntelliSense popup appears with suggestions:
   - `go()`
   - `stop()`
   - `move(tiles)`
   - `turn(direction)`
   - etc.

**Keyboard controls:**
- `↑` `↓` - Navigate suggestions
- `Enter` or `Tab` - Accept suggestion
- `Esc` - Close popup
- Continue typing to filter

**Advanced test:**
1. Type `stoplight.`
2. Should show stoplight methods: `red()`, `green()`, `is_red()`, etc.

---

### 3. ✅ Parameter Hints
**Location:** Code editor window
**What it does:** Shows function parameters as you type

**Test it:**
1. Type: `car.move(`
2. Parameter hint appears: `move(tiles: int)`
3. Type a number and close parenthesis: `car.move(5)`

**Try these:**
- `car.turn(` → shows `turn(direction: str)` with hint "'left' or 'right'"
- `car.set_speed(` → shows `set_speed(speed: float)` with range hint

---

### 4. ✅ Hover Tooltips
**Location:** Code editor window
**What it does:** Shows documentation when you hover over functions

**Test it:**
1. Type: `car.front_road()`
2. Hover mouse over `front_road`
3. Tooltip appears with description: "Check if there is a road directly in front of the car"

**Try hovering over:**
- `car.go()` - "Start moving forward at current speed"
- `stoplight.is_red()` - "Check if stoplight is red"
- Variables you've defined

---

### 5. ✅ Code Snippets
**Location:** Code editor window
**What it does:** Insert common code patterns quickly

**Test it:**
1. Type: `ifroad` (no space)
2. Press `Tab`
3. Expands to:
```python
if car.front_road():
    car.go()
else:
    car.turn("right")
```
4. Cursor is positioned inside the if block

**Available snippets:**
| Trigger | Expands to |
|---------|------------|
| `ifroad` | if front_road check |
| `ifred` | if stoplight is red |
| `whileend` | while not at_end loop |
| `ifcrash` | if front_crash check |
| `ifblock` | if blocked check |
| `ifdead` | if dead_end check |

**How to use:**
1. Type the trigger word
2. Press `Tab` to expand

---

### 6. ✅ Code Folding
**Location:** Code editor window (left margin)
**What it does:** Collapse/expand code blocks

**Test it:**
1. Write code with if/while blocks:
```python
if car.front_road():
    car.go()
    car.wait(1)
else:
    car.turn("left")
```
2. Look at left margin next to line 1
3. Click the `▼` arrow to fold the if block
4. Block collapses, arrow changes to `▶`
5. Click `▶` to unfold

**What you can fold:**
- `if` statements
- `elif` blocks
- `else` blocks
- `while` loops
- `for` loops

---

### 7. ✅ Code Linting (Error Detection)
**Location:** Code editor window (inline errors)
**What it does:** Shows errors before you run code

**Test it - Syntax Errors:**
1. Type invalid code:
```python
if car.front_road()   # Missing colon
    car.go()
```
2. Red squiggly line appears under `if` line
3. Hover to see error: "SyntaxError: expected ':' after if condition"

**Test it - Indentation Errors:**
1. Type:
```python
if car.front_road():
car.go()  # Wrong indentation
```
2. Error appears: "IndentationError: expected an indented block"

**Test it - Unknown Methods:**
1. Type:
```python
car.fly()  # This method doesn't exist
```
2. Warning appears: "AttributeError: 'car' has no method 'fly'"

**Error indicators:**
- Red squiggly underline
- Hover for details
- Errors update as you type

---

### 8. ✅ Execution Visualization
**Location:** Code editor window during execution
**What it does:** Highlights the currently executing line

**Test it:**
1. Write code with pauses:
```python
car.go()
car.wait(2)
car.stop()
```
2. Press `F5` (Run Code)
3. Line 1 highlights in yellow while executing
4. After 2 seconds, line 2 highlights
5. Then line 3 highlights

**What you'll see:**
- Yellow background on current line
- Line-by-line execution tracking
- Works with loops (you'll see the line highlight repeatedly)

---

### 9. ✅ Breakpoint Debugging
**Location:** Code editor left gutter
**What it does:** Pause execution at specific lines

**Test it:**
1. Write multi-line code:
```python
car.go()
car.wait(1)
car.stop()
```
2. Click in the left gutter (next to line numbers) on line 2
3. Red dot appears (breakpoint set)
4. Press `F5` to run
5. Execution pauses at line 2
6. Press `F5` again to continue (or use step buttons)

**Debugger controls:**
- **F5** - Continue execution
- **F10** - Step Over (next line)
- **F11** - Step Into (into function calls)
- **Shift+F11** - Step Out (out of function)

**Visual indicators:**
- Red dot = breakpoint
- Yellow highlight = current execution line

---

### 10. ✅ Performance Metrics
**Location:** Status bar (bottom of code editor)
**What it does:** Shows execution time and memory usage

**Test it:**
1. Write code:
```python
while not car.at_end():
    if car.front_road():
        car.go()
    else:
        car.turn("right")
```
2. Press `F5` to run
3. Look at bottom status bar
4. You'll see metrics update:
   - **Execution time:** `42ms` (example)
   - **Lines executed:** `127`
   - **Memory:** `2.4 KB`

**Metrics shown:**
- Parse time (how long to analyze code)
- Execution time (how long code ran)
- Line count executed
- Memory used by interpreter

---

## 🎮 Window Controls

### Moving Windows
- **Click and drag** the title bar to move windows anywhere
- Windows are no longer anchored to corners!

### Resizing Windows
- **Drag edges** to resize
- **Drag corners** for two-directional resize
- Minimum size enforced (can't make too small)

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| `Ctrl+1` | Open/close Code Editor |
| `Ctrl+2` | Open/close README |
| `Ctrl+3` | Open/close Skill Tree (future) |
| `Ctrl+N` | New file |
| `Ctrl+S` | Save file |
| `F2` | Rename file |
| `F5` | Run code / Continue debugging |
| `F10` | Step over (debugging) |
| `F11` | Step into (debugging) |
| `Shift+F11` | Step out (debugging) |

---

## 📁 File Explorer Features

**Location:** Left panel in Code Editor window

### Test it:
1. Open code editor (`Ctrl+1`)
2. See file explorer on left side
3. Files shown:
   - `main.py` (default, selected)
   - `README.md`

### Actions:
- **Click file** - Opens it in editor
- **+File button** - Create new file
- **+Folder button** - Create new folder (future)
- **Rename button** - Rename selected file (`F2`)

### Virtual File System:
- Files are stored in memory (not on disk)
- Automatically saved when you switch files
- Persists during gameplay session

---

## 🧪 Quick Test Checklist

Use this to verify everything works:

- [ ] Code editor opens centered (not top-left)
- [ ] Can drag window around by title bar
- [ ] Python syntax highlighting works (colors)
- [ ] Type `car.` and IntelliSense popup appears
- [ ] Press `Tab` after typing `ifroad` to expand snippet
- [ ] Hover over `car.go()` shows tooltip
- [ ] Write invalid code, see red squiggly error
- [ ] Click gutter to set breakpoint (red dot appears)
- [ ] Run code, see yellow line highlight during execution
- [ ] Fold/unfold an if statement
- [ ] Check status bar for performance metrics
- [ ] Create new file with `+File` button
- [ ] Switch between files in explorer

---

## 🐛 Troubleshooting

### IntelliSense not appearing?
- Wait 0.3 seconds after typing
- Make sure you typed the dot: `car.`
- Try pressing `Ctrl+Space` to manually trigger

### Syntax highlighting not working?
- Check that file ends with `.py`
- Restart the game if needed

### Breakpoints not working?
- Debugger may not be initialized
- Try running code once first, then set breakpoints

### Window stuck off-screen?
- Close and reopen with `Ctrl+1`
- Window will re-center

### Features not showing?
- Make sure `use_new_ui = true` in `main.gd` line 27
- Check console for errors

---

## 🎓 Educational Value

These features teach students:

1. **Syntax Highlighting** - Helps recognize Python structure
2. **IntelliSense** - Discovers available functions without memorization
3. **Parameter Hints** - Learns function signatures
4. **Hover Docs** - Understands what functions do
5. **Code Snippets** - Learns common patterns quickly
6. **Linting** - Catches errors before running (debugging skill)
7. **Execution Viz** - Understands program flow visually
8. **Breakpoints** - Professional debugging techniques
9. **Code Folding** - Manages complex code organization
10. **Metrics** - Performance awareness

---

## 📝 Next Steps

1. **Test each feature** using the instructions above
2. **Report any bugs** you find
3. **Suggest improvements** based on your experience
4. **Try combining features** (e.g., use IntelliSense + snippets + debugging together)

---

## 🎉 Enjoy Your Enhanced Editor!

The code editor is now feature-complete with professional IDE capabilities while remaining accessible for students learning Python!
