# GoCars Tutorial Script

## Overview

Dialogue script for 5 tutorial stages. Character assets already exist - this is the dialogue content.

---

## TUTORIAL 1: "Welcome to GoCars!"

**Level Layout:** Straight road from left to right (about 5 tiles)
- Spawn: (0, 3)
- Destination: (4, 3)
- No stoplights, no turns

**Objective:** Learn the game interface and type `car.go()`

### Script:

```
STEP 1: Welcome
[Character appears]
"Welcome to GoCars! I'm Maki, and I'll teach you how to code cars!"
"In this game, you write REAL Python code to control vehicles."

STEP 2: Point at Car
[Arrow points to car on screen]
"See that car? That's YOUR car!"
"It won't move on its own - YOU have to tell it what to do with code."

STEP 3: Point at Code Editor Button
[Arrow points to code_editor_button]
"Click here to open the Code Editor - this is where you'll write your code!"
[WAIT: Player clicks to open code editor]

STEP 4: Code Editor Overview
[Code editor opens, arrow points to VBoxContainer/ContentContainer/ContentVBox/EditorContainer/CodeEdit]
"This is your Code Editor! It works just like a real programmer's editor."
"You write Python code here to control the car."

STEP 5: Point at File Explorer
[Arrow points to file_explorer]
"This is the File Explorer - you can create and manage code files here."
"For now, we'll use the default file."

STEP 6: Point at Run Button
[Arrow points to VBoxContainer/ContentContainer/ContentVBox/ControlBar/RunButton]
"This is the RUN button (or press F5). It executes your code!"

STEP 7: Point at Pause Button
[Arrow points to VBoxContainer/ContentContainer/ContentVBox/ControlBar/PauseButton]
"PAUSE button (Spacebar) - freezes the simulation."

STEP 8: Point at Reset Button
[Arrow points to VBoxContainer/ContentContainer/ContentVBox/ControlBar/ResetButton]
"RESET button (R) - restarts the level if things go wrong."

STEP 9: Point at Speed Controls
[Arrow points to speed controls]
"Speed controls: + to speed up, - to slow down."
"Great for watching your code in action!"

STEP 10: Shortcuts Summary
"Quick shortcuts to remember:"
"F5 = Run Code"
"Space = Pause/Resume"
"R = Reset Level"
"+ / - = Speed Up / Slow Down"

STEP 11: First Code Challenge
[Arrow points to VBoxContainer/ContentContainer/ContentVBox/EditorContainer/CodeEdit]
"Now let's make the car move!"
"Type this command in the code editor: car.go()"
"car.go() tells the car to start driving forward."
"The car will keep moving until it reaches the destination."
[WAIT: Player types car.go()]

STEP 12: Run the Code
[Arrow points to VBoxContainer/ContentContainer/ContentVBox/ControlBar/RunButton]
"Perfect! You typed car.go() - now let's run it!"
"Click the RUN button (or press F5) to execute your code and watch the car move!"
[WAIT: Player presses Run]

STEP 13: Success
[Car reaches destination]
"AMAZING! You just wrote your first line of code!"
"The car moved because YOU told it to. That's programming!"

[LEVEL COMPLETE]
```

---

## TUTORIAL 2: "Navigation Basics"

**Level Layout:** Zigzag maze road
```
[S]--[R]
	  |
[R]--[R]
|
[R]--[D]
```
- Spawn: (0, 1)
- Path: Right 3, Down-Right 1, Right 2, Down-Left 1, Left 3
- Destination: (4, 3)

**Objective:** Learn `car.move(N)` and `car.turn("direction")`

### Script:

```
STEP 1: Introduction
"Welcome back! Today we'll learn how to navigate turns."
"This road has corners - car.go() alone won't work here!"

STEP 2: Introduce car.move()
"First, let's learn car.move(N)"
"The N is how many tiles to move forward."
"Example: car.move(3) moves the car 3 tiles."

STEP 3: Introduce car.turn()
"To turn, use car.turn('left') or car.turn('right')"
"The car will rotate 90 degrees in that direction."

STEP 4: Challenge Setup
"Look at this zigzag road. You need to:"
"1. Move forward"
"2. Turn at corners"
"3. Reach the destination!"

STEP 5: Open Code Editor First
[Arrow points to code_editor_button]
"First, open the Code Editor by clicking this button!"
[WAIT: Player clicks to open code editor]

STEP 6: Guide First Move
[Arrow points to VBoxContainer/ContentContainer/ContentVBox/EditorContainer/CodeEdit]
"Start by typing: car.move(3)"
"This moves the car to the first corner."
[WAIT: Player types car.move(3)]

STEP 7: First Turn
"Now add a turn: car.turn('right')"
[WAIT: Player adds the turn]

STEP 7: Continue Navigation
"Keep going! Add more moves and turns to reach the end."
"Hint: The pattern is move, turn, move, turn..."
[WAIT: Player completes the code]

STEP 8: Demonstrate Crash (FORCED)
[Before player runs code, force a crash scenario]
"Wait! Before you run that, let me show you something important."
[Spawn a second car that crashes off-road]
"See that? When a car leaves the road, it CRASHES!"
[Arrow points to hearts/lives display]
"You lost 1 LIFE! You have 3 lives total."
"Lose all 3 and it's GAME OVER!"

STEP 9: Crashed Cars Stay
[Point at crashed car]
"Notice the crashed car is still there - darker and stopped."
"Crashed cars become OBSTACLES! Other cars must avoid them."

STEP 10: Run Your Code
"Now run YOUR code and navigate safely!"
[WAIT: Player runs code successfully]

STEP 11: Success
"Perfect navigation! You've mastered basic movement!"
"Remember: car.move(N) and car.turn('left'/'right')"

[LEVEL COMPLETE]
```

---

## TUTORIAL 3: "Traffic Lights"

**Level Layout:** Straight road with stoplight in middle
- Spawn: (0, 3)
- Stoplight at: (3, 3) - starts RED
- Destination: (6, 3)

**Objective:** Learn if statements and stoplight handling

### Script:

```
STEP 1: Introduction
"Time to learn about traffic lights!"
"In real life AND in code, you must stop at red lights."

STEP 2: Show the Stoplight
[Arrow points to red stoplight]
"See that red light? Your car needs to check it!"

STEP 3: FORCED RED LIGHT VIOLATION
"First, let me show you what happens if you ignore it..."
[Auto-run: car.go() without checking stoplight]
[Car runs the red light]
[Arrow points to hearts display]
"VIOLATION! Running a red light costs you 1 LIFE!"
"You now have 2 lives left. Be careful!"

STEP 4: Introduce if Statements
"To avoid this, we use IF statements."
"IF statements check a condition before doing something."

STEP 5: Show Syntax
"Here's the pattern:"
"if stoplight.is_red():"
"    car.stop()"
"else:"
"    car.go()"

STEP 6: Explain the Code
"This code CHECKS if the light is red."
"If red: stop the car"
"If not red (green/yellow): go!"

STEP 7: Stoplight Functions
"Stoplight commands you can use:"
"stoplight.is_red() - returns True if red"
"stoplight.is_green() - returns True if green"
"stoplight.is_yellow() - returns True if yellow"

STEP 8: Challenge
[Reset level, stoplight starts red then turns green]
"Now YOU write the code!"
"Make the car wait for green, then go."
[WAIT: Player writes if statement code]

STEP 9: Run Code
"Run your code and watch the car obey the traffic light!"
[WAIT: Player runs code]

STEP 10: Success
"Excellent! Your car waited for the green light!"
"IF statements let your car make DECISIONS."

[LEVEL COMPLETE]
```

---

## TUTORIAL 4: "Loops - The Power of Repetition"

**Level Layout:** Long winding road with multiple turns
```
[S]--[R]--[R]
		  |
	 [R]--[R]
	 |
[D]--[R]
```
- Spawn: (0, 0)
- Many turns required
- Destination: (0, 4)

**Objective:** Learn while loops with road detection

### Script:

```
STEP 1: Introduction
"What if the road is REALLY long with MANY turns?"
"Writing car.move() and car.turn() for each one is tedious!"

STEP 2: Introduce Loops
"LOOPS let you repeat code automatically!"
"A WHILE loop keeps running UNTIL a condition is false."

STEP 3: Show the Problem
"Look at this winding road. Without loops, you'd write:"
"car.move(2)"
"car.turn('right')"
"car.move(2)"
"car.turn('left')"
"...and on and on! There's a better way."

STEP 4: Introduce Road Detection
"Your car can DETECT roads around it!"
"car.front_road() - Is there road ahead?"
"car.left_road() - Is there road to the left?"
"car.right_road() - Is there road to the right?"
"car.at_end() - Am I at the destination?"

STEP 5: The Magic Loop
"Here's the magic code that handles ANY road:"

while not car.at_end():
	if car.front_road():
		car.go()
	elif car.left_road():
		car.turn("left")
	elif car.right_road():
		car.turn("right")

STEP 6: Explain the Loop
"Let me break this down:"
"while not car.at_end(): - Keep going until destination"
"if car.front_road(): car.go() - If road ahead, go!"
"elif car.left_road(): car.turn('left') - Otherwise turn left"
"elif car.right_road(): car.turn('right') - Or turn right"

STEP 7: Challenge
"Now type this loop and watch the magic!"
[WAIT: Player types the while loop]

STEP 8: Run Code
"Run it and watch your car navigate automatically!"
[WAIT: Player runs code]

STEP 9: Observe
[Car navigates the entire winding road]
"Look at that! ONE piece of code handles the ENTIRE road!"
"This is the power of LOOPS + CONDITIONS."

STEP 10: Success
"You've learned the most powerful technique in GoCars!"
"This loop pattern works on almost any road."

[LEVEL COMPLETE]
```

---

## TUTORIAL 5: "Putting It All Together"

**Level Layout:** Complex road with:
- Multiple turns
- One stoplight
- Longer path

```
[S]--[R]--[SL]--[R]
			   |
		  [R]--[R]
		  |
	 [D]--[R]
```
- Spawn: (0, 1)
- Stoplight: (2, 1) - cycles between red/green
- Destination: (1, 3)

**Objective:** Combine all skills: movement, turns, stoplights, and loops

### Script:

```
STEP 1: Final Challenge
"This is your FINAL tutorial challenge!"
"You'll need EVERYTHING you've learned:"
"- Movement commands"
"- Turn commands"
"- If statements"
"- While loops"
"- Road detection"
"- Stoplight handling"

STEP 2: Analyze the Road
[Camera pans over the road]
"Look at this road:"
"- It has turns (you'll need road detection)"
"- It has a stoplight (you'll need if statements)"
"- It's long (you'll need a loop)"

STEP 3: Hint at Solution
"Think about combining what you learned:"
"1. Use a while loop to keep going"
"2. Check the stoplight inside the loop"
"3. Use road detection for turns"

STEP 4: Challenge
"I won't give you the code this time."
"Use what you've learned to write it yourself!"
"Hint: Start with the loop from Tutorial 4, then add stoplight checking."
[WAIT: Player writes code]

STEP 5: Run Code
"Ready? Run your code!"
[WAIT: Player runs code]

STEP 6A: If Fails
[If car crashes or runs red light]
"Not quite! Remember:"
"- Check stoplight.is_red() before moving"
"- Use road detection for turns"
"Press R to reset and try again!"

STEP 6B: If Succeeds
"CONGRATULATIONS!"
"You've completed all the tutorials!"

STEP 7: Graduation
"You now know:"
"- car.go(), car.stop(), car.move(), car.turn()"
"- if/elif/else statements"
"- while loops"
"- Road detection: front_road(), left_road(), right_road()"
"- Stoplight handling"

STEP 8: Send Off
"You're ready for the REAL challenges!"
"The Campaign levels will test your skills."
"Good luck, and remember: Think like a programmer!"

[LEVEL COMPLETE - TUTORIALS FINISHED]
```

---

## Quick Reference

| Tutorial | Focus | Key Concepts |
|----------|-------|--------------|
| T1 | Interface | UI tour, `car.go()` |
| T2 | Navigation | `car.move()`, `car.turn()`, crash demo |
| T3 | Conditionals | `if/else`, stoplights, red light demo |
| T4 | Loops | `while`, road detection |
| T5 | Everything | Combine all skills |

---

## Action Types Reference

- `[DIALOGUE]` - Character speaks
- `[POINT: target]` - Arrow points at UI element
- `[WAIT: action]` - Wait for player to do something
- `[FORCE: event]` - System forces an event (crash, violation)
- `[LEVEL COMPLETE]` - End of tutorial
