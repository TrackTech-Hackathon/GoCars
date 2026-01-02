extends Node2D

## Main scene controller - connects UI to SimulationEngine

@onready var simulation_engine: SimulationEngine = $SimulationEngine
@onready var code_editor: TextEdit = $UI/CodeEditor
@onready var run_button: Button = $UI/RunButton
@onready var status_label: Label = $UI/StatusLabel
@onready var speed_label: Label = $UI/SpeedLabel
@onready var test_vehicle: Vehicle = $GameWorld/TestVehicle
@onready var test_stoplight: Stoplight = $GameWorld/TestStoplight

# Result popup elements
@onready var result_popup: Panel = $UI/ResultPopup
@onready var result_title: Label = $UI/ResultPopup/ResultTitle
@onready var result_message: Label = $UI/ResultPopup/ResultMessage
@onready var retry_button: Button = $UI/ResultPopup/RetryButton
@onready var next_button: Button = $UI/ResultPopup/NextButton


func _ready() -> void:
	# Register vehicle with simulation engine
	simulation_engine.register_vehicle(test_vehicle)

	# Register stoplight if it exists
	if test_stoplight:
		simulation_engine.register_stoplight(test_stoplight)

	# Connect UI signals
	run_button.pressed.connect(_on_run_button_pressed)

	# Connect simulation signals
	simulation_engine.simulation_started.connect(_on_simulation_started)
	simulation_engine.simulation_paused.connect(_on_simulation_paused)
	simulation_engine.simulation_ended.connect(_on_simulation_ended)
	simulation_engine.car_reached_destination.connect(_on_car_reached_destination)
	simulation_engine.car_crashed.connect(_on_car_crashed)
	simulation_engine.level_completed.connect(_on_level_completed)
	simulation_engine.level_failed.connect(_on_level_failed)

	# Connect vehicle stoplight signals if vehicle exists
	if test_vehicle:
		test_vehicle.stopped_at_light.connect(_on_car_stopped_at_light)
		test_vehicle.resumed_from_light.connect(_on_car_resumed_from_light)

	# Connect result popup buttons
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)

	# Set initial code (example showing stoplight + car interaction)
	code_editor.text = "stoplight.set_green()\ncar.go()"

	_update_status("Ready - Enter code and press 'Run Code'")
	_update_speed_label()


func _on_run_button_pressed() -> void:
	var code = code_editor.text
	if code.strip_edges().is_empty():
		_update_status("Error: No code entered")
		return

	# Reset vehicle position before running
	test_vehicle.reset(Vector2(100, 300), Vector2.RIGHT)

	# Execute the code
	simulation_engine.execute_code(code)


func _on_simulation_started() -> void:
	_update_status("Running...")
	run_button.disabled = true


func _on_simulation_paused() -> void:
	_update_status("Paused (Press Space to resume)")


func _on_simulation_ended(success: bool) -> void:
	run_button.disabled = false
	if success:
		_update_status("Simulation complete!")
	else:
		_update_status("Simulation failed")


func _on_car_reached_destination(car_id: String) -> void:
	_update_status("Car '%s' reached destination!" % car_id)


func _on_car_crashed(car_id: String) -> void:
	_update_status("Car '%s' crashed!" % car_id)


func _on_level_completed(stars: int) -> void:
	_update_status("Level Complete! Stars: %s" % stars)
	_show_victory_popup(stars)


func _on_level_failed(reason: String) -> void:
	_update_status("Level Failed: %s" % reason)
	_show_failure_popup(reason)


func _on_car_stopped_at_light(car_id: String, stoplight_id: String) -> void:
	_update_status("Car '%s' stopped at red light '%s'" % [car_id, stoplight_id])


func _on_car_resumed_from_light(car_id: String, stoplight_id: String) -> void:
	_update_status("Car '%s' resumed (light '%s' turned green)" % [car_id, stoplight_id])


func _update_status(message: String) -> void:
	status_label.text = "Status: %s" % message


func _update_speed_label() -> void:
	speed_label.text = "Speed: %.1fx" % simulation_engine.speed_multiplier


func _show_victory_popup(stars: int) -> void:
	result_title.text = "LEVEL COMPLETE!"
	var star_display = ""
	for i in range(3):
		if i < stars:
			star_display += "[*]"
		else:
			star_display += "[ ]"
	result_message.text = "Stars: %s\nTime: %.1fs" % [star_display, simulation_engine.get_elapsed_time()]
	next_button.visible = true
	result_popup.visible = true


func _show_failure_popup(reason: String) -> void:
	result_title.text = "LEVEL FAILED"
	result_message.text = reason
	next_button.visible = false  # Can't proceed on failure
	result_popup.visible = true


func _hide_result_popup() -> void:
	result_popup.visible = false


func _on_retry_pressed() -> void:
	_hide_result_popup()
	simulation_engine.reset()
	test_vehicle.reset(Vector2(100, 300), Vector2.RIGHT)
	if test_stoplight:
		test_stoplight.reset()
	_update_status("Reset - Ready")
	run_button.disabled = false


func _on_next_pressed() -> void:
	_hide_result_popup()
	# For now, just reset - in full game this would load next level
	_on_retry_pressed()
	_update_status("Next level would load here - Ready")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				# Handle R key for reset
				_hide_result_popup()
				simulation_engine.reset()
				test_vehicle.reset(Vector2(100, 300), Vector2.RIGHT)
				if test_stoplight:
					test_stoplight.reset()
				_update_status("Reset - Ready")
				run_button.disabled = false
			KEY_EQUAL, KEY_KP_ADD, KEY_MINUS, KEY_KP_SUBTRACT:
				# Update speed label when speed changes
				# Give a small delay to let simulation engine process first
				call_deferred("_update_speed_label")
