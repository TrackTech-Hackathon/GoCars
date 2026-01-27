extends TileMapLayer
class_name RoadTileMapLayer

## TileMapLayer-based road system for GoCars
## Uses the new 8-column tileset with spawn groups A-D (144x144 per tile)
##
## Tile Layout (row/column):
## r0/c0=road no connection  r0/c1=road E        r0/c2=road EW       r0/c3=road W        r0/c4=spawn S A  r0/c5=spawn S B  r0/c6=spawn S C  r0/c7=spawn S D
## r1/c0=road S              r1/c1=road SE       r1/c2=road SEW      r1/c3=road SW       r1/c4=spawn N A  r1/c5=spawn N B  r1/c6=spawn N C  r1/c7=spawn N D
## r2/c0=road SN             r2/c1=road SNE      r2/c2=road SNEW     r2/c3=road SNW      r2/c4=dest S A   r2/c5=dest S B   r2/c6=dest S C   r2/c7=dest S D
## r3/c0=road N              r3/c1=road NE       r3/c2=road NEW      r3/c3=road NW       r3/c4=dest N A   r3/c5=dest N B   r3/c6=dest N C   r3/c7=dest N D
## r4/c0=spawn E A           r4/c1=spawn W A     r4/c2=spawn E B     r4/c3=spawn W B     r4/c4=spawn E C  r4/c5=spawn W C  r4/c6=spawn E D  r4/c7=spawn W D
## r5/c0=dest E A            r5/c1=dest W A      r5/c2=dest E B      r5/c3=dest W B      r5/c4=dest E C   r5/c5=dest W C   r5/c6=dest E D   r5/c7=dest W D
## r6/c0=stoplight SNEW      r6/c1=stoplight SNE r6/c2=stoplight NEW r6/c3=stoplight SEW r6/c4=stoplight SNW  (r6/c5-c7=None)

# Spawn groups for destination matching
enum SpawnGroup { A, B, C, D, NONE }

# Tile constants
const TILE_SIZE: float = 144.0
const HALF_TILE: float = 72.0
const LANE_OFFSET: float = 25.0

# Tile type enums for clarity
enum TileType {
	ROAD_NONE,           # No connections (isolated road)
	ROAD_E,              # East connection
	ROAD_EW,             # East-West
	ROAD_W,              # West connection
	SPAWN_PARKING_S_A,   # Spawn parking S Group A
	SPAWN_PARKING_S_B,   # Spawn parking S Group B
	SPAWN_PARKING_S_C,   # Spawn parking S Group C
	SPAWN_PARKING_S_D,   # Spawn parking S Group D
	ROAD_S,              # South connection
	ROAD_SE,             # South-East
	ROAD_SEW,            # South-East-West
	ROAD_SW,             # South-West
	SPAWN_PARKING_N_A,   # Spawn parking N Group A
	SPAWN_PARKING_N_B,   # Spawn parking N Group B
	SPAWN_PARKING_N_C,   # Spawn parking N Group C
	SPAWN_PARKING_N_D,   # Spawn parking N Group D
	ROAD_SN,             # South-North
	ROAD_SNE,            # South-North-East
	ROAD_SNEW,           # All four directions
	ROAD_SNW,            # South-North-West
	DEST_PARKING_S_A,    # Dest parking S Group A
	DEST_PARKING_S_B,    # Dest parking S Group B
	DEST_PARKING_S_C,    # Dest parking S Group C
	DEST_PARKING_S_D,    # Dest parking S Group D
	ROAD_N,              # North connection
	ROAD_NE,             # North-East
	ROAD_NEW,            # North-East-West
	ROAD_NW,             # North-West
	DEST_PARKING_N_A,    # Dest parking N Group A
	DEST_PARKING_N_B,    # Dest parking N Group B
	DEST_PARKING_N_C,    # Dest parking N Group C
	DEST_PARKING_N_D,    # Dest parking N Group D
	SPAWN_PARKING_E_A,   # Spawn parking E Group A
	SPAWN_PARKING_W_A,   # Spawn parking W Group A
	SPAWN_PARKING_E_B,   # Spawn parking E Group B
	SPAWN_PARKING_W_B,   # Spawn parking W Group B
	SPAWN_PARKING_E_C,   # Spawn parking E Group C
	SPAWN_PARKING_W_C,   # Spawn parking W Group C
	SPAWN_PARKING_E_D,   # Spawn parking E Group D
	SPAWN_PARKING_W_D,   # Spawn parking W Group D
	DEST_PARKING_E_A,    # Dest parking E Group A
	DEST_PARKING_W_A,    # Dest parking W Group A
	DEST_PARKING_E_B,    # Dest parking E Group B
	DEST_PARKING_W_B,    # Dest parking W Group B
	DEST_PARKING_E_C,    # Dest parking E Group C
	DEST_PARKING_W_C,    # Dest parking W Group C
	DEST_PARKING_E_D,    # Dest parking E Group D
	DEST_PARKING_W_D,    # Dest parking W Group D
	STOPLIGHT_SNEW,      # Stoplight all 4 directions
	STOPLIGHT_SNE,       # Stoplight S-N-E
	STOPLIGHT_NEW,       # Stoplight N-E-W
	STOPLIGHT_SEW,       # Stoplight S-E-W
	STOPLIGHT_SNW,       # Stoplight S-N-W
	NONE                 # Empty/no tile
}

# Mapping from tile atlas coords to TileType (8 columns x 7 rows)
const TILE_COORDS_TO_TYPE: Dictionary = {
	# Row 0: Basic roads and spawn parking S (groups A-D)
	Vector2i(0, 0): TileType.ROAD_NONE,
	Vector2i(1, 0): TileType.ROAD_E,
	Vector2i(2, 0): TileType.ROAD_EW,
	Vector2i(3, 0): TileType.ROAD_W,
	Vector2i(4, 0): TileType.SPAWN_PARKING_S_A,
	Vector2i(5, 0): TileType.SPAWN_PARKING_S_B,
	Vector2i(6, 0): TileType.SPAWN_PARKING_S_C,
	Vector2i(7, 0): TileType.SPAWN_PARKING_S_D,
	# Row 1: Roads with S and spawn parking N (groups A-D)
	Vector2i(0, 1): TileType.ROAD_S,
	Vector2i(1, 1): TileType.ROAD_SE,
	Vector2i(2, 1): TileType.ROAD_SEW,
	Vector2i(3, 1): TileType.ROAD_SW,
	Vector2i(4, 1): TileType.SPAWN_PARKING_N_A,
	Vector2i(5, 1): TileType.SPAWN_PARKING_N_B,
	Vector2i(6, 1): TileType.SPAWN_PARKING_N_C,
	Vector2i(7, 1): TileType.SPAWN_PARKING_N_D,
	# Row 2: Roads with SN and dest parking S (groups A-D)
	Vector2i(0, 2): TileType.ROAD_SN,
	Vector2i(1, 2): TileType.ROAD_SNE,
	Vector2i(2, 2): TileType.ROAD_SNEW,
	Vector2i(3, 2): TileType.ROAD_SNW,
	Vector2i(4, 2): TileType.DEST_PARKING_S_A,
	Vector2i(5, 2): TileType.DEST_PARKING_S_B,
	Vector2i(6, 2): TileType.DEST_PARKING_S_C,
	Vector2i(7, 2): TileType.DEST_PARKING_S_D,
	# Row 3: Roads with N and dest parking N (groups A-D)
	Vector2i(0, 3): TileType.ROAD_N,
	Vector2i(1, 3): TileType.ROAD_NE,
	Vector2i(2, 3): TileType.ROAD_NEW,
	Vector2i(3, 3): TileType.ROAD_NW,
	Vector2i(4, 3): TileType.DEST_PARKING_N_A,
	Vector2i(5, 3): TileType.DEST_PARKING_N_B,
	Vector2i(6, 3): TileType.DEST_PARKING_N_C,
	Vector2i(7, 3): TileType.DEST_PARKING_N_D,
	# Row 4: Spawn parking E/W (groups A-D)
	Vector2i(0, 4): TileType.SPAWN_PARKING_E_A,
	Vector2i(1, 4): TileType.SPAWN_PARKING_W_A,
	Vector2i(2, 4): TileType.SPAWN_PARKING_E_B,
	Vector2i(3, 4): TileType.SPAWN_PARKING_W_B,
	Vector2i(4, 4): TileType.SPAWN_PARKING_E_C,
	Vector2i(5, 4): TileType.SPAWN_PARKING_W_C,
	Vector2i(6, 4): TileType.SPAWN_PARKING_E_D,
	Vector2i(7, 4): TileType.SPAWN_PARKING_W_D,
	# Row 5: Dest parking E/W (groups A-D)
	Vector2i(0, 5): TileType.DEST_PARKING_E_A,
	Vector2i(1, 5): TileType.DEST_PARKING_W_A,
	Vector2i(2, 5): TileType.DEST_PARKING_E_B,
	Vector2i(3, 5): TileType.DEST_PARKING_W_B,
	Vector2i(4, 5): TileType.DEST_PARKING_E_C,
	Vector2i(5, 5): TileType.DEST_PARKING_W_C,
	Vector2i(6, 5): TileType.DEST_PARKING_E_D,
	Vector2i(7, 5): TileType.DEST_PARKING_W_D,
	# Row 6: Stoplight tiles
	Vector2i(0, 6): TileType.STOPLIGHT_SNEW,
	Vector2i(1, 6): TileType.STOPLIGHT_SNE,
	Vector2i(2, 6): TileType.STOPLIGHT_NEW,
	Vector2i(3, 6): TileType.STOPLIGHT_SEW,
	Vector2i(4, 6): TileType.STOPLIGHT_SNW,
	Vector2i(5, 6): TileType.NONE,
	Vector2i(6, 6): TileType.NONE,
	Vector2i(7, 6): TileType.NONE,
}

# Mapping from TileType to connections (directions the tile connects to)
const TILE_CONNECTIONS: Dictionary = {
	TileType.ROAD_NONE: [],
	TileType.ROAD_E: ["right"],
	TileType.ROAD_EW: ["left", "right"],
	TileType.ROAD_W: ["left"],
	TileType.SPAWN_PARKING_S_A: ["bottom"],
	TileType.SPAWN_PARKING_S_B: ["bottom"],
	TileType.SPAWN_PARKING_S_C: ["bottom"],
	TileType.SPAWN_PARKING_S_D: ["bottom"],
	TileType.ROAD_S: ["bottom"],
	TileType.ROAD_SE: ["bottom", "right"],
	TileType.ROAD_SEW: ["bottom", "left", "right"],
	TileType.ROAD_SW: ["bottom", "left"],
	TileType.SPAWN_PARKING_N_A: ["top"],
	TileType.SPAWN_PARKING_N_B: ["top"],
	TileType.SPAWN_PARKING_N_C: ["top"],
	TileType.SPAWN_PARKING_N_D: ["top"],
	TileType.ROAD_SN: ["top", "bottom"],
	TileType.ROAD_SNE: ["top", "bottom", "right"],
	TileType.ROAD_SNEW: ["top", "bottom", "left", "right"],
	TileType.ROAD_SNW: ["top", "bottom", "left"],
	TileType.DEST_PARKING_S_A: ["bottom"],
	TileType.DEST_PARKING_S_B: ["bottom"],
	TileType.DEST_PARKING_S_C: ["bottom"],
	TileType.DEST_PARKING_S_D: ["bottom"],
	TileType.ROAD_N: ["top"],
	TileType.ROAD_NE: ["top", "right"],
	TileType.ROAD_NEW: ["top", "left", "right"],
	TileType.ROAD_NW: ["top", "left"],
	TileType.DEST_PARKING_N_A: ["top"],
	TileType.DEST_PARKING_N_B: ["top"],
	TileType.DEST_PARKING_N_C: ["top"],
	TileType.DEST_PARKING_N_D: ["top"],
	TileType.SPAWN_PARKING_E_A: ["right"],
	TileType.SPAWN_PARKING_W_A: ["left"],
	TileType.SPAWN_PARKING_E_B: ["right"],
	TileType.SPAWN_PARKING_W_B: ["left"],
	TileType.SPAWN_PARKING_E_C: ["right"],
	TileType.SPAWN_PARKING_W_C: ["left"],
	TileType.SPAWN_PARKING_E_D: ["right"],
	TileType.SPAWN_PARKING_W_D: ["left"],
	TileType.DEST_PARKING_E_A: ["right"],
	TileType.DEST_PARKING_W_A: ["left"],
	TileType.DEST_PARKING_E_B: ["right"],
	TileType.DEST_PARKING_W_B: ["left"],
	TileType.DEST_PARKING_E_C: ["right"],
	TileType.DEST_PARKING_W_C: ["left"],
	TileType.DEST_PARKING_E_D: ["right"],
	TileType.DEST_PARKING_W_D: ["left"],
	TileType.STOPLIGHT_SNEW: ["top", "bottom", "left", "right"],
	TileType.STOPLIGHT_SNE: ["top", "bottom", "right"],
	TileType.STOPLIGHT_NEW: ["top", "left", "right"],
	TileType.STOPLIGHT_SEW: ["bottom", "left", "right"],
	TileType.STOPLIGHT_SNW: ["top", "bottom", "left"],
	TileType.NONE: []
}

# Mapping from TileType to SpawnGroup
const TILE_TO_GROUP: Dictionary = {
	# Spawn parking groups
	TileType.SPAWN_PARKING_S_A: SpawnGroup.A,
	TileType.SPAWN_PARKING_S_B: SpawnGroup.B,
	TileType.SPAWN_PARKING_S_C: SpawnGroup.C,
	TileType.SPAWN_PARKING_S_D: SpawnGroup.D,
	TileType.SPAWN_PARKING_N_A: SpawnGroup.A,
	TileType.SPAWN_PARKING_N_B: SpawnGroup.B,
	TileType.SPAWN_PARKING_N_C: SpawnGroup.C,
	TileType.SPAWN_PARKING_N_D: SpawnGroup.D,
	TileType.SPAWN_PARKING_E_A: SpawnGroup.A,
	TileType.SPAWN_PARKING_W_A: SpawnGroup.A,
	TileType.SPAWN_PARKING_E_B: SpawnGroup.B,
	TileType.SPAWN_PARKING_W_B: SpawnGroup.B,
	TileType.SPAWN_PARKING_E_C: SpawnGroup.C,
	TileType.SPAWN_PARKING_W_C: SpawnGroup.C,
	TileType.SPAWN_PARKING_E_D: SpawnGroup.D,
	TileType.SPAWN_PARKING_W_D: SpawnGroup.D,
	# Dest parking groups
	TileType.DEST_PARKING_S_A: SpawnGroup.A,
	TileType.DEST_PARKING_S_B: SpawnGroup.B,
	TileType.DEST_PARKING_S_C: SpawnGroup.C,
	TileType.DEST_PARKING_S_D: SpawnGroup.D,
	TileType.DEST_PARKING_N_A: SpawnGroup.A,
	TileType.DEST_PARKING_N_B: SpawnGroup.B,
	TileType.DEST_PARKING_N_C: SpawnGroup.C,
	TileType.DEST_PARKING_N_D: SpawnGroup.D,
	TileType.DEST_PARKING_E_A: SpawnGroup.A,
	TileType.DEST_PARKING_W_A: SpawnGroup.A,
	TileType.DEST_PARKING_E_B: SpawnGroup.B,
	TileType.DEST_PARKING_W_B: SpawnGroup.B,
	TileType.DEST_PARKING_E_C: SpawnGroup.C,
	TileType.DEST_PARKING_W_C: SpawnGroup.C,
	TileType.DEST_PARKING_E_D: SpawnGroup.D,
	TileType.DEST_PARKING_W_D: SpawnGroup.D,
}

# All spawn parking tile types
const SPAWN_PARKING_TILES: Array = [
	TileType.SPAWN_PARKING_S_A, TileType.SPAWN_PARKING_S_B, TileType.SPAWN_PARKING_S_C, TileType.SPAWN_PARKING_S_D,
	TileType.SPAWN_PARKING_N_A, TileType.SPAWN_PARKING_N_B, TileType.SPAWN_PARKING_N_C, TileType.SPAWN_PARKING_N_D,
	TileType.SPAWN_PARKING_E_A, TileType.SPAWN_PARKING_W_A, TileType.SPAWN_PARKING_E_B, TileType.SPAWN_PARKING_W_B,
	TileType.SPAWN_PARKING_E_C, TileType.SPAWN_PARKING_W_C, TileType.SPAWN_PARKING_E_D, TileType.SPAWN_PARKING_W_D
]

# All destination parking tile types
const DEST_PARKING_TILES: Array = [
	TileType.DEST_PARKING_S_A, TileType.DEST_PARKING_S_B, TileType.DEST_PARKING_S_C, TileType.DEST_PARKING_S_D,
	TileType.DEST_PARKING_N_A, TileType.DEST_PARKING_N_B, TileType.DEST_PARKING_N_C, TileType.DEST_PARKING_N_D,
	TileType.DEST_PARKING_E_A, TileType.DEST_PARKING_W_A, TileType.DEST_PARKING_E_B, TileType.DEST_PARKING_W_B,
	TileType.DEST_PARKING_E_C, TileType.DEST_PARKING_W_C, TileType.DEST_PARKING_E_D, TileType.DEST_PARKING_W_D
]

# All stoplight tile types
const STOPLIGHT_TILES: Array = [
	TileType.STOPLIGHT_SNEW, TileType.STOPLIGHT_SNE, TileType.STOPLIGHT_NEW,
	TileType.STOPLIGHT_SEW, TileType.STOPLIGHT_SNW
]

# Cached spawn and destination positions
var spawn_positions: Array[Vector2i] = []  # Grid positions of spawn parking tiles
var destination_positions: Array[Vector2i] = []  # Grid positions of destination parking tiles
var stoplight_positions: Array[Vector2i] = []  # Grid positions of stoplight tiles

# Path cache - recalculated when needed
var _paths_dirty: bool = true
var _cached_paths: Dictionary = {}  # Key: grid_pos, Value: Dictionary of entry->exit->path

# Signals
signal paths_updated
signal stoplight_tiles_found(positions: Array)


func _ready() -> void:
	_scan_for_parking_tiles()


## Scan the tilemap for spawn, destination, and stoplight tiles
func _scan_for_parking_tiles() -> void:
	spawn_positions.clear()
	destination_positions.clear()
	stoplight_positions.clear()

	var used_cells = get_used_cells()
	for cell_pos in used_cells:
		var tile_type = get_tile_type_at(cell_pos)

		# Check for spawn parking tiles (all groups)
		if tile_type in SPAWN_PARKING_TILES:
			spawn_positions.append(cell_pos)

		# Check for destination parking tiles (all groups)
		elif tile_type in DEST_PARKING_TILES:
			destination_positions.append(cell_pos)

		# Check for stoplight tiles
		elif tile_type in STOPLIGHT_TILES:
			stoplight_positions.append(cell_pos)

	print("Found %d spawn positions, %d destination positions, %d stoplights" % [spawn_positions.size(), destination_positions.size(), stoplight_positions.size()])

	# Emit signal so main scene can spawn stoplights
	if not stoplight_positions.is_empty():
		stoplight_tiles_found.emit(stoplight_positions)


## Get the spawn group for a tile type
func get_tile_group(tile_type: TileType) -> SpawnGroup:
	return TILE_TO_GROUP.get(tile_type, SpawnGroup.NONE)


## Get the spawn group at a grid position
func get_group_at(grid_pos: Vector2i) -> SpawnGroup:
	var tile_type = get_tile_type_at(grid_pos)
	return get_tile_group(tile_type)


## Get spawn group name as string
static func get_group_name(group: SpawnGroup) -> String:
	match group:
		SpawnGroup.A: return "A"
		SpawnGroup.B: return "B"
		SpawnGroup.C: return "C"
		SpawnGroup.D: return "D"
		_: return "None"


## Check if a tile is a stoplight tile
func is_stoplight_tile(grid_pos: Vector2i) -> bool:
	var tile_type = get_tile_type_at(grid_pos)
	return tile_type in STOPLIGHT_TILES


## Get the TileType at a grid position
func get_tile_type_at(grid_pos: Vector2i) -> TileType:
	var atlas_coords = get_cell_atlas_coords(grid_pos)
	if atlas_coords == Vector2i(-1, -1):
		return TileType.NONE
	return TILE_COORDS_TO_TYPE.get(atlas_coords, TileType.NONE)


## Get connections for a tile at grid position
func get_connections_at(grid_pos: Vector2i) -> Array:
	var tile_type = get_tile_type_at(grid_pos)
	return TILE_CONNECTIONS.get(tile_type, [])


## Check if there's a road at the given grid position
func has_road_at(grid_pos: Vector2i) -> bool:
	var tile_type = get_tile_type_at(grid_pos)
	return tile_type != TileType.NONE


## Check if tile at grid_pos has a connection in the given direction
func has_connection(grid_pos: Vector2i, direction: String) -> bool:
	var connections = get_connections_at(grid_pos)
	return direction in connections


## Check if there's a road at world position
func is_road_at_position(world_pos: Vector2) -> bool:
	var grid_pos = local_to_map(world_pos)
	return has_road_at(grid_pos)


## Get available exit directions when entering from a given direction
func get_available_exits(grid_pos: Vector2i, entry_dir: String) -> Array:
	var connections = get_connections_at(grid_pos)
	var exits: Array = []

	for dir in connections:
		if dir != entry_dir:  # Can't exit where you entered
			exits.append(dir)

	return exits


## Get spawn positions with their spawn direction
## Returns array of dictionaries: {position: Vector2, direction: Vector2, rotation: float, entry_dir: String, group: SpawnGroup}
## Lane offset follows right-hand traffic (cars drive on RIGHT side of road)
func get_spawn_data() -> Array:
	var spawn_data: Array = []

	for spawn_pos in spawn_positions:
		var tile_type = get_tile_type_at(spawn_pos)
		var world_pos = map_to_local(spawn_pos)
		var data = {}

		# Get spawn group
		data["group"] = get_tile_group(tile_type)
		data["group_name"] = get_group_name(data["group"])

		# Lane positions (relative to tile center):
		# - Going East: bottom-left = (-LANE_OFFSET, +LANE_OFFSET)
		# - Going West: top-right = (+LANE_OFFSET, -LANE_OFFSET)
		# - Going South: top-left = (-LANE_OFFSET, -LANE_OFFSET)
		# - Going North: bottom-right = (+LANE_OFFSET, +LANE_OFFSET)

		# Check direction based on tile type (handle all groups)
		if tile_type in [TileType.SPAWN_PARKING_S_A, TileType.SPAWN_PARKING_S_B, TileType.SPAWN_PARKING_S_C, TileType.SPAWN_PARKING_S_D]:
			# Car exits through SOUTH (bottom), faces DOWN → top-left
			data["position"] = world_pos + Vector2(-LANE_OFFSET, -LANE_OFFSET)
			data["direction"] = Vector2.DOWN
			data["rotation"] = PI
			data["entry_dir"] = "top"
		elif tile_type in [TileType.SPAWN_PARKING_N_A, TileType.SPAWN_PARKING_N_B, TileType.SPAWN_PARKING_N_C, TileType.SPAWN_PARKING_N_D]:
			# Car exits through NORTH (top), faces UP → bottom-right
			data["position"] = world_pos + Vector2(LANE_OFFSET, LANE_OFFSET)
			data["direction"] = Vector2.UP
			data["rotation"] = 0.0
			data["entry_dir"] = "bottom"
		elif tile_type in [TileType.SPAWN_PARKING_E_A, TileType.SPAWN_PARKING_E_B, TileType.SPAWN_PARKING_E_C, TileType.SPAWN_PARKING_E_D]:
			# Car exits through EAST (right), faces RIGHT → bottom-left
			data["position"] = world_pos + Vector2(-LANE_OFFSET, LANE_OFFSET)
			data["direction"] = Vector2.RIGHT
			data["rotation"] = PI / 2
			data["entry_dir"] = "left"
		elif tile_type in [TileType.SPAWN_PARKING_W_A, TileType.SPAWN_PARKING_W_B, TileType.SPAWN_PARKING_W_C, TileType.SPAWN_PARKING_W_D]:
			# Car exits through WEST (left), faces LEFT → top-right
			data["position"] = world_pos + Vector2(LANE_OFFSET, -LANE_OFFSET)
			data["direction"] = Vector2.LEFT
			data["rotation"] = -PI / 2
			data["entry_dir"] = "right"

		data["grid_pos"] = spawn_pos
		spawn_data.append(data)

	return spawn_data


## Get destination positions with their entry direction
## Returns array of dictionaries: {position: Vector2, entry_dir: String, grid_pos: Vector2i, group: SpawnGroup}
## Lane offset follows right-hand traffic (cars drive on RIGHT side of road)
func get_destination_data() -> Array:
	var dest_data: Array = []

	for dest_pos in destination_positions:
		var tile_type = get_tile_type_at(dest_pos)
		var world_pos = map_to_local(dest_pos)
		var data = {}

		# Get destination group
		data["group"] = get_tile_group(tile_type)
		data["group_name"] = get_group_name(data["group"])

		# Parking positions (at tile center with lane offset):
		# - Going East and parking: center-bottom = (0, +LANE_OFFSET)
		# - Going West and parking: center-top = (0, -LANE_OFFSET)
		# - Going South and parking: center-left = (-LANE_OFFSET, 0)
		# - Going North and parking: center-right = (+LANE_OFFSET, 0)

		# Check direction based on tile type (handle all groups)
		if tile_type in [TileType.DEST_PARKING_S_A, TileType.DEST_PARKING_S_B, TileType.DEST_PARKING_S_C, TileType.DEST_PARKING_S_D]:
			# Car enters through SOUTH connection (traveling North into parking) → center-right
			data["position"] = world_pos + Vector2(LANE_OFFSET, 0)
			data["entry_dir"] = "bottom"
		elif tile_type in [TileType.DEST_PARKING_N_A, TileType.DEST_PARKING_N_B, TileType.DEST_PARKING_N_C, TileType.DEST_PARKING_N_D]:
			# Car enters through NORTH connection (traveling South into parking) → center-left
			data["position"] = world_pos + Vector2(-LANE_OFFSET, 0)
			data["entry_dir"] = "top"
		elif tile_type in [TileType.DEST_PARKING_E_A, TileType.DEST_PARKING_E_B, TileType.DEST_PARKING_E_C, TileType.DEST_PARKING_E_D]:
			# Car enters through EAST connection (traveling West into parking) → center-top
			data["position"] = world_pos + Vector2(0, -LANE_OFFSET)
			data["entry_dir"] = "right"
		elif tile_type in [TileType.DEST_PARKING_W_A, TileType.DEST_PARKING_W_B, TileType.DEST_PARKING_W_C, TileType.DEST_PARKING_W_D]:
			# Car enters through WEST connection (traveling East into parking) → center-bottom
			data["position"] = world_pos + Vector2(0, LANE_OFFSET)
			data["entry_dir"] = "left"

		data["grid_pos"] = dest_pos
		dest_data.append(data)

	return dest_data


## Get stoplight positions with their world coordinates
## Returns array of dictionaries: {position: Vector2, grid_pos: Vector2i}
func get_stoplight_data() -> Array:
	var stoplight_data: Array = []

	for stoplight_pos in stoplight_positions:
		var world_pos = map_to_local(stoplight_pos)
		var data = {
			"position": world_pos,
			"grid_pos": stoplight_pos
		}
		stoplight_data.append(data)

	return stoplight_data


## Get the guideline path for traversing a tile from entry to exit
## Returns array of world positions (waypoints)
func get_guideline_path(grid_pos: Vector2i, entry_dir: String, exit_dir: String) -> Array:
	# Check if we have this path cached
	var cache_key = "%s_%s_%s" % [grid_pos, entry_dir, exit_dir]
	if _cached_paths.has(cache_key):
		return _cached_paths[cache_key]

	# Calculate the path
	var path = _calculate_path_waypoints(grid_pos, entry_dir, exit_dir)
	_cached_paths[cache_key] = path
	return path


## Calculate waypoint path from entry to exit direction
## Waypoints are in world coordinates
func _calculate_path_waypoints(grid_pos: Vector2i, entry_dir: String, exit_dir: String) -> Array:
	var points: Array = []
	var tile_center = Vector2(map_to_local(grid_pos))

	# Check if this is a straight path or a turn
	var is_straight = _get_axis(entry_dir) == _get_axis(exit_dir)

	if is_straight:
		# Straight path - both points have SAME lane offset
		var lane_offset = _get_straight_lane_offset(entry_dir, exit_dir)
		var entry_point = _get_edge_center(entry_dir, tile_center) + lane_offset
		var exit_point = _get_edge_center(exit_dir, tile_center) + lane_offset
		points.append(entry_point)
		points.append(exit_point)
	else:
		# Turn - need different lane offsets and a corner point
		var entry_point = _get_turn_edge_point(entry_dir, exit_dir, tile_center, true)
		var corner = _get_corner_point(entry_dir, exit_dir, tile_center)
		var exit_point = _get_turn_edge_point(entry_dir, exit_dir, tile_center, false)
		points.append(entry_point)
		points.append(corner)
		points.append(exit_point)

	return points


## Get the center of an edge (no lane offset)
func _get_edge_center(dir: String, tile_center: Vector2) -> Vector2:
	match dir:
		"top": return tile_center + Vector2(0, -HALF_TILE)
		"bottom": return tile_center + Vector2(0, HALF_TILE)
		"left": return tile_center + Vector2(-HALF_TILE, 0)
		"right": return tile_center + Vector2(HALF_TILE, 0)
	return tile_center


## Get lane offset for straight paths based on travel direction
## Lane positions (relative to tile center):
## - Going East (left_right): bottom-left = (-LANE_OFFSET, +LANE_OFFSET)
## - Going West (right_left): top-right = (+LANE_OFFSET, -LANE_OFFSET)
## - Going South (top_bottom): top-left = (-LANE_OFFSET, -LANE_OFFSET)
## - Going North (bottom_top): bottom-right = (+LANE_OFFSET, +LANE_OFFSET)
func _get_straight_lane_offset(entry_dir: String, exit_dir: String) -> Vector2:
	match entry_dir + "_" + exit_dir:
		"left_right":  # Going East → bottom-left
			return Vector2(-LANE_OFFSET, LANE_OFFSET)
		"right_left":  # Going West → top-right
			return Vector2(LANE_OFFSET, -LANE_OFFSET)
		"top_bottom":  # Going South → top-left
			return Vector2(-LANE_OFFSET, -LANE_OFFSET)
		"bottom_top":  # Going North → bottom-right
			return Vector2(LANE_OFFSET, LANE_OFFSET)
	return Vector2.ZERO


## Get edge point for turns (entry or exit)
func _get_turn_edge_point(entry_dir: String, exit_dir: String, tile_center: Vector2, is_entry: bool) -> Vector2:
	var edge = entry_dir if is_entry else exit_dir
	var edge_center = _get_edge_center(edge, tile_center)

	if is_entry:
		var offset = _get_entry_lane_offset(entry_dir)
		return edge_center + offset
	else:
		var offset = _get_exit_lane_offset(exit_dir)
		return edge_center + offset


## Get corner waypoint for turns
func _get_corner_point(entry_dir: String, exit_dir: String, tile_center: Vector2) -> Vector2:
	var entry_offset = _get_entry_lane_offset(entry_dir)
	var exit_offset = _get_exit_lane_offset(exit_dir)

	match entry_dir + "_" + exit_dir:
		# Entering horizontally, exiting vertically
		"left_top", "left_bottom", "right_top", "right_bottom":
			return tile_center + Vector2(exit_offset.x, entry_offset.y)
		# Entering vertically, exiting horizontally
		"top_left", "top_right", "bottom_left", "bottom_right":
			return tile_center + Vector2(entry_offset.x, exit_offset.y)

	return tile_center


## Get lane offset for entry direction
## Entry direction is where the car is coming FROM (opposite of travel direction)
## Lane positions (relative to tile center):
## - Entry "left" = Going East → bottom-left = (-LANE_OFFSET, +LANE_OFFSET)
## - Entry "right" = Going West → top-right = (+LANE_OFFSET, -LANE_OFFSET)
## - Entry "top" = Going South → top-left = (-LANE_OFFSET, -LANE_OFFSET)
## - Entry "bottom" = Going North → bottom-right = (+LANE_OFFSET, +LANE_OFFSET)
func _get_entry_lane_offset(entry_dir: String) -> Vector2:
	match entry_dir:
		"left":   return Vector2(-LANE_OFFSET, LANE_OFFSET)   # Going East → bottom-left
		"right":  return Vector2(LANE_OFFSET, -LANE_OFFSET)   # Going West → top-right
		"top":    return Vector2(-LANE_OFFSET, -LANE_OFFSET)  # Going South → top-left
		"bottom": return Vector2(LANE_OFFSET, LANE_OFFSET)    # Going North → bottom-right
	return Vector2.ZERO


## Get lane offset for exit direction
## Exit direction is where the car is going TO
## Lane positions (relative to tile center):
## - Exit "left" = Going West → top-right = (+LANE_OFFSET, -LANE_OFFSET)
## - Exit "right" = Going East → bottom-left = (-LANE_OFFSET, +LANE_OFFSET)
## - Exit "top" = Going North → bottom-right = (+LANE_OFFSET, +LANE_OFFSET)
## - Exit "bottom" = Going South → top-left = (-LANE_OFFSET, -LANE_OFFSET)
func _get_exit_lane_offset(exit_dir: String) -> Vector2:
	match exit_dir:
		"left":   return Vector2(LANE_OFFSET, -LANE_OFFSET)   # Going West → top-right
		"right":  return Vector2(-LANE_OFFSET, LANE_OFFSET)   # Going East → bottom-left
		"top":    return Vector2(LANE_OFFSET, LANE_OFFSET)    # Going North → bottom-right
		"bottom": return Vector2(-LANE_OFFSET, -LANE_OFFSET)  # Going South → top-left
	return Vector2.ZERO


## Get axis for a direction (0 = horizontal, 1 = vertical)
func _get_axis(dir: String) -> int:
	match dir:
		"left", "right": return 0
		"top", "bottom": return 1
	return -1


## Mark paths as dirty (clear cache)
func mark_paths_dirty() -> void:
	_paths_dirty = true
	_cached_paths.clear()


## Get opposite direction
static func get_opposite_direction(direction: String) -> String:
	match direction:
		"top": return "bottom"
		"bottom": return "top"
		"left": return "right"
		"right": return "left"
	return ""


## Get the direction to the left of the given entry direction
static func get_left_of(entry: String) -> String:
	match entry:
		"right": return "bottom"
		"left": return "top"
		"top": return "right"
		"bottom": return "left"
	return ""


## Get the direction to the right of the given entry direction
static func get_right_of(entry: String) -> String:
	match entry:
		"right": return "top"
		"left": return "bottom"
		"top": return "left"
		"bottom": return "right"
	return ""


## Check if the tile at grid_pos is a spawn parking tile
func is_spawn_tile(grid_pos: Vector2i) -> bool:
	var tile_type = get_tile_type_at(grid_pos)
	return tile_type in SPAWN_PARKING_TILES


## Check if the tile at grid_pos is a destination parking tile
func is_destination_tile(grid_pos: Vector2i) -> bool:
	var tile_type = get_tile_type_at(grid_pos)
	return tile_type in DEST_PARKING_TILES


## Get grid position from world position
func get_grid_pos_from_world(world_pos: Vector2) -> Vector2i:
	return local_to_map(world_pos)


## Get world position (center) from grid position
func get_world_pos_from_grid(grid_pos: Vector2i) -> Vector2:
	return map_to_local(grid_pos)


## Rescan parking tiles (call after modifying the tilemap)
func refresh_parking_tiles() -> void:
	_scan_for_parking_tiles()
	mark_paths_dirty()
