extends TileMapLayer
class_name RoadTileMapLayer

## TileMapLayer-based road system for GoCars
## Uses the new 18-column x 12-row tileset with spawn groups A-D (144x144 per tile)
##
## Tile Types:
## - road: Basic roads with road connections
## - parking road: Single parking with road connections
## - multi parking road: Parking with road + parking road connections
##
## Connection Types:
## - road connection: Connects to roads and parking roads
## - parking road connection: Connects to multi parking roads only

# Spawn groups for destination matching
enum SpawnGroup { A, B, C, D, NONE }

# Tile type categories
enum TileCategory { ROAD, PARKING_ROAD, MULTI_PARKING_ROAD, NONE }

# Tile constants
const TILE_SIZE: float = 144.0
const HALF_TILE: float = 72.0
const LANE_OFFSET: float = 25.0

# Tile type enums - organized by row
enum TileType {
	# Row 0: Basic roads (c0-c3), Spawn road west (c4-c7), Road with parking connections (c8-c11)
	ROAD_NONE,                    # r0/c0
	ROAD_E,                       # r0/c1
	ROAD_EW,                      # r0/c2
	ROAD_W,                       # r0/c3
	SPAWN_ROAD_W_A,               # r0/c4
	SPAWN_ROAD_W_B,               # r0/c5
	SPAWN_ROAD_W_C,               # r0/c6
	SPAWN_ROAD_W_D,               # r0/c7
	ROAD_SE_PW,                   # r0/c8 - road SE + parking W
	ROAD_SW_PE,                   # r0/c9 - road SW + parking E
	ROAD_SE_PNW,                  # r0/c10 - road SE + parking NW
	ROAD_SW_PNE,                  # r0/c11 - road SW + parking NE
	ROAD_SNEW_12,                 # r0/c12 - 4-way road
	ROAD_SNEW_13,                 # r0/c13 - 4-way road
	ROAD_SNEW_14,                 # r0/c14 - 4-way road
	STOPLIGHT_SNEW,               # r0/c15 - stoplight 4-way
	STOPLIGHT_SEW,                # r0/c16 - stoplight SEW

	# Row 1: Roads with S (c0-c3), Spawn road east (c4-c7), Road with parking connections (c8-c11)
	ROAD_S,                       # r1/c0
	ROAD_SE,                      # r1/c1
	ROAD_SEW,                     # r1/c2
	ROAD_SW,                      # r1/c3
	SPAWN_ROAD_E_A,               # r1/c4
	SPAWN_ROAD_E_B,               # r1/c5
	SPAWN_ROAD_E_C,               # r1/c6
	SPAWN_ROAD_E_D,               # r1/c7
	ROAD_SN_PW,                   # r1/c8 - road SN + parking W
	ROAD_SN_PE,                   # r1/c9 - road SN + parking E
	ROAD_NE_PSW,                  # r1/c10 - road NE + parking SW
	ROAD_NW_PSE,                  # r1/c11 - road NW + parking SE
	ROAD_SNEW_1_12,               # r1/c12 - 4-way road
	ROAD_SNEW_1_13,               # r1/c13 - 4-way road
	STOPLIGHT_SNE,                # r1/c14 - stoplight SNE
	STOPLIGHT_NEW,                # r1/c15 - stoplight NEW
	STOPLIGHT_SNW,                # r1/c16 - stoplight SNW

	# Row 2: Roads with SN (c0-c3), Road with parking N (c4-c7), Road with parking (c8-c9), Parking roads (c10-c13)
	ROAD_SN,                      # r2/c0
	ROAD_SNE,                     # r2/c1
	ROAD_SNEW,                    # r2/c2
	ROAD_SNW,                     # r2/c3
	ROAD_SE_PN,                   # r2/c4 - road SE + parking N
	ROAD_EW_PN,                   # r2/c5 - road EW + parking N
	ROAD_SEW_PN,                  # r2/c6 - road SEW + parking N
	ROAD_SW_PN,                   # r2/c7 - road SW + parking N
	ROAD_SNE_PW,                  # r2/c8 - road SNE + parking W
	ROAD_SNW_PE,                  # r2/c9 - road SNW + parking E
	PARKING_S,                    # r2/c10 - parking road, road connection south
	MULTI_PARKING_S_PE,           # r2/c11 - multi parking, road S, parking E
	MULTI_PARKING_S_PEW,          # r2/c12 - multi parking, road S, parking EW
	MULTI_PARKING_S_PW,           # r2/c13 - multi parking, road S, parking W

	# Row 3: Roads with N (c0-c3), Road with parking S (c4-c7), Road with parking (c8-c9), Parking roads (c10-c13)
	ROAD_N,                       # r3/c0
	ROAD_NE,                      # r3/c1
	ROAD_NEW,                     # r3/c2
	ROAD_NW,                      # r3/c3
	ROAD_NE_PS,                   # r3/c4 - road NE + parking S
	ROAD_EW_PS,                   # r3/c5 - road EW + parking S
	ROAD_NEW_PS,                  # r3/c6 - road NEW + parking S
	ROAD_NW_PS,                   # r3/c7 - road NW + parking S
	ROAD_NE_PW,                   # r3/c8 - road NE + parking W
	ROAD_NW_PE,                   # r3/c9 - road NW + parking E
	PARKING_N,                    # r3/c10 - parking road, road connection north
	MULTI_PARKING_N_PE,           # r3/c11 - multi parking, road N, parking E
	MULTI_PARKING_N_PEW,          # r3/c12 - multi parking, road N, parking EW
	MULTI_PARKING_N_PW,           # r3/c13 - multi parking, road N, parking W

	# Row 4: Spawn roads SN (c0-c1), Spawn parking N groups A-D (c2-c17)
	SPAWN_ROAD_S_A,               # r4/c0
	SPAWN_ROAD_N_A,               # r4/c1
	SPAWN_PARKING_N_A,            # r4/c2
	SPAWN_MULTI_PARKING_N_A_PE,   # r4/c3
	SPAWN_MULTI_PARKING_N_A_PEW,  # r4/c4
	SPAWN_MULTI_PARKING_N_A_PW,   # r4/c5
	SPAWN_PARKING_N_B,            # r4/c6
	SPAWN_MULTI_PARKING_N_B_PE,   # r4/c7
	SPAWN_MULTI_PARKING_N_B_PEW,  # r4/c8
	SPAWN_MULTI_PARKING_N_B_PW,   # r4/c9
	SPAWN_PARKING_N_C,            # r4/c10
	SPAWN_MULTI_PARKING_N_C_PE,   # r4/c11
	SPAWN_MULTI_PARKING_N_C_PEW,  # r4/c12
	SPAWN_MULTI_PARKING_N_C_PW,   # r4/c13
	SPAWN_PARKING_N_D,            # r4/c14
	SPAWN_MULTI_PARKING_N_D_PE,   # r4/c15
	SPAWN_MULTI_PARKING_N_D_PEW,  # r4/c16
	SPAWN_MULTI_PARKING_N_D_PW,   # r4/c17

	# Row 5: Spawn roads SN (c0-c1), Spawn parking S groups A-D (c2-c17)
	SPAWN_ROAD_S_B,               # r5/c0
	SPAWN_ROAD_N_B,               # r5/c1
	SPAWN_PARKING_S_A,            # r5/c2
	SPAWN_MULTI_PARKING_S_A_PE,   # r5/c3
	SPAWN_MULTI_PARKING_S_A_PEW,  # r5/c4
	SPAWN_MULTI_PARKING_S_A_PW,   # r5/c5
	SPAWN_PARKING_S_B,            # r5/c6
	SPAWN_MULTI_PARKING_S_B_PE,   # r5/c7
	SPAWN_MULTI_PARKING_S_B_PEW,  # r5/c8
	SPAWN_MULTI_PARKING_S_B_PW,   # r5/c9
	SPAWN_PARKING_S_C,            # r5/c10
	SPAWN_MULTI_PARKING_S_C_PE,   # r5/c11
	SPAWN_MULTI_PARKING_S_C_PEW,  # r5/c12
	SPAWN_MULTI_PARKING_S_C_PW,   # r5/c13
	SPAWN_PARKING_S_D,            # r5/c14
	SPAWN_MULTI_PARKING_S_D_PE,   # r5/c15
	SPAWN_MULTI_PARKING_S_D_PEW,  # r5/c16
	SPAWN_MULTI_PARKING_S_D_PW,   # r5/c17

	# Row 6: Spawn roads SN (c0-c1), Dest parking N groups A-D (c2-c17)
	SPAWN_ROAD_S_C,               # r6/c0
	SPAWN_ROAD_N_C,               # r6/c1
	DEST_PARKING_N_A,             # r6/c2
	DEST_MULTI_PARKING_N_A_PE,    # r6/c3
	DEST_MULTI_PARKING_N_A_PEW,   # r6/c4
	DEST_MULTI_PARKING_N_A_PW,    # r6/c5
	DEST_PARKING_N_B,             # r6/c6
	DEST_MULTI_PARKING_N_B_PE,    # r6/c7
	DEST_MULTI_PARKING_N_B_PEW,   # r6/c8
	DEST_MULTI_PARKING_N_B_PW,    # r6/c9
	DEST_PARKING_N_C,             # r6/c10
	DEST_MULTI_PARKING_N_C_PE,    # r6/c11
	DEST_MULTI_PARKING_N_C_PEW,   # r6/c12
	DEST_MULTI_PARKING_N_C_PW,    # r6/c13
	DEST_PARKING_N_D,             # r6/c14
	DEST_MULTI_PARKING_N_D_PE,    # r6/c15
	DEST_MULTI_PARKING_N_D_PEW,   # r6/c16
	DEST_MULTI_PARKING_N_D_PW,    # r6/c17

	# Row 7: Spawn roads SN (c0-c1), Dest parking S groups A-D (c2-c17)
	SPAWN_ROAD_S_D,               # r7/c0
	SPAWN_ROAD_N_D,               # r7/c1
	DEST_PARKING_S_A,             # r7/c2
	DEST_MULTI_PARKING_S_A_PE,    # r7/c3
	DEST_MULTI_PARKING_S_A_PEW,   # r7/c4
	DEST_MULTI_PARKING_S_A_PW,    # r7/c5
	DEST_PARKING_S_B,             # r7/c6
	DEST_MULTI_PARKING_S_B_PE,    # r7/c7
	DEST_MULTI_PARKING_S_B_PEW,   # r7/c8
	DEST_MULTI_PARKING_S_B_PW,    # r7/c9
	DEST_PARKING_S_C,             # r7/c10
	DEST_MULTI_PARKING_S_C_PE,    # r7/c11
	DEST_MULTI_PARKING_S_C_PEW,   # r7/c12
	DEST_MULTI_PARKING_S_C_PW,    # r7/c13
	DEST_PARKING_S_D,             # r7/c14
	DEST_MULTI_PARKING_S_D_PE,    # r7/c15
	DEST_MULTI_PARKING_S_D_PEW,   # r7/c16
	DEST_MULTI_PARKING_S_D_PW,    # r7/c17

	# Row 8: Parking roads E/W (c0-c1), Spawn parking E/W groups A-D (c2-c9), Dest parking E/W groups A-D (c10-c17)
	PARKING_E,                    # r8/c0
	PARKING_W,                    # r8/c1
	SPAWN_PARKING_E_A,            # r8/c2
	SPAWN_PARKING_W_A,            # r8/c3
	SPAWN_PARKING_E_B,            # r8/c4
	SPAWN_PARKING_W_B,            # r8/c5
	SPAWN_PARKING_E_C,            # r8/c6
	SPAWN_PARKING_W_C,            # r8/c7
	SPAWN_PARKING_E_D,            # r8/c8
	SPAWN_PARKING_W_D,            # r8/c9
	DEST_PARKING_E_A,             # r8/c10
	DEST_PARKING_W_A,             # r8/c11
	DEST_PARKING_E_B,             # r8/c12
	DEST_PARKING_W_B,             # r8/c13
	DEST_PARKING_E_C,             # r8/c14
	DEST_PARKING_W_C,             # r8/c15
	DEST_PARKING_E_D,             # r8/c16
	DEST_PARKING_W_D,             # r8/c17

	# Row 9: Multi parking E/W with PS (c0-c1), Spawn multi E/W PS groups A-D (c2-c9), Dest multi E/W PS groups A-D (c10-c17)
	MULTI_PARKING_E_PS,           # r9/c0
	MULTI_PARKING_W_PS,           # r9/c1
	SPAWN_MULTI_PARKING_E_A_PS,   # r9/c2
	SPAWN_MULTI_PARKING_W_A_PS,   # r9/c3
	SPAWN_MULTI_PARKING_E_B_PS,   # r9/c4
	SPAWN_MULTI_PARKING_W_B_PS,   # r9/c5
	SPAWN_MULTI_PARKING_E_C_PS,   # r9/c6
	SPAWN_MULTI_PARKING_W_C_PS,   # r9/c7
	SPAWN_MULTI_PARKING_E_D_PS,   # r9/c8
	SPAWN_MULTI_PARKING_W_D_PS,   # r9/c9
	DEST_MULTI_PARKING_E_A_PS,    # r9/c10
	DEST_MULTI_PARKING_W_A_PS,    # r9/c11
	DEST_MULTI_PARKING_E_B_PS,    # r9/c12
	DEST_MULTI_PARKING_W_B_PS,    # r9/c13
	DEST_MULTI_PARKING_E_C_PS,    # r9/c14
	DEST_MULTI_PARKING_W_C_PS,    # r9/c15
	DEST_MULTI_PARKING_E_D_PS,    # r9/c16
	DEST_MULTI_PARKING_W_D_PS,    # r9/c17

	# Row 10: Multi parking E/W with PSN (c0-c1), Spawn multi E/W PSN groups A-D (c2-c9), Dest multi E/W PSN groups A-D (c10-c17)
	MULTI_PARKING_E_PSN,          # r10/c0
	MULTI_PARKING_W_PSN,          # r10/c1
	SPAWN_MULTI_PARKING_E_A_PSN,  # r10/c2
	SPAWN_MULTI_PARKING_W_A_PSN,  # r10/c3
	SPAWN_MULTI_PARKING_E_B_PSN,  # r10/c4
	SPAWN_MULTI_PARKING_W_B_PSN,  # r10/c5
	SPAWN_MULTI_PARKING_E_C_PSN,  # r10/c6
	SPAWN_MULTI_PARKING_W_C_PSN,  # r10/c7
	SPAWN_MULTI_PARKING_E_D_PSN,  # r10/c8
	SPAWN_MULTI_PARKING_W_D_PSN,  # r10/c9
	DEST_MULTI_PARKING_E_A_PSN,   # r10/c10
	DEST_MULTI_PARKING_W_A_PSN,   # r10/c11
	DEST_MULTI_PARKING_E_B_PSN,   # r10/c12
	DEST_MULTI_PARKING_W_B_PSN,   # r10/c13
	DEST_MULTI_PARKING_E_C_PSN,   # r10/c14
	DEST_MULTI_PARKING_W_C_PSN,   # r10/c15
	DEST_MULTI_PARKING_E_D_PSN,   # r10/c16
	DEST_MULTI_PARKING_W_D_PSN,   # r10/c17

	# Row 11: Multi parking E/W with PN (c0-c1), Spawn multi E/W PN groups A-D (c2-c9), Dest multi E/W PN groups A-D (c10-c17)
	MULTI_PARKING_E_PN,           # r11/c0
	MULTI_PARKING_W_PN,           # r11/c1
	SPAWN_MULTI_PARKING_E_A_PN,   # r11/c2
	SPAWN_MULTI_PARKING_W_A_PN,   # r11/c3
	SPAWN_MULTI_PARKING_E_B_PN,   # r11/c4
	SPAWN_MULTI_PARKING_W_B_PN,   # r11/c5
	SPAWN_MULTI_PARKING_E_C_PN,   # r11/c6
	SPAWN_MULTI_PARKING_W_C_PN,   # r11/c7
	SPAWN_MULTI_PARKING_E_D_PN,   # r11/c8
	SPAWN_MULTI_PARKING_W_D_PN,   # r11/c9
	DEST_MULTI_PARKING_E_A_PN,    # r11/c10
	DEST_MULTI_PARKING_W_A_PN,    # r11/c11
	DEST_MULTI_PARKING_E_B_PN,    # r11/c12
	DEST_MULTI_PARKING_W_B_PN,    # r11/c13
	DEST_MULTI_PARKING_E_C_PN,    # r11/c14
	DEST_MULTI_PARKING_W_C_PN,    # r11/c15
	DEST_MULTI_PARKING_E_D_PN,    # r11/c16
	DEST_MULTI_PARKING_W_D_PN,    # r11/c17

	NONE                          # Empty/no tile
}

# Cached spawn and destination positions
var spawn_positions: Array[Vector2i] = []
var destination_positions: Array[Vector2i] = []
var stoplight_positions: Array[Vector2i] = []

# Path cache
var _paths_dirty: bool = true
var _cached_paths: Dictionary = {}

# Signals
signal paths_updated
signal stoplight_tiles_found(positions: Array)


# Mapping from tile atlas coords to TileType (18 columns x 12 rows)
const TILE_COORDS_TO_TYPE: Dictionary = {
	# Row 0
	Vector2i(0, 0): TileType.ROAD_NONE, Vector2i(1, 0): TileType.ROAD_E,
	Vector2i(2, 0): TileType.ROAD_EW, Vector2i(3, 0): TileType.ROAD_W,
	Vector2i(4, 0): TileType.SPAWN_ROAD_W_A, Vector2i(5, 0): TileType.SPAWN_ROAD_W_B,
	Vector2i(6, 0): TileType.SPAWN_ROAD_W_C, Vector2i(7, 0): TileType.SPAWN_ROAD_W_D,
	Vector2i(8, 0): TileType.ROAD_SE_PW, Vector2i(9, 0): TileType.ROAD_SW_PE,
	Vector2i(10, 0): TileType.ROAD_SE_PNW, Vector2i(11, 0): TileType.ROAD_SW_PNE,
	Vector2i(12, 0): TileType.ROAD_SNEW_12, Vector2i(13, 0): TileType.ROAD_SNEW_13,
	Vector2i(14, 0): TileType.ROAD_SNEW_14, Vector2i(15, 0): TileType.STOPLIGHT_SNEW,
	Vector2i(16, 0): TileType.STOPLIGHT_SEW,
	# Row 1
	Vector2i(0, 1): TileType.ROAD_S, Vector2i(1, 1): TileType.ROAD_SE,
	Vector2i(2, 1): TileType.ROAD_SEW, Vector2i(3, 1): TileType.ROAD_SW,
	Vector2i(4, 1): TileType.SPAWN_ROAD_E_A, Vector2i(5, 1): TileType.SPAWN_ROAD_E_B,
	Vector2i(6, 1): TileType.SPAWN_ROAD_E_C, Vector2i(7, 1): TileType.SPAWN_ROAD_E_D,
	Vector2i(8, 1): TileType.ROAD_SN_PW, Vector2i(9, 1): TileType.ROAD_SN_PE,
	Vector2i(10, 1): TileType.ROAD_NE_PSW, Vector2i(11, 1): TileType.ROAD_NW_PSE,
	Vector2i(12, 1): TileType.ROAD_SNEW_1_12, Vector2i(13, 1): TileType.ROAD_SNEW_1_13,
	Vector2i(14, 1): TileType.STOPLIGHT_SNE, Vector2i(15, 1): TileType.STOPLIGHT_NEW,
	Vector2i(16, 1): TileType.STOPLIGHT_SNW,
	# Row 2
	Vector2i(0, 2): TileType.ROAD_SN, Vector2i(1, 2): TileType.ROAD_SNE,
	Vector2i(2, 2): TileType.ROAD_SNEW, Vector2i(3, 2): TileType.ROAD_SNW,
	Vector2i(4, 2): TileType.ROAD_SE_PN, Vector2i(5, 2): TileType.ROAD_EW_PN,
	Vector2i(6, 2): TileType.ROAD_SEW_PN, Vector2i(7, 2): TileType.ROAD_SW_PN,
	Vector2i(8, 2): TileType.ROAD_SNE_PW, Vector2i(9, 2): TileType.ROAD_SNW_PE,
	Vector2i(10, 2): TileType.PARKING_S, Vector2i(11, 2): TileType.MULTI_PARKING_S_PE,
	Vector2i(12, 2): TileType.MULTI_PARKING_S_PEW, Vector2i(13, 2): TileType.MULTI_PARKING_S_PW,
	# Row 3
	Vector2i(0, 3): TileType.ROAD_N, Vector2i(1, 3): TileType.ROAD_NE,
	Vector2i(2, 3): TileType.ROAD_NEW, Vector2i(3, 3): TileType.ROAD_NW,
	Vector2i(4, 3): TileType.ROAD_NE_PS, Vector2i(5, 3): TileType.ROAD_EW_PS,
	Vector2i(6, 3): TileType.ROAD_NEW_PS, Vector2i(7, 3): TileType.ROAD_NW_PS,
	Vector2i(8, 3): TileType.ROAD_NE_PW, Vector2i(9, 3): TileType.ROAD_NW_PE,
	Vector2i(10, 3): TileType.PARKING_N, Vector2i(11, 3): TileType.MULTI_PARKING_N_PE,
	Vector2i(12, 3): TileType.MULTI_PARKING_N_PEW, Vector2i(13, 3): TileType.MULTI_PARKING_N_PW,
	# Row 4
	Vector2i(0, 4): TileType.SPAWN_ROAD_S_A, Vector2i(1, 4): TileType.SPAWN_ROAD_N_A,
	Vector2i(2, 4): TileType.SPAWN_PARKING_N_A, Vector2i(3, 4): TileType.SPAWN_MULTI_PARKING_N_A_PE,
	Vector2i(4, 4): TileType.SPAWN_MULTI_PARKING_N_A_PEW, Vector2i(5, 4): TileType.SPAWN_MULTI_PARKING_N_A_PW,
	Vector2i(6, 4): TileType.SPAWN_PARKING_N_B, Vector2i(7, 4): TileType.SPAWN_MULTI_PARKING_N_B_PE,
	Vector2i(8, 4): TileType.SPAWN_MULTI_PARKING_N_B_PEW, Vector2i(9, 4): TileType.SPAWN_MULTI_PARKING_N_B_PW,
	Vector2i(10, 4): TileType.SPAWN_PARKING_N_C, Vector2i(11, 4): TileType.SPAWN_MULTI_PARKING_N_C_PE,
	Vector2i(12, 4): TileType.SPAWN_MULTI_PARKING_N_C_PEW, Vector2i(13, 4): TileType.SPAWN_MULTI_PARKING_N_C_PW,
	Vector2i(14, 4): TileType.SPAWN_PARKING_N_D, Vector2i(15, 4): TileType.SPAWN_MULTI_PARKING_N_D_PE,
	Vector2i(16, 4): TileType.SPAWN_MULTI_PARKING_N_D_PEW, Vector2i(17, 4): TileType.SPAWN_MULTI_PARKING_N_D_PW,
	# Row 5
	Vector2i(0, 5): TileType.SPAWN_ROAD_S_B, Vector2i(1, 5): TileType.SPAWN_ROAD_N_B,
	Vector2i(2, 5): TileType.SPAWN_PARKING_S_A, Vector2i(3, 5): TileType.SPAWN_MULTI_PARKING_S_A_PE,
	Vector2i(4, 5): TileType.SPAWN_MULTI_PARKING_S_A_PEW, Vector2i(5, 5): TileType.SPAWN_MULTI_PARKING_S_A_PW,
	Vector2i(6, 5): TileType.SPAWN_PARKING_S_B, Vector2i(7, 5): TileType.SPAWN_MULTI_PARKING_S_B_PE,
	Vector2i(8, 5): TileType.SPAWN_MULTI_PARKING_S_B_PEW, Vector2i(9, 5): TileType.SPAWN_MULTI_PARKING_S_B_PW,
	Vector2i(10, 5): TileType.SPAWN_PARKING_S_C, Vector2i(11, 5): TileType.SPAWN_MULTI_PARKING_S_C_PE,
	Vector2i(12, 5): TileType.SPAWN_MULTI_PARKING_S_C_PEW, Vector2i(13, 5): TileType.SPAWN_MULTI_PARKING_S_C_PW,
	Vector2i(14, 5): TileType.SPAWN_PARKING_S_D, Vector2i(15, 5): TileType.SPAWN_MULTI_PARKING_S_D_PE,
	Vector2i(16, 5): TileType.SPAWN_MULTI_PARKING_S_D_PEW, Vector2i(17, 5): TileType.SPAWN_MULTI_PARKING_S_D_PW,
	# Row 6
	Vector2i(0, 6): TileType.SPAWN_ROAD_S_C, Vector2i(1, 6): TileType.SPAWN_ROAD_N_C,
	Vector2i(2, 6): TileType.DEST_PARKING_N_A, Vector2i(3, 6): TileType.DEST_MULTI_PARKING_N_A_PE,
	Vector2i(4, 6): TileType.DEST_MULTI_PARKING_N_A_PEW, Vector2i(5, 6): TileType.DEST_MULTI_PARKING_N_A_PW,
	Vector2i(6, 6): TileType.DEST_PARKING_N_B, Vector2i(7, 6): TileType.DEST_MULTI_PARKING_N_B_PE,
	Vector2i(8, 6): TileType.DEST_MULTI_PARKING_N_B_PEW, Vector2i(9, 6): TileType.DEST_MULTI_PARKING_N_B_PW,
	Vector2i(10, 6): TileType.DEST_PARKING_N_C, Vector2i(11, 6): TileType.DEST_MULTI_PARKING_N_C_PE,
	Vector2i(12, 6): TileType.DEST_MULTI_PARKING_N_C_PEW, Vector2i(13, 6): TileType.DEST_MULTI_PARKING_N_C_PW,
	Vector2i(14, 6): TileType.DEST_PARKING_N_D, Vector2i(15, 6): TileType.DEST_MULTI_PARKING_N_D_PE,
	Vector2i(16, 6): TileType.DEST_MULTI_PARKING_N_D_PEW, Vector2i(17, 6): TileType.DEST_MULTI_PARKING_N_D_PW,
	# Row 7
	Vector2i(0, 7): TileType.SPAWN_ROAD_S_D, Vector2i(1, 7): TileType.SPAWN_ROAD_N_D,
	Vector2i(2, 7): TileType.DEST_PARKING_S_A, Vector2i(3, 7): TileType.DEST_MULTI_PARKING_S_A_PE,
	Vector2i(4, 7): TileType.DEST_MULTI_PARKING_S_A_PEW, Vector2i(5, 7): TileType.DEST_MULTI_PARKING_S_A_PW,
	Vector2i(6, 7): TileType.DEST_PARKING_S_B, Vector2i(7, 7): TileType.DEST_MULTI_PARKING_S_B_PE,
	Vector2i(8, 7): TileType.DEST_MULTI_PARKING_S_B_PEW, Vector2i(9, 7): TileType.DEST_MULTI_PARKING_S_B_PW,
	Vector2i(10, 7): TileType.DEST_PARKING_S_C, Vector2i(11, 7): TileType.DEST_MULTI_PARKING_S_C_PE,
	Vector2i(12, 7): TileType.DEST_MULTI_PARKING_S_C_PEW, Vector2i(13, 7): TileType.DEST_MULTI_PARKING_S_C_PW,
	Vector2i(14, 7): TileType.DEST_PARKING_S_D, Vector2i(15, 7): TileType.DEST_MULTI_PARKING_S_D_PE,
	Vector2i(16, 7): TileType.DEST_MULTI_PARKING_S_D_PEW, Vector2i(17, 7): TileType.DEST_MULTI_PARKING_S_D_PW,
	# Row 8
	Vector2i(0, 8): TileType.PARKING_E, Vector2i(1, 8): TileType.PARKING_W,
	Vector2i(2, 8): TileType.SPAWN_PARKING_E_A, Vector2i(3, 8): TileType.SPAWN_PARKING_W_A,
	Vector2i(4, 8): TileType.SPAWN_PARKING_E_B, Vector2i(5, 8): TileType.SPAWN_PARKING_W_B,
	Vector2i(6, 8): TileType.SPAWN_PARKING_E_C, Vector2i(7, 8): TileType.SPAWN_PARKING_W_C,
	Vector2i(8, 8): TileType.SPAWN_PARKING_E_D, Vector2i(9, 8): TileType.SPAWN_PARKING_W_D,
	Vector2i(10, 8): TileType.DEST_PARKING_E_A, Vector2i(11, 8): TileType.DEST_PARKING_W_A,
	Vector2i(12, 8): TileType.DEST_PARKING_E_B, Vector2i(13, 8): TileType.DEST_PARKING_W_B,
	Vector2i(14, 8): TileType.DEST_PARKING_E_C, Vector2i(15, 8): TileType.DEST_PARKING_W_C,
	Vector2i(16, 8): TileType.DEST_PARKING_E_D, Vector2i(17, 8): TileType.DEST_PARKING_W_D,
	# Row 9
	Vector2i(0, 9): TileType.MULTI_PARKING_E_PS, Vector2i(1, 9): TileType.MULTI_PARKING_W_PS,
	Vector2i(2, 9): TileType.SPAWN_MULTI_PARKING_E_A_PS, Vector2i(3, 9): TileType.SPAWN_MULTI_PARKING_W_A_PS,
	Vector2i(4, 9): TileType.SPAWN_MULTI_PARKING_E_B_PS, Vector2i(5, 9): TileType.SPAWN_MULTI_PARKING_W_B_PS,
	Vector2i(6, 9): TileType.SPAWN_MULTI_PARKING_E_C_PS, Vector2i(7, 9): TileType.SPAWN_MULTI_PARKING_W_C_PS,
	Vector2i(8, 9): TileType.SPAWN_MULTI_PARKING_E_D_PS, Vector2i(9, 9): TileType.SPAWN_MULTI_PARKING_W_D_PS,
	Vector2i(10, 9): TileType.DEST_MULTI_PARKING_E_A_PS, Vector2i(11, 9): TileType.DEST_MULTI_PARKING_W_A_PS,
	Vector2i(12, 9): TileType.DEST_MULTI_PARKING_E_B_PS, Vector2i(13, 9): TileType.DEST_MULTI_PARKING_W_B_PS,
	Vector2i(14, 9): TileType.DEST_MULTI_PARKING_E_C_PS, Vector2i(15, 9): TileType.DEST_MULTI_PARKING_W_C_PS,
	Vector2i(16, 9): TileType.DEST_MULTI_PARKING_E_D_PS, Vector2i(17, 9): TileType.DEST_MULTI_PARKING_W_D_PS,
	# Row 10
	Vector2i(0, 10): TileType.MULTI_PARKING_E_PSN, Vector2i(1, 10): TileType.MULTI_PARKING_W_PSN,
	Vector2i(2, 10): TileType.SPAWN_MULTI_PARKING_E_A_PSN, Vector2i(3, 10): TileType.SPAWN_MULTI_PARKING_W_A_PSN,
	Vector2i(4, 10): TileType.SPAWN_MULTI_PARKING_E_B_PSN, Vector2i(5, 10): TileType.SPAWN_MULTI_PARKING_W_B_PSN,
	Vector2i(6, 10): TileType.SPAWN_MULTI_PARKING_E_C_PSN, Vector2i(7, 10): TileType.SPAWN_MULTI_PARKING_W_C_PSN,
	Vector2i(8, 10): TileType.SPAWN_MULTI_PARKING_E_D_PSN, Vector2i(9, 10): TileType.SPAWN_MULTI_PARKING_W_D_PSN,
	Vector2i(10, 10): TileType.DEST_MULTI_PARKING_E_A_PSN, Vector2i(11, 10): TileType.DEST_MULTI_PARKING_W_A_PSN,
	Vector2i(12, 10): TileType.DEST_MULTI_PARKING_E_B_PSN, Vector2i(13, 10): TileType.DEST_MULTI_PARKING_W_B_PSN,
	Vector2i(14, 10): TileType.DEST_MULTI_PARKING_E_C_PSN, Vector2i(15, 10): TileType.DEST_MULTI_PARKING_W_C_PSN,
	Vector2i(16, 10): TileType.DEST_MULTI_PARKING_E_D_PSN, Vector2i(17, 10): TileType.DEST_MULTI_PARKING_W_D_PSN,
	# Row 11
	Vector2i(0, 11): TileType.MULTI_PARKING_E_PN, Vector2i(1, 11): TileType.MULTI_PARKING_W_PN,
	Vector2i(2, 11): TileType.SPAWN_MULTI_PARKING_E_A_PN, Vector2i(3, 11): TileType.SPAWN_MULTI_PARKING_W_A_PN,
	Vector2i(4, 11): TileType.SPAWN_MULTI_PARKING_E_B_PN, Vector2i(5, 11): TileType.SPAWN_MULTI_PARKING_W_B_PN,
	Vector2i(6, 11): TileType.SPAWN_MULTI_PARKING_E_C_PN, Vector2i(7, 11): TileType.SPAWN_MULTI_PARKING_W_C_PN,
	Vector2i(8, 11): TileType.SPAWN_MULTI_PARKING_E_D_PN, Vector2i(9, 11): TileType.SPAWN_MULTI_PARKING_W_D_PN,
	Vector2i(10, 11): TileType.DEST_MULTI_PARKING_E_A_PN, Vector2i(11, 11): TileType.DEST_MULTI_PARKING_W_A_PN,
	Vector2i(12, 11): TileType.DEST_MULTI_PARKING_E_B_PN, Vector2i(13, 11): TileType.DEST_MULTI_PARKING_W_B_PN,
	Vector2i(14, 11): TileType.DEST_MULTI_PARKING_E_C_PN, Vector2i(15, 11): TileType.DEST_MULTI_PARKING_W_C_PN,
	Vector2i(16, 11): TileType.DEST_MULTI_PARKING_E_D_PN, Vector2i(17, 11): TileType.DEST_MULTI_PARKING_W_D_PN,
}


# Road connections - directions where vehicles can drive (road connections only)
# These are used for vehicle pathfinding
const TILE_ROAD_CONNECTIONS: Dictionary = {
	# Row 0
	TileType.ROAD_NONE: [],
	TileType.ROAD_E: ["right"],
	TileType.ROAD_EW: ["left", "right"],
	TileType.ROAD_W: ["left"],
	TileType.SPAWN_ROAD_W_A: ["left", "right"],
	TileType.SPAWN_ROAD_W_B: ["left", "right"],
	TileType.SPAWN_ROAD_W_C: ["left", "right"],
	TileType.SPAWN_ROAD_W_D: ["left", "right"],
	TileType.ROAD_SE_PW: ["bottom", "right"],
	TileType.ROAD_SW_PE: ["bottom", "left"],
	TileType.ROAD_SE_PNW: ["bottom", "right"],
	TileType.ROAD_SW_PNE: ["bottom", "left"],
	TileType.ROAD_SNEW_12: ["top", "bottom", "left", "right"],
	TileType.ROAD_SNEW_13: ["top", "bottom", "left", "right"],
	TileType.ROAD_SNEW_14: ["top", "bottom", "left", "right"],
	TileType.STOPLIGHT_SNEW: ["top", "bottom", "left", "right"],
	TileType.STOPLIGHT_SEW: ["bottom", "left", "right"],
	# Row 1
	TileType.ROAD_S: ["bottom"],
	TileType.ROAD_SE: ["bottom", "right"],
	TileType.ROAD_SEW: ["bottom", "left", "right"],
	TileType.ROAD_SW: ["bottom", "left"],
	TileType.SPAWN_ROAD_E_A: ["left", "right"],
	TileType.SPAWN_ROAD_E_B: ["left", "right"],
	TileType.SPAWN_ROAD_E_C: ["left", "right"],
	TileType.SPAWN_ROAD_E_D: ["left", "right"],
	TileType.ROAD_SN_PW: ["top", "bottom"],
	TileType.ROAD_SN_PE: ["top", "bottom"],
	TileType.ROAD_NE_PSW: ["top", "right"],
	TileType.ROAD_NW_PSE: ["top", "left"],
	TileType.ROAD_SNEW_1_12: ["top", "bottom", "left", "right"],
	TileType.ROAD_SNEW_1_13: ["top", "bottom", "left", "right"],
	TileType.STOPLIGHT_SNE: ["top", "bottom", "right"],
	TileType.STOPLIGHT_NEW: ["top", "left", "right"],
	TileType.STOPLIGHT_SNW: ["top", "bottom", "left"],
	# Row 2
	TileType.ROAD_SN: ["top", "bottom"],
	TileType.ROAD_SNE: ["top", "bottom", "right"],
	TileType.ROAD_SNEW: ["top", "bottom", "left", "right"],
	TileType.ROAD_SNW: ["top", "bottom", "left"],
	TileType.ROAD_SE_PN: ["bottom", "right"],
	TileType.ROAD_EW_PN: ["left", "right"],
	TileType.ROAD_SEW_PN: ["bottom", "left", "right"],
	TileType.ROAD_SW_PN: ["bottom", "left"],
	TileType.ROAD_SNE_PW: ["top", "bottom", "right"],
	TileType.ROAD_SNW_PE: ["top", "bottom", "left"],
	TileType.PARKING_S: ["bottom"],
	TileType.MULTI_PARKING_S_PE: ["bottom"],
	TileType.MULTI_PARKING_S_PEW: ["bottom"],
	TileType.MULTI_PARKING_S_PW: ["bottom"],
	# Row 3
	TileType.ROAD_N: ["top"],
	TileType.ROAD_NE: ["top", "right"],
	TileType.ROAD_NEW: ["top", "left", "right"],
	TileType.ROAD_NW: ["top", "left"],
	TileType.ROAD_NE_PS: ["top", "right"],
	TileType.ROAD_EW_PS: ["left", "right"],
	TileType.ROAD_NEW_PS: ["top", "left", "right"],
	TileType.ROAD_NW_PS: ["top", "left"],
	TileType.ROAD_NE_PW: ["top", "right"],
	TileType.ROAD_NW_PE: ["top", "left"],
	TileType.PARKING_N: ["top"],
	TileType.MULTI_PARKING_N_PE: ["top"],
	TileType.MULTI_PARKING_N_PEW: ["top"],
	TileType.MULTI_PARKING_N_PW: ["top"],
	# Row 4 - Spawn roads and spawn parking (spawn facing south, road connection south)
	TileType.SPAWN_ROAD_S_A: ["top", "bottom"],
	TileType.SPAWN_ROAD_N_A: ["top", "bottom"],
	TileType.SPAWN_PARKING_N_A: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_A_PE: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_A_PEW: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_A_PW: ["bottom"],
	TileType.SPAWN_PARKING_N_B: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_B_PE: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_B_PEW: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_B_PW: ["bottom"],
	TileType.SPAWN_PARKING_N_C: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_C_PE: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_C_PEW: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_C_PW: ["bottom"],
	TileType.SPAWN_PARKING_N_D: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_D_PE: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_D_PEW: ["bottom"],
	TileType.SPAWN_MULTI_PARKING_N_D_PW: ["bottom"],
	# Row 5 - Spawn roads and spawn parking (spawn facing north, road connection north)
	TileType.SPAWN_ROAD_S_B: ["top", "bottom"],
	TileType.SPAWN_ROAD_N_B: ["top", "bottom"],
	TileType.SPAWN_PARKING_S_A: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_A_PE: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_A_PEW: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_A_PW: ["top"],
	TileType.SPAWN_PARKING_S_B: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_B_PE: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_B_PEW: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_B_PW: ["top"],
	TileType.SPAWN_PARKING_S_C: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_C_PE: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_C_PEW: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_C_PW: ["top"],
	TileType.SPAWN_PARKING_S_D: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_D_PE: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_D_PEW: ["top"],
	TileType.SPAWN_MULTI_PARKING_S_D_PW: ["top"],
	# Row 6 - Spawn roads and dest parking (road connection south)
	TileType.SPAWN_ROAD_S_C: ["top", "bottom"],
	TileType.SPAWN_ROAD_N_C: ["top", "bottom"],
	TileType.DEST_PARKING_N_A: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_A_PE: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_A_PEW: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_A_PW: ["bottom"],
	TileType.DEST_PARKING_N_B: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_B_PE: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_B_PEW: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_B_PW: ["bottom"],
	TileType.DEST_PARKING_N_C: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_C_PE: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_C_PEW: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_C_PW: ["bottom"],
	TileType.DEST_PARKING_N_D: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_D_PE: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_D_PEW: ["bottom"],
	TileType.DEST_MULTI_PARKING_N_D_PW: ["bottom"],
	# Row 7 - Spawn roads and dest parking (road connection north)
	TileType.SPAWN_ROAD_S_D: ["top", "bottom"],
	TileType.SPAWN_ROAD_N_D: ["top", "bottom"],
	TileType.DEST_PARKING_S_A: ["top"],
	TileType.DEST_MULTI_PARKING_S_A_PE: ["top"],
	TileType.DEST_MULTI_PARKING_S_A_PEW: ["top"],
	TileType.DEST_MULTI_PARKING_S_A_PW: ["top"],
	TileType.DEST_PARKING_S_B: ["top"],
	TileType.DEST_MULTI_PARKING_S_B_PE: ["top"],
	TileType.DEST_MULTI_PARKING_S_B_PEW: ["top"],
	TileType.DEST_MULTI_PARKING_S_B_PW: ["top"],
	TileType.DEST_PARKING_S_C: ["top"],
	TileType.DEST_MULTI_PARKING_S_C_PE: ["top"],
	TileType.DEST_MULTI_PARKING_S_C_PEW: ["top"],
	TileType.DEST_MULTI_PARKING_S_C_PW: ["top"],
	TileType.DEST_PARKING_S_D: ["top"],
	TileType.DEST_MULTI_PARKING_S_D_PE: ["top"],
	TileType.DEST_MULTI_PARKING_S_D_PEW: ["top"],
	TileType.DEST_MULTI_PARKING_S_D_PW: ["top"],
	# Row 8 - Parking E/W
	TileType.PARKING_E: ["right"],
	TileType.PARKING_W: ["left"],
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
	# Row 9 - Multi parking E/W with PS
	TileType.MULTI_PARKING_E_PS: ["right"],
	TileType.MULTI_PARKING_W_PS: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_A_PS: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_A_PS: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_B_PS: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_B_PS: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_C_PS: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_C_PS: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_D_PS: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_D_PS: ["left"],
	TileType.DEST_MULTI_PARKING_E_A_PS: ["right"],
	TileType.DEST_MULTI_PARKING_W_A_PS: ["left"],
	TileType.DEST_MULTI_PARKING_E_B_PS: ["right"],
	TileType.DEST_MULTI_PARKING_W_B_PS: ["left"],
	TileType.DEST_MULTI_PARKING_E_C_PS: ["right"],
	TileType.DEST_MULTI_PARKING_W_C_PS: ["left"],
	TileType.DEST_MULTI_PARKING_E_D_PS: ["right"],
	TileType.DEST_MULTI_PARKING_W_D_PS: ["left"],
	# Row 10 - Multi parking E/W with PSN
	TileType.MULTI_PARKING_E_PSN: ["right"],
	TileType.MULTI_PARKING_W_PSN: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_A_PSN: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_A_PSN: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_B_PSN: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_B_PSN: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_C_PSN: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_C_PSN: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_D_PSN: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_D_PSN: ["left"],
	TileType.DEST_MULTI_PARKING_E_A_PSN: ["right"],
	TileType.DEST_MULTI_PARKING_W_A_PSN: ["left"],
	TileType.DEST_MULTI_PARKING_E_B_PSN: ["right"],
	TileType.DEST_MULTI_PARKING_W_B_PSN: ["left"],
	TileType.DEST_MULTI_PARKING_E_C_PSN: ["right"],
	TileType.DEST_MULTI_PARKING_W_C_PSN: ["left"],
	TileType.DEST_MULTI_PARKING_E_D_PSN: ["right"],
	TileType.DEST_MULTI_PARKING_W_D_PSN: ["left"],
	# Row 11 - Multi parking E/W with PN
	TileType.MULTI_PARKING_E_PN: ["right"],
	TileType.MULTI_PARKING_W_PN: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_A_PN: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_A_PN: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_B_PN: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_B_PN: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_C_PN: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_C_PN: ["left"],
	TileType.SPAWN_MULTI_PARKING_E_D_PN: ["right"],
	TileType.SPAWN_MULTI_PARKING_W_D_PN: ["left"],
	TileType.DEST_MULTI_PARKING_E_A_PN: ["right"],
	TileType.DEST_MULTI_PARKING_W_A_PN: ["left"],
	TileType.DEST_MULTI_PARKING_E_B_PN: ["right"],
	TileType.DEST_MULTI_PARKING_W_B_PN: ["left"],
	TileType.DEST_MULTI_PARKING_E_C_PN: ["right"],
	TileType.DEST_MULTI_PARKING_W_C_PN: ["left"],
	TileType.DEST_MULTI_PARKING_E_D_PN: ["right"],
	TileType.DEST_MULTI_PARKING_W_D_PN: ["left"],
	TileType.NONE: []
}


# Mapping from TileType to SpawnGroup
const TILE_TO_GROUP: Dictionary = {
	# Spawn road groups (rows 0, 1, 4-7 columns 0-1)
	TileType.SPAWN_ROAD_W_A: SpawnGroup.A, TileType.SPAWN_ROAD_W_B: SpawnGroup.B,
	TileType.SPAWN_ROAD_W_C: SpawnGroup.C, TileType.SPAWN_ROAD_W_D: SpawnGroup.D,
	TileType.SPAWN_ROAD_E_A: SpawnGroup.A, TileType.SPAWN_ROAD_E_B: SpawnGroup.B,
	TileType.SPAWN_ROAD_E_C: SpawnGroup.C, TileType.SPAWN_ROAD_E_D: SpawnGroup.D,
	TileType.SPAWN_ROAD_S_A: SpawnGroup.A, TileType.SPAWN_ROAD_N_A: SpawnGroup.A,
	TileType.SPAWN_ROAD_S_B: SpawnGroup.B, TileType.SPAWN_ROAD_N_B: SpawnGroup.B,
	TileType.SPAWN_ROAD_S_C: SpawnGroup.C, TileType.SPAWN_ROAD_N_C: SpawnGroup.C,
	TileType.SPAWN_ROAD_S_D: SpawnGroup.D, TileType.SPAWN_ROAD_N_D: SpawnGroup.D,
	# Spawn parking N groups (row 4)
	TileType.SPAWN_PARKING_N_A: SpawnGroup.A, TileType.SPAWN_MULTI_PARKING_N_A_PE: SpawnGroup.A,
	TileType.SPAWN_MULTI_PARKING_N_A_PEW: SpawnGroup.A, TileType.SPAWN_MULTI_PARKING_N_A_PW: SpawnGroup.A,
	TileType.SPAWN_PARKING_N_B: SpawnGroup.B, TileType.SPAWN_MULTI_PARKING_N_B_PE: SpawnGroup.B,
	TileType.SPAWN_MULTI_PARKING_N_B_PEW: SpawnGroup.B, TileType.SPAWN_MULTI_PARKING_N_B_PW: SpawnGroup.B,
	TileType.SPAWN_PARKING_N_C: SpawnGroup.C, TileType.SPAWN_MULTI_PARKING_N_C_PE: SpawnGroup.C,
	TileType.SPAWN_MULTI_PARKING_N_C_PEW: SpawnGroup.C, TileType.SPAWN_MULTI_PARKING_N_C_PW: SpawnGroup.C,
	TileType.SPAWN_PARKING_N_D: SpawnGroup.D, TileType.SPAWN_MULTI_PARKING_N_D_PE: SpawnGroup.D,
	TileType.SPAWN_MULTI_PARKING_N_D_PEW: SpawnGroup.D, TileType.SPAWN_MULTI_PARKING_N_D_PW: SpawnGroup.D,
	# Spawn parking S groups (row 5)
	TileType.SPAWN_PARKING_S_A: SpawnGroup.A, TileType.SPAWN_MULTI_PARKING_S_A_PE: SpawnGroup.A,
	TileType.SPAWN_MULTI_PARKING_S_A_PEW: SpawnGroup.A, TileType.SPAWN_MULTI_PARKING_S_A_PW: SpawnGroup.A,
	TileType.SPAWN_PARKING_S_B: SpawnGroup.B, TileType.SPAWN_MULTI_PARKING_S_B_PE: SpawnGroup.B,
	TileType.SPAWN_MULTI_PARKING_S_B_PEW: SpawnGroup.B, TileType.SPAWN_MULTI_PARKING_S_B_PW: SpawnGroup.B,
	TileType.SPAWN_PARKING_S_C: SpawnGroup.C, TileType.SPAWN_MULTI_PARKING_S_C_PE: SpawnGroup.C,
	TileType.SPAWN_MULTI_PARKING_S_C_PEW: SpawnGroup.C, TileType.SPAWN_MULTI_PARKING_S_C_PW: SpawnGroup.C,
	TileType.SPAWN_PARKING_S_D: SpawnGroup.D, TileType.SPAWN_MULTI_PARKING_S_D_PE: SpawnGroup.D,
	TileType.SPAWN_MULTI_PARKING_S_D_PEW: SpawnGroup.D, TileType.SPAWN_MULTI_PARKING_S_D_PW: SpawnGroup.D,
	# Dest parking N groups (row 6)
	TileType.DEST_PARKING_N_A: SpawnGroup.A, TileType.DEST_MULTI_PARKING_N_A_PE: SpawnGroup.A,
	TileType.DEST_MULTI_PARKING_N_A_PEW: SpawnGroup.A, TileType.DEST_MULTI_PARKING_N_A_PW: SpawnGroup.A,
	TileType.DEST_PARKING_N_B: SpawnGroup.B, TileType.DEST_MULTI_PARKING_N_B_PE: SpawnGroup.B,
	TileType.DEST_MULTI_PARKING_N_B_PEW: SpawnGroup.B, TileType.DEST_MULTI_PARKING_N_B_PW: SpawnGroup.B,
	TileType.DEST_PARKING_N_C: SpawnGroup.C, TileType.DEST_MULTI_PARKING_N_C_PE: SpawnGroup.C,
	TileType.DEST_MULTI_PARKING_N_C_PEW: SpawnGroup.C, TileType.DEST_MULTI_PARKING_N_C_PW: SpawnGroup.C,
	TileType.DEST_PARKING_N_D: SpawnGroup.D, TileType.DEST_MULTI_PARKING_N_D_PE: SpawnGroup.D,
	TileType.DEST_MULTI_PARKING_N_D_PEW: SpawnGroup.D, TileType.DEST_MULTI_PARKING_N_D_PW: SpawnGroup.D,
	# Dest parking S groups (row 7)
	TileType.DEST_PARKING_S_A: SpawnGroup.A, TileType.DEST_MULTI_PARKING_S_A_PE: SpawnGroup.A,
	TileType.DEST_MULTI_PARKING_S_A_PEW: SpawnGroup.A, TileType.DEST_MULTI_PARKING_S_A_PW: SpawnGroup.A,
	TileType.DEST_PARKING_S_B: SpawnGroup.B, TileType.DEST_MULTI_PARKING_S_B_PE: SpawnGroup.B,
	TileType.DEST_MULTI_PARKING_S_B_PEW: SpawnGroup.B, TileType.DEST_MULTI_PARKING_S_B_PW: SpawnGroup.B,
	TileType.DEST_PARKING_S_C: SpawnGroup.C, TileType.DEST_MULTI_PARKING_S_C_PE: SpawnGroup.C,
	TileType.DEST_MULTI_PARKING_S_C_PEW: SpawnGroup.C, TileType.DEST_MULTI_PARKING_S_C_PW: SpawnGroup.C,
	TileType.DEST_PARKING_S_D: SpawnGroup.D, TileType.DEST_MULTI_PARKING_S_D_PE: SpawnGroup.D,
	TileType.DEST_MULTI_PARKING_S_D_PEW: SpawnGroup.D, TileType.DEST_MULTI_PARKING_S_D_PW: SpawnGroup.D,
	# Spawn parking E/W groups (row 8)
	TileType.SPAWN_PARKING_E_A: SpawnGroup.A, TileType.SPAWN_PARKING_W_A: SpawnGroup.A,
	TileType.SPAWN_PARKING_E_B: SpawnGroup.B, TileType.SPAWN_PARKING_W_B: SpawnGroup.B,
	TileType.SPAWN_PARKING_E_C: SpawnGroup.C, TileType.SPAWN_PARKING_W_C: SpawnGroup.C,
	TileType.SPAWN_PARKING_E_D: SpawnGroup.D, TileType.SPAWN_PARKING_W_D: SpawnGroup.D,
	# Dest parking E/W groups (row 8)
	TileType.DEST_PARKING_E_A: SpawnGroup.A, TileType.DEST_PARKING_W_A: SpawnGroup.A,
	TileType.DEST_PARKING_E_B: SpawnGroup.B, TileType.DEST_PARKING_W_B: SpawnGroup.B,
	TileType.DEST_PARKING_E_C: SpawnGroup.C, TileType.DEST_PARKING_W_C: SpawnGroup.C,
	TileType.DEST_PARKING_E_D: SpawnGroup.D, TileType.DEST_PARKING_W_D: SpawnGroup.D,
	# Spawn multi parking E/W with PS groups (row 9)
	TileType.SPAWN_MULTI_PARKING_E_A_PS: SpawnGroup.A, TileType.SPAWN_MULTI_PARKING_W_A_PS: SpawnGroup.A,
	TileType.SPAWN_MULTI_PARKING_E_B_PS: SpawnGroup.B, TileType.SPAWN_MULTI_PARKING_W_B_PS: SpawnGroup.B,
	TileType.SPAWN_MULTI_PARKING_E_C_PS: SpawnGroup.C, TileType.SPAWN_MULTI_PARKING_W_C_PS: SpawnGroup.C,
	TileType.SPAWN_MULTI_PARKING_E_D_PS: SpawnGroup.D, TileType.SPAWN_MULTI_PARKING_W_D_PS: SpawnGroup.D,
	# Dest multi parking E/W with PS groups (row 9)
	TileType.DEST_MULTI_PARKING_E_A_PS: SpawnGroup.A, TileType.DEST_MULTI_PARKING_W_A_PS: SpawnGroup.A,
	TileType.DEST_MULTI_PARKING_E_B_PS: SpawnGroup.B, TileType.DEST_MULTI_PARKING_W_B_PS: SpawnGroup.B,
	TileType.DEST_MULTI_PARKING_E_C_PS: SpawnGroup.C, TileType.DEST_MULTI_PARKING_W_C_PS: SpawnGroup.C,
	TileType.DEST_MULTI_PARKING_E_D_PS: SpawnGroup.D, TileType.DEST_MULTI_PARKING_W_D_PS: SpawnGroup.D,
	# Spawn multi parking E/W with PSN groups (row 10)
	TileType.SPAWN_MULTI_PARKING_E_A_PSN: SpawnGroup.A, TileType.SPAWN_MULTI_PARKING_W_A_PSN: SpawnGroup.A,
	TileType.SPAWN_MULTI_PARKING_E_B_PSN: SpawnGroup.B, TileType.SPAWN_MULTI_PARKING_W_B_PSN: SpawnGroup.B,
	TileType.SPAWN_MULTI_PARKING_E_C_PSN: SpawnGroup.C, TileType.SPAWN_MULTI_PARKING_W_C_PSN: SpawnGroup.C,
	TileType.SPAWN_MULTI_PARKING_E_D_PSN: SpawnGroup.D, TileType.SPAWN_MULTI_PARKING_W_D_PSN: SpawnGroup.D,
	# Dest multi parking E/W with PSN groups (row 10)
	TileType.DEST_MULTI_PARKING_E_A_PSN: SpawnGroup.A, TileType.DEST_MULTI_PARKING_W_A_PSN: SpawnGroup.A,
	TileType.DEST_MULTI_PARKING_E_B_PSN: SpawnGroup.B, TileType.DEST_MULTI_PARKING_W_B_PSN: SpawnGroup.B,
	TileType.DEST_MULTI_PARKING_E_C_PSN: SpawnGroup.C, TileType.DEST_MULTI_PARKING_W_C_PSN: SpawnGroup.C,
	TileType.DEST_MULTI_PARKING_E_D_PSN: SpawnGroup.D, TileType.DEST_MULTI_PARKING_W_D_PSN: SpawnGroup.D,
	# Spawn multi parking E/W with PN groups (row 11)
	TileType.SPAWN_MULTI_PARKING_E_A_PN: SpawnGroup.A, TileType.SPAWN_MULTI_PARKING_W_A_PN: SpawnGroup.A,
	TileType.SPAWN_MULTI_PARKING_E_B_PN: SpawnGroup.B, TileType.SPAWN_MULTI_PARKING_W_B_PN: SpawnGroup.B,
	TileType.SPAWN_MULTI_PARKING_E_C_PN: SpawnGroup.C, TileType.SPAWN_MULTI_PARKING_W_C_PN: SpawnGroup.C,
	TileType.SPAWN_MULTI_PARKING_E_D_PN: SpawnGroup.D, TileType.SPAWN_MULTI_PARKING_W_D_PN: SpawnGroup.D,
	# Dest multi parking E/W with PN groups (row 11)
	TileType.DEST_MULTI_PARKING_E_A_PN: SpawnGroup.A, TileType.DEST_MULTI_PARKING_W_A_PN: SpawnGroup.A,
	TileType.DEST_MULTI_PARKING_E_B_PN: SpawnGroup.B, TileType.DEST_MULTI_PARKING_W_B_PN: SpawnGroup.B,
	TileType.DEST_MULTI_PARKING_E_C_PN: SpawnGroup.C, TileType.DEST_MULTI_PARKING_W_C_PN: SpawnGroup.C,
	TileType.DEST_MULTI_PARKING_E_D_PN: SpawnGroup.D, TileType.DEST_MULTI_PARKING_W_D_PN: SpawnGroup.D,
}

# Spawn facing direction - the direction the car faces when spawning
# This is separate from road connections because spawn roads have multiple connections
const SPAWN_FACING_DIRECTION: Dictionary = {
	# Row 0 - Spawn facing WEST (r0/c4-c7)
	TileType.SPAWN_ROAD_W_A: "left", TileType.SPAWN_ROAD_W_B: "left",
	TileType.SPAWN_ROAD_W_C: "left", TileType.SPAWN_ROAD_W_D: "left",
	# Row 1 - Spawn facing EAST (r1/c4-c7)
	TileType.SPAWN_ROAD_E_A: "right", TileType.SPAWN_ROAD_E_B: "right",
	TileType.SPAWN_ROAD_E_C: "right", TileType.SPAWN_ROAD_E_D: "right",
	# Row 4 - Spawn roads facing S/N (r4/c0-c1)
	TileType.SPAWN_ROAD_S_A: "bottom", TileType.SPAWN_ROAD_N_A: "top",
	# Row 4 - Spawn parking facing SOUTH (r4/c2-c17) - cars exit through bottom (south)
	TileType.SPAWN_PARKING_N_A: "bottom", TileType.SPAWN_MULTI_PARKING_N_A_PE: "bottom",
	TileType.SPAWN_MULTI_PARKING_N_A_PEW: "bottom", TileType.SPAWN_MULTI_PARKING_N_A_PW: "bottom",
	TileType.SPAWN_PARKING_N_B: "bottom", TileType.SPAWN_MULTI_PARKING_N_B_PE: "bottom",
	TileType.SPAWN_MULTI_PARKING_N_B_PEW: "bottom", TileType.SPAWN_MULTI_PARKING_N_B_PW: "bottom",
	TileType.SPAWN_PARKING_N_C: "bottom", TileType.SPAWN_MULTI_PARKING_N_C_PE: "bottom",
	TileType.SPAWN_MULTI_PARKING_N_C_PEW: "bottom", TileType.SPAWN_MULTI_PARKING_N_C_PW: "bottom",
	TileType.SPAWN_PARKING_N_D: "bottom", TileType.SPAWN_MULTI_PARKING_N_D_PE: "bottom",
	TileType.SPAWN_MULTI_PARKING_N_D_PEW: "bottom", TileType.SPAWN_MULTI_PARKING_N_D_PW: "bottom",
	# Row 5 - Spawn roads facing S/N (r5/c0-c1)
	TileType.SPAWN_ROAD_S_B: "bottom", TileType.SPAWN_ROAD_N_B: "top",
	# Row 5 - Spawn parking facing NORTH (r5/c2-c17) - cars exit through top (north)
	TileType.SPAWN_PARKING_S_A: "top", TileType.SPAWN_MULTI_PARKING_S_A_PE: "top",
	TileType.SPAWN_MULTI_PARKING_S_A_PEW: "top", TileType.SPAWN_MULTI_PARKING_S_A_PW: "top",
	TileType.SPAWN_PARKING_S_B: "top", TileType.SPAWN_MULTI_PARKING_S_B_PE: "top",
	TileType.SPAWN_MULTI_PARKING_S_B_PEW: "top", TileType.SPAWN_MULTI_PARKING_S_B_PW: "top",
	TileType.SPAWN_PARKING_S_C: "top", TileType.SPAWN_MULTI_PARKING_S_C_PE: "top",
	TileType.SPAWN_MULTI_PARKING_S_C_PEW: "top", TileType.SPAWN_MULTI_PARKING_S_C_PW: "top",
	TileType.SPAWN_PARKING_S_D: "top", TileType.SPAWN_MULTI_PARKING_S_D_PE: "top",
	TileType.SPAWN_MULTI_PARKING_S_D_PEW: "top", TileType.SPAWN_MULTI_PARKING_S_D_PW: "top",
	# Row 6 - Spawn roads facing S/N (r6/c0-c1)
	TileType.SPAWN_ROAD_S_C: "bottom", TileType.SPAWN_ROAD_N_C: "top",
	# Row 7 - Spawn roads facing S/N (r7/c0-c1)
	TileType.SPAWN_ROAD_S_D: "bottom", TileType.SPAWN_ROAD_N_D: "top",
	# Row 8 - Spawn parking facing E/W (r8/c2-c9)
	TileType.SPAWN_PARKING_E_A: "right", TileType.SPAWN_PARKING_W_A: "left",
	TileType.SPAWN_PARKING_E_B: "right", TileType.SPAWN_PARKING_W_B: "left",
	TileType.SPAWN_PARKING_E_C: "right", TileType.SPAWN_PARKING_W_C: "left",
	TileType.SPAWN_PARKING_E_D: "right", TileType.SPAWN_PARKING_W_D: "left",
	# Row 9 - Spawn multi parking facing E/W (r9/c2-c9)
	TileType.SPAWN_MULTI_PARKING_E_A_PS: "right", TileType.SPAWN_MULTI_PARKING_W_A_PS: "left",
	TileType.SPAWN_MULTI_PARKING_E_B_PS: "right", TileType.SPAWN_MULTI_PARKING_W_B_PS: "left",
	TileType.SPAWN_MULTI_PARKING_E_C_PS: "right", TileType.SPAWN_MULTI_PARKING_W_C_PS: "left",
	TileType.SPAWN_MULTI_PARKING_E_D_PS: "right", TileType.SPAWN_MULTI_PARKING_W_D_PS: "left",
	# Row 10 - Spawn multi parking facing E/W (r10/c2-c9)
	TileType.SPAWN_MULTI_PARKING_E_A_PSN: "right", TileType.SPAWN_MULTI_PARKING_W_A_PSN: "left",
	TileType.SPAWN_MULTI_PARKING_E_B_PSN: "right", TileType.SPAWN_MULTI_PARKING_W_B_PSN: "left",
	TileType.SPAWN_MULTI_PARKING_E_C_PSN: "right", TileType.SPAWN_MULTI_PARKING_W_C_PSN: "left",
	TileType.SPAWN_MULTI_PARKING_E_D_PSN: "right", TileType.SPAWN_MULTI_PARKING_W_D_PSN: "left",
	# Row 11 - Spawn multi parking facing E/W (r11/c2-c9)
	TileType.SPAWN_MULTI_PARKING_E_A_PN: "right", TileType.SPAWN_MULTI_PARKING_W_A_PN: "left",
	TileType.SPAWN_MULTI_PARKING_E_B_PN: "right", TileType.SPAWN_MULTI_PARKING_W_B_PN: "left",
	TileType.SPAWN_MULTI_PARKING_E_C_PN: "right", TileType.SPAWN_MULTI_PARKING_W_C_PN: "left",
	TileType.SPAWN_MULTI_PARKING_E_D_PN: "right", TileType.SPAWN_MULTI_PARKING_W_D_PN: "left",
}

# All spawn tiles (roads and parking)
const SPAWN_TILES: Array = [
	# Spawn roads
	TileType.SPAWN_ROAD_W_A, TileType.SPAWN_ROAD_W_B, TileType.SPAWN_ROAD_W_C, TileType.SPAWN_ROAD_W_D,
	TileType.SPAWN_ROAD_E_A, TileType.SPAWN_ROAD_E_B, TileType.SPAWN_ROAD_E_C, TileType.SPAWN_ROAD_E_D,
	TileType.SPAWN_ROAD_S_A, TileType.SPAWN_ROAD_N_A, TileType.SPAWN_ROAD_S_B, TileType.SPAWN_ROAD_N_B,
	TileType.SPAWN_ROAD_S_C, TileType.SPAWN_ROAD_N_C, TileType.SPAWN_ROAD_S_D, TileType.SPAWN_ROAD_N_D,
	# Spawn parking N (row 4)
	TileType.SPAWN_PARKING_N_A, TileType.SPAWN_MULTI_PARKING_N_A_PE, TileType.SPAWN_MULTI_PARKING_N_A_PEW, TileType.SPAWN_MULTI_PARKING_N_A_PW,
	TileType.SPAWN_PARKING_N_B, TileType.SPAWN_MULTI_PARKING_N_B_PE, TileType.SPAWN_MULTI_PARKING_N_B_PEW, TileType.SPAWN_MULTI_PARKING_N_B_PW,
	TileType.SPAWN_PARKING_N_C, TileType.SPAWN_MULTI_PARKING_N_C_PE, TileType.SPAWN_MULTI_PARKING_N_C_PEW, TileType.SPAWN_MULTI_PARKING_N_C_PW,
	TileType.SPAWN_PARKING_N_D, TileType.SPAWN_MULTI_PARKING_N_D_PE, TileType.SPAWN_MULTI_PARKING_N_D_PEW, TileType.SPAWN_MULTI_PARKING_N_D_PW,
	# Spawn parking S (row 5)
	TileType.SPAWN_PARKING_S_A, TileType.SPAWN_MULTI_PARKING_S_A_PE, TileType.SPAWN_MULTI_PARKING_S_A_PEW, TileType.SPAWN_MULTI_PARKING_S_A_PW,
	TileType.SPAWN_PARKING_S_B, TileType.SPAWN_MULTI_PARKING_S_B_PE, TileType.SPAWN_MULTI_PARKING_S_B_PEW, TileType.SPAWN_MULTI_PARKING_S_B_PW,
	TileType.SPAWN_PARKING_S_C, TileType.SPAWN_MULTI_PARKING_S_C_PE, TileType.SPAWN_MULTI_PARKING_S_C_PEW, TileType.SPAWN_MULTI_PARKING_S_C_PW,
	TileType.SPAWN_PARKING_S_D, TileType.SPAWN_MULTI_PARKING_S_D_PE, TileType.SPAWN_MULTI_PARKING_S_D_PEW, TileType.SPAWN_MULTI_PARKING_S_D_PW,
	# Spawn parking E/W (row 8)
	TileType.SPAWN_PARKING_E_A, TileType.SPAWN_PARKING_W_A, TileType.SPAWN_PARKING_E_B, TileType.SPAWN_PARKING_W_B,
	TileType.SPAWN_PARKING_E_C, TileType.SPAWN_PARKING_W_C, TileType.SPAWN_PARKING_E_D, TileType.SPAWN_PARKING_W_D,
	# Spawn multi parking E/W with PS (row 9)
	TileType.SPAWN_MULTI_PARKING_E_A_PS, TileType.SPAWN_MULTI_PARKING_W_A_PS, TileType.SPAWN_MULTI_PARKING_E_B_PS, TileType.SPAWN_MULTI_PARKING_W_B_PS,
	TileType.SPAWN_MULTI_PARKING_E_C_PS, TileType.SPAWN_MULTI_PARKING_W_C_PS, TileType.SPAWN_MULTI_PARKING_E_D_PS, TileType.SPAWN_MULTI_PARKING_W_D_PS,
	# Spawn multi parking E/W with PSN (row 10)
	TileType.SPAWN_MULTI_PARKING_E_A_PSN, TileType.SPAWN_MULTI_PARKING_W_A_PSN, TileType.SPAWN_MULTI_PARKING_E_B_PSN, TileType.SPAWN_MULTI_PARKING_W_B_PSN,
	TileType.SPAWN_MULTI_PARKING_E_C_PSN, TileType.SPAWN_MULTI_PARKING_W_C_PSN, TileType.SPAWN_MULTI_PARKING_E_D_PSN, TileType.SPAWN_MULTI_PARKING_W_D_PSN,
	# Spawn multi parking E/W with PN (row 11)
	TileType.SPAWN_MULTI_PARKING_E_A_PN, TileType.SPAWN_MULTI_PARKING_W_A_PN, TileType.SPAWN_MULTI_PARKING_E_B_PN, TileType.SPAWN_MULTI_PARKING_W_B_PN,
	TileType.SPAWN_MULTI_PARKING_E_C_PN, TileType.SPAWN_MULTI_PARKING_W_C_PN, TileType.SPAWN_MULTI_PARKING_E_D_PN, TileType.SPAWN_MULTI_PARKING_W_D_PN,
]

# All destination tiles
const DEST_TILES: Array = [
	# Dest parking N (row 6)
	TileType.DEST_PARKING_N_A, TileType.DEST_MULTI_PARKING_N_A_PE, TileType.DEST_MULTI_PARKING_N_A_PEW, TileType.DEST_MULTI_PARKING_N_A_PW,
	TileType.DEST_PARKING_N_B, TileType.DEST_MULTI_PARKING_N_B_PE, TileType.DEST_MULTI_PARKING_N_B_PEW, TileType.DEST_MULTI_PARKING_N_B_PW,
	TileType.DEST_PARKING_N_C, TileType.DEST_MULTI_PARKING_N_C_PE, TileType.DEST_MULTI_PARKING_N_C_PEW, TileType.DEST_MULTI_PARKING_N_C_PW,
	TileType.DEST_PARKING_N_D, TileType.DEST_MULTI_PARKING_N_D_PE, TileType.DEST_MULTI_PARKING_N_D_PEW, TileType.DEST_MULTI_PARKING_N_D_PW,
	# Dest parking S (row 7)
	TileType.DEST_PARKING_S_A, TileType.DEST_MULTI_PARKING_S_A_PE, TileType.DEST_MULTI_PARKING_S_A_PEW, TileType.DEST_MULTI_PARKING_S_A_PW,
	TileType.DEST_PARKING_S_B, TileType.DEST_MULTI_PARKING_S_B_PE, TileType.DEST_MULTI_PARKING_S_B_PEW, TileType.DEST_MULTI_PARKING_S_B_PW,
	TileType.DEST_PARKING_S_C, TileType.DEST_MULTI_PARKING_S_C_PE, TileType.DEST_MULTI_PARKING_S_C_PEW, TileType.DEST_MULTI_PARKING_S_C_PW,
	TileType.DEST_PARKING_S_D, TileType.DEST_MULTI_PARKING_S_D_PE, TileType.DEST_MULTI_PARKING_S_D_PEW, TileType.DEST_MULTI_PARKING_S_D_PW,
	# Dest parking E/W (row 8)
	TileType.DEST_PARKING_E_A, TileType.DEST_PARKING_W_A, TileType.DEST_PARKING_E_B, TileType.DEST_PARKING_W_B,
	TileType.DEST_PARKING_E_C, TileType.DEST_PARKING_W_C, TileType.DEST_PARKING_E_D, TileType.DEST_PARKING_W_D,
	# Dest multi parking E/W with PS (row 9)
	TileType.DEST_MULTI_PARKING_E_A_PS, TileType.DEST_MULTI_PARKING_W_A_PS, TileType.DEST_MULTI_PARKING_E_B_PS, TileType.DEST_MULTI_PARKING_W_B_PS,
	TileType.DEST_MULTI_PARKING_E_C_PS, TileType.DEST_MULTI_PARKING_W_C_PS, TileType.DEST_MULTI_PARKING_E_D_PS, TileType.DEST_MULTI_PARKING_W_D_PS,
	# Dest multi parking E/W with PSN (row 10)
	TileType.DEST_MULTI_PARKING_E_A_PSN, TileType.DEST_MULTI_PARKING_W_A_PSN, TileType.DEST_MULTI_PARKING_E_B_PSN, TileType.DEST_MULTI_PARKING_W_B_PSN,
	TileType.DEST_MULTI_PARKING_E_C_PSN, TileType.DEST_MULTI_PARKING_W_C_PSN, TileType.DEST_MULTI_PARKING_E_D_PSN, TileType.DEST_MULTI_PARKING_W_D_PSN,
	# Dest multi parking E/W with PN (row 11)
	TileType.DEST_MULTI_PARKING_E_A_PN, TileType.DEST_MULTI_PARKING_W_A_PN, TileType.DEST_MULTI_PARKING_E_B_PN, TileType.DEST_MULTI_PARKING_W_B_PN,
	TileType.DEST_MULTI_PARKING_E_C_PN, TileType.DEST_MULTI_PARKING_W_C_PN, TileType.DEST_MULTI_PARKING_E_D_PN, TileType.DEST_MULTI_PARKING_W_D_PN,
]

# All stoplight tiles
const STOPLIGHT_TILES: Array = [
	TileType.STOPLIGHT_SNEW, TileType.STOPLIGHT_SEW,
	TileType.STOPLIGHT_SNE, TileType.STOPLIGHT_NEW, TileType.STOPLIGHT_SNW,
]

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

		if tile_type in SPAWN_TILES:
			spawn_positions.append(cell_pos)
		elif tile_type in DEST_TILES:
			destination_positions.append(cell_pos)
		elif tile_type in STOPLIGHT_TILES:
			stoplight_positions.append(cell_pos)

	print("Found %d spawn positions, %d destination positions, %d stoplights" % [spawn_positions.size(), destination_positions.size(), stoplight_positions.size()])

	# Emit signal so main scene can spawn stoplights
	if not stoplight_positions.is_empty():
		stoplight_tiles_found.emit(stoplight_positions)


## Get stoplight data for spawning stoplight entities
## Returns array of dictionaries with "position" key (world position)
func get_stoplight_data() -> Array:
	var data: Array = []
	for grid_pos in stoplight_positions:
		var world_pos = Vector2(
			grid_pos.x * TILE_SIZE + HALF_TILE,
			grid_pos.y * TILE_SIZE + HALF_TILE
		)
		data.append({
			"position": world_pos,
			"grid_pos": grid_pos,
			"tile_type": get_tile_type_at(grid_pos)
		})
	return data


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


## Get the TileType at a grid position
func get_tile_type_at(grid_pos: Vector2i) -> TileType:
	var atlas_coords = get_cell_atlas_coords(grid_pos)
	if atlas_coords == Vector2i(-1, -1):
		return TileType.NONE
	return TILE_COORDS_TO_TYPE.get(atlas_coords, TileType.NONE)


## Get connections for a tile at grid position
func get_connections_at(grid_pos: Vector2i) -> Array:
	var tile_type = get_tile_type_at(grid_pos)
	return TILE_ROAD_CONNECTIONS.get(tile_type, [])


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
func get_spawn_data() -> Array:
	var spawn_data: Array = []

	for spawn_pos in spawn_positions:
		var tile_type = get_tile_type_at(spawn_pos)
		var world_pos = map_to_local(spawn_pos)
		var data = {}

		data["group"] = get_tile_group(tile_type)
		data["group_name"] = get_group_name(data["group"])
		data["position"] = world_pos
		data["grid_pos"] = spawn_pos

		# Use SPAWN_FACING_DIRECTION for the facing direction
		# This is separate from road connections because spawn tiles may have multiple connections
		var facing_dir = SPAWN_FACING_DIRECTION.get(tile_type, "")

		# Fallback to first road connection if not in SPAWN_FACING_DIRECTION
		if facing_dir == "":
			var connections = TILE_ROAD_CONNECTIONS.get(tile_type, [])
			if connections.size() > 0:
				facing_dir = connections[0]

		# Set direction, rotation, and entry_dir based on facing direction
		match facing_dir:
			"top":
				data["direction"] = Vector2.UP
				data["rotation"] = 0.0
				data["entry_dir"] = "bottom"
			"bottom":
				data["direction"] = Vector2.DOWN
				data["rotation"] = PI
				data["entry_dir"] = "top"
			"left":
				data["direction"] = Vector2.LEFT
				data["rotation"] = -PI / 2
				data["entry_dir"] = "right"
			"right":
				data["direction"] = Vector2.RIGHT
				data["rotation"] = PI / 2
				data["entry_dir"] = "left"
			_:
				# Default to facing down if no direction found
				data["direction"] = Vector2.DOWN
				data["rotation"] = PI
				data["entry_dir"] = "top"

		spawn_data.append(data)

	return spawn_data


## Get destination positions with their entry direction
func get_destination_data() -> Array:
	var dest_data: Array = []

	for dest_pos in destination_positions:
		var tile_type = get_tile_type_at(dest_pos)
		var world_pos = map_to_local(dest_pos)
		var data = {}

		data["group"] = get_tile_group(tile_type)
		data["group_name"] = get_group_name(data["group"])

		# Determine entry direction based on tile connections
		var connections = TILE_ROAD_CONNECTIONS.get(tile_type, [])
		if connections.size() > 0:
			var road_dir = connections[0]  # The road connection direction
			# Entry direction is where the car comes from (opposite of road connection)
			data["entry_dir"] = get_opposite_direction(road_dir)

		data["position"] = world_pos
		data["grid_pos"] = dest_pos
		dest_data.append(data)

	return dest_data


## Get the guideline path for traversing a tile from entry to exit
func get_guideline_path(grid_pos: Vector2i, entry_dir: String, exit_dir: String) -> Array:
	var cache_key = "%s_%s_%s" % [grid_pos, entry_dir, exit_dir]
	if _cached_paths.has(cache_key):
		return _cached_paths[cache_key]

	var path = _calculate_path_waypoints(grid_pos, entry_dir, exit_dir)
	_cached_paths[cache_key] = path
	return path


## Calculate waypoint path from entry to exit direction
func _calculate_path_waypoints(grid_pos: Vector2i, entry_dir: String, exit_dir: String) -> Array:
	var points: Array = []
	var tile_center = Vector2(map_to_local(grid_pos))

	var exit_point = _get_edge_center(exit_dir, tile_center)
	points.append(exit_point)

	return points


## Get the center of an edge
func _get_edge_center(dir: String, tile_center: Vector2) -> Vector2:
	match dir:
		"top": return tile_center + Vector2(0, -HALF_TILE)
		"bottom": return tile_center + Vector2(0, HALF_TILE)
		"left": return tile_center + Vector2(-HALF_TILE, 0)
		"right": return tile_center + Vector2(HALF_TILE, 0)
	return tile_center


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


## Check if the tile at grid_pos is a spawn tile
func is_spawn_tile(grid_pos: Vector2i) -> bool:
	var tile_type = get_tile_type_at(grid_pos)
	return tile_type in SPAWN_TILES


## Check if the tile at grid_pos is a destination tile
func is_destination_tile(grid_pos: Vector2i) -> bool:
	var tile_type = get_tile_type_at(grid_pos)
	return tile_type in DEST_TILES


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
