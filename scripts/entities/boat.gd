extends Node2D
class_name Boat

## Ferry boat entity for water/port levels.
## Supports: depart(), is_ready(), is_full(), get_passenger_count()
##
## Boats dock at ferry terminals and transport vehicles across water.
## Vehicles can drive onto the boat when it's docked.
## The boat departs automatically when full or when depart() is called.

signal boat_departed(boat_id: String)
signal boat_arrived(boat_id: String)
signal vehicle_boarded(boat_id: String, vehicle_id: String)
signal vehicle_disembarked(boat_id: String, vehicle_id: String)
signal state_changed(boat_id: String, new_state: String)

# Boat states
enum BoatState { DOCKED, DEPARTING, TRAVELING, ARRIVING }

# Boat properties
@export var boat_id: String = "boat1"
@export var capacity: int = 3  # Max number of vehicles
@export var travel_time: float = 5.0  # Seconds to cross water
@export var departure_position: Vector2 = Vector2.ZERO  # Where boat docks for boarding
@export var arrival_position: Vector2 = Vector2.ZERO  # Where boat docks for disembarking

# Current state
var current_state: BoatState = BoatState.DOCKED
var _passengers: Array = []  # Array of Vehicle references
var _travel_timer: float = 0.0
var _is_at_departure: bool = true  # True = at departure dock, False = at arrival dock

# Animation
var _move_speed: float = 100.0  # Pixels per second for visual movement
var _target_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Set initial position
	if departure_position != Vector2.ZERO:
		global_position = departure_position
	_target_position = global_position


func _process(delta: float) -> void:
	match current_state:
		BoatState.DEPARTING:
			_process_departing(delta)
		BoatState.TRAVELING:
			_process_traveling(delta)
		BoatState.ARRIVING:
			_process_arriving(delta)


func _process_departing(delta: float) -> void:
	# Move away from dock slightly before traveling
	var depart_offset = Vector2(0, -50)  # Move slightly away
	_target_position = departure_position + depart_offset

	var distance = global_position.distance_to(_target_position)
	if distance > 5:
		var dir = (departure_position + depart_offset - global_position).normalized()
		global_position += dir * _move_speed * delta
	else:
		# Done departing, start traveling
		current_state = BoatState.TRAVELING
		_travel_timer = travel_time
		state_changed.emit(boat_id, "traveling")
		boat_departed.emit(boat_id)


func _process_traveling(delta: float) -> void:
	_travel_timer -= delta

	# Interpolate position during travel
	var travel_progress = 1.0 - (_travel_timer / travel_time)
	travel_progress = clamp(travel_progress, 0.0, 1.0)

	# Smooth movement from departure to arrival
	var depart_offset = departure_position + Vector2(0, -50)
	var arrive_offset = arrival_position + Vector2(0, -50)
	global_position = depart_offset.lerp(arrive_offset, travel_progress)

	if _travel_timer <= 0:
		# Arrived at destination, start docking
		current_state = BoatState.ARRIVING
		_target_position = arrival_position
		state_changed.emit(boat_id, "arriving")


func _process_arriving(delta: float) -> void:
	# Move to dock position
	var distance = global_position.distance_to(arrival_position)
	if distance > 5:
		var dir = (arrival_position - global_position).normalized()
		global_position += dir * _move_speed * delta
	else:
		# Docked at arrival
		global_position = arrival_position
		current_state = BoatState.DOCKED
		_is_at_departure = false
		state_changed.emit(boat_id, "docked")
		boat_arrived.emit(boat_id)

		# Disembark all passengers
		_disembark_all()


# ============================================
# Command Functions (called by SimulationEngine)
# ============================================

## Force the boat to depart immediately
func depart() -> void:
	if current_state == BoatState.DOCKED and _is_at_departure:
		_start_departure()


## Check if the boat is docked and ready for boarding
func is_ready() -> bool:
	return current_state == BoatState.DOCKED and _is_at_departure


## Check if the boat is at full capacity
func is_full() -> bool:
	return _passengers.size() >= capacity


## Get the number of vehicles currently on board
func get_passenger_count() -> int:
	return _passengers.size()


# ============================================
# Vehicle Boarding/Disembarking
# ============================================

## Board a vehicle onto the boat
func board_vehicle(vehicle: Vehicle) -> bool:
	if current_state != BoatState.DOCKED:
		return false

	if not _is_at_departure:
		return false

	if is_full():
		return false

	if vehicle in _passengers:
		return false  # Already on board

	_passengers.append(vehicle)
	vehicle_boarded.emit(boat_id, vehicle.vehicle_id)

	# Hide vehicle while on boat (or reparent to boat)
	vehicle.visible = false
	vehicle.is_moving = false

	# Auto-depart if full
	if is_full():
		_start_departure()

	return true


## Disembark all vehicles at arrival dock
func _disembark_all() -> void:
	for vehicle in _passengers:
		if is_instance_valid(vehicle):
			vehicle.visible = true
			# Position vehicle at arrival position
			vehicle.global_position = arrival_position + Vector2(50, 0)
			vehicle_disembarked.emit(boat_id, vehicle.vehicle_id)

	_passengers.clear()


## Start the departure sequence
func _start_departure() -> void:
	if current_state != BoatState.DOCKED:
		return

	current_state = BoatState.DEPARTING
	state_changed.emit(boat_id, "departing")


# ============================================
# State Queries
# ============================================

## Get the current state as a string
func get_state() -> String:
	match current_state:
		BoatState.DOCKED:
			if _is_at_departure:
				return "docked_departure"
			else:
				return "docked_arrival"
		BoatState.DEPARTING:
			return "departing"
		BoatState.TRAVELING:
			return "traveling"
		BoatState.ARRIVING:
			return "arriving"
	return "unknown"


## Check if boat is currently traveling
func is_traveling() -> bool:
	return current_state == BoatState.TRAVELING


## Check if boat is docked (at either end)
func is_docked() -> bool:
	return current_state == BoatState.DOCKED


# ============================================
# Utility Functions
# ============================================

## Reset the boat to initial state
func reset() -> void:
	current_state = BoatState.DOCKED
	_is_at_departure = true
	_passengers.clear()
	_travel_timer = 0.0

	if departure_position != Vector2.ZERO:
		global_position = departure_position

	_target_position = global_position


## Get the boarding area (for collision detection)
func get_boarding_rect() -> Rect2:
	# Area where vehicles can board
	return Rect2(global_position - Vector2(40, 40), Vector2(80, 80))


## Check if a vehicle is in boarding range
func is_vehicle_in_boarding_range(vehicle: Vehicle) -> bool:
	var boarding_rect = get_boarding_rect()
	return boarding_rect.has_point(vehicle.global_position)
