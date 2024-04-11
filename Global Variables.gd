extends Node

const UINT8_MAX  = (1 << 8)  - 1 # 255
const UINT16_MAX = (1 << 16) - 1 # 65535
const UINT32_MAX = (1 << 32) - 1 # 4294967295

const INT8_MIN  = -(1 << 7)  # -128
const INT16_MIN = -(1 << 15) # -32768
const INT32_MIN = -(1 << 31) # -2147483648
const INT64_MIN = -(1 << 63) # -9223372036854775808

const INT8_MAX  = (1 << 7)  - 1 # 127
const INT16_MAX = (1 << 15) - 1 # 32767
const INT32_MAX = (1 << 31) - 1 # 2147483647
const INT64_MAX = (1 << 63) - 1 # 9223372036854775807

var factorials:Array[int] = [1];
var combinations:Array[Array] = [[1]];

#size-related stuff
const TILE_WIDTH:float = 40; #px
const RESOLUTION:Vector2 = Vector2(1600, 1200);
const RESOLUTION_T:Vector2i = Vector2i(RESOLUTION/TILE_WIDTH);
const BORDER_DISTANCE_T:int = 12; #128; #2000000000;
const BORDER_MIN_POS_T:Vector2i = -Vector2i(BORDER_DISTANCE_T, BORDER_DISTANCE_T);
const BORDER_MAX_POS_T:Vector2i = Vector2i(BORDER_DISTANCE_T, BORDER_DISTANCE_T);
const WORLD_MIN_POS_T:Vector2i = BORDER_MIN_POS_T + Vector2i.ONE; #leave gap for border cell
const WORLD_MAX_POS_T:Vector2i = BORDER_MAX_POS_T - Vector2i.ONE;

#level-related stuff
const LEVEL_COUNT:int = 15;
var current_level_index:int = 7;
var current_level_from_save:bool = false;
var level_scores = [];
var changing_level:bool = false;
var reverting:bool = false; #if true, fade faster and don't show lv name
#var through_goal:bool = false; #changing level via goal

#procgen-related stuff
const TILE_POW_MAX:int = 14;
const TILE_GEN_POW_MAX:int = 11;
const TILE_VALUE_COUNT:int = 2 * TILE_POW_MAX + 3;
const TILE_LOAD_BUFFER:float = 8 * TILE_WIDTH;
const TILE_UNLOAD_BUFFER:float = 8 * TILE_WIDTH;

#pathfinder-related stuff
#var level_hash_numbers:Array = [];
#var x_hash_numbers:Array = [];
#var y_hash_numbers:Array = [];

#save-related stuff
#note non-export variables are not saved in packed scene
const PLAYER_SNAPSHOT_BADDIE_RANGE:float = 448;
var savepoint_id:int = -1; #id of savepoint at which player will spawn (after lv change)
var player_power:int; #saved for instantiation at dest goal
var player_ssign:int;
var current_savepoint_ids = []; #ids of saved savepoints
var current_savepoint_saves = []; #packed scene of level (at saved savepoints)
var current_snapshot_sizes = []; #size of player_snapshots (at saved savepoints)
var temp_player_snapshots = []; #keep player snapshots when reverting
var current_savepoint_powers = [];
var current_savepoint_ssigns = [];
var temp_player_snapshot_locations = []; #to reinstate after player spawns
var temp_player_snapshot_locations_new = [];
var current_savepoint_tiles_snapshot_locations = []; #2d array of array refs
var current_savepoint_tiles_snapshot_locations_new = [];
var current_savepoint_baddies_snapshot_locations = [];

var level_last_savepoint_ids:Array[int] = []; #in lv0, for spawning player after "home"
var level_initial_savepoint_ids:Array[int] = []; #id of goal where player first enters level
var level_initial_player_powers:Array[int] = [];
var level_initial_player_ssigns:Array[int] = [];

const FADER_SPEED_SCALE_MAJOR:float = 1;
const FADER_SPEED_SCALE_MINOR:float = 1.2;
const LEVEL_NAME_FADE_IN_TIME:float = 1.6;
const LEVEL_NAME_DISPLAY_TIME:float = 3;
const LEVEL_NAME_FADE_OUT_TIME:float = 1.2;

const TRACKING_CAM_LEAD_RATIO:float = 1.35; #target = pos + ratio * (track_pos - pos)
const TRACKING_CAM_SLACK_RATIO:float = 0.15; #0.25; #ratio applied to slack (tracking movement along the non-trigger axis)
const TRACKING_CAM_TRANSITION_TIME:float = 1.28;
const PLAYER_SPAWN_INVINCIBILITY_TIME:float = 0.25;

const PLAYER_COLLIDER_SCALE:float = 0.98;
const PLAYER_SNAP_RANGE:float = TILE_WIDTH * (1 - PLAYER_COLLIDER_SCALE);
const PLAYER_MU:float = 0.16; #coefficient of friction
const PLAYER_SLIDE_SPEED:float = 33;
const PLAYER_SLIDE_SPEED_MIN:float = 8;
const PLAYER_SPEED_RATIO:float = 0.9; #must be less than 1 so tile solidifies before premove
const TILE_SLIDE_SPEED:float = 320;
const COMBINING_MERGE_RATIO:float = 1/2.7;

const COMBINING_FRAME_COUNT:int = 6; #9; #1;
const SPLITTING_FRAME_COUNT:int = 6; #9; #1;

const MOVE_REPEAT_DELAY_F0:int = 16;
const MOVE_REPEAT_DELAY_DF:int = -1;
const MOVE_REPEAT_DELAY_DDF:int = -1;
const MOVE_REPEAT_DELAY_FMIN:int = 10;

const UNDO_REPEAT_DELAY_F0:int = 20;
const UNDO_REPEAT_DELAY_DF:int = -1;
const UNDO_REPEAT_DELAY_DDF:int = -1;
const UNDO_REPEAT_DELAY_FMIN:int = 14;

enum InputType {
	MOVE=0,
	UNDO
}

enum ScaleAnim {
	DUANG=0,
	DWING
};

const DUANG_START_MODULATE:float = 0; #0.2;
const DUANG_START_ANGLE:float = 1;
const DUANG_FACTOR:float = 1/sin(DUANG_START_ANGLE);
const DUANG_END_ANGLE:float = PI - DUANG_START_ANGLE;
const DUANG_SPEED:float = 0.1;
const DUANG_FADE_SPEED:float = 0.07;

const FADE_START_ANGLE:float = 1;
const DWING_START_ANGLE:float = 1;
const DWING_FACTOR:float = sin(DWING_START_ANGLE);
const DWING_END_ANGLE:float = PI - DWING_START_ANGLE;
const DWING_SPEED:float = 0.1;
const DWING_FADE_SPEED:float = 0.07;

const SHIFT_RAY_LENGTH:float = RESOLUTION.x;
const SHIFT_TIME:float = 6; #in frames
const SHIFT_LERP_WEIGHT:float = 0.6;
var SHIFT_LERP_WEIGHT_TOTAL:float = 0;
var SHIFT_DISTANCE_TO_MAX_SPEED:float;

var player_snap:bool = true; #move mode

const directions = {
	"left" : Vector2i(-1, 0),
	"right" : Vector2i(1, 0),
	"up" : Vector2i(0, -1),
	"down" : Vector2i(0, 1),
};

var abilities = {
	"home" : true,
	"restart" : true,
	"move_mode" : true,
	"undo" : true,
	"revert" : true,
	#"merge" : true,
	"split" : true,
	"shift" : true,
	"copy" : true,
	"tile_push_limit" : 3,
};

enum TileId { #5 bits
	EMPTY = 0,
	ZERO = 16,
};

enum TypeId { #3 bits
	PLAYER = 0,
	INVINCIBLE,
	HOSTILE,
	REGULAR,
	VOID,
}

enum BackId { #8 bits
	EMPTY = 0,
	BORDER_ROUND,
	BORDER_SQUARE,
	MEMBRANE,
	BLACK_WALL,
	BLUE_WALL,
	RED_WALL,
	SAVEPOINT,
	GOAL,
}

enum LayerId {
	BACK,
	TILE
}

enum ColorId {
	ALL = 4,
	RED = 29,
	BLUE = 30,
	BLACK = 31,
	GRAY = 32,
};

#const PHYSICS_ENABLER_SHAPE:RectangleShape2D = preload("res://Objects/PhysicsEnablerShape.tres");
#const PHYSICS_ENABLER_BASE_SIZE:Vector2 = Vector2(144, 144); #px, px; at tile_push_limit = 0


func _ready():
	level_scores.resize(LEVEL_COUNT);
	level_scores.fill(0);
	level_last_savepoint_ids.resize(LEVEL_COUNT);
	level_last_savepoint_ids.fill(-1);
	level_initial_savepoint_ids.resize(LEVEL_COUNT);
	level_initial_player_powers.resize(LEVEL_COUNT);
	level_initial_player_ssigns.resize(LEVEL_COUNT);
	
	#calculate shift parameter
	for frame in range(1, SHIFT_TIME+1):
		var term_sign = 1;
		for term in range(1, frame+1):
			SHIFT_LERP_WEIGHT_TOTAL += term_sign * combinations_dp(frame, term) * pow(SHIFT_LERP_WEIGHT, term);
			term_sign *= -1;
	SHIFT_DISTANCE_TO_MAX_SPEED = 60 / SHIFT_LERP_WEIGHT_TOTAL;
	
#	#init physics enabler size
#	set_tile_push_limit(abilities["tile_push_limit"]);
#
#	#scale shapecasts (bc inspector can't handle precise floats)
#	var shape_LR:RectangleShape2D = preload("res://Objects/ShapeCastShapeLR.tres");
#	var shape_UD:RectangleShape2D = preload("res://Objects/ShapeCastShapeUD.tres");
#	shape_LR.size.y *= GV.PLAYER_COLLIDER_SCALE;
#	shape_UD.size.x *= GV.PLAYER_COLLIDER_SCALE;

func same_sign_inclusive(a, b) -> bool:
	if a == 0:
		return true;
	if a > 0:
		return b >= 0;
	return b <= 0;

func same_sign_exclusive(a, b) -> bool:
	if a == 0:
		return false;
	if a > 0:
		return b > 0;
	return b < 0;
		
func factorial(n) -> int:
	if factorials.size() > n:
		return factorials[n];
	
	var ans = factorials[factorials.size() - 1];
	for i in range(factorials.size(), n+1):
		ans *= i;
		factorials.push_back(ans);
	return ans;

func combinations_gen(n, k) -> int:
	if n < k:
		return 0;
	if n == k:
		return 1;
	@warning_ignore("integer_division")
	return factorial(n)/factorial(k)/factorial(n-k);

func combinations_dp(n, k) -> int:
	#range check
	if n < 0 or k < 0 or k > n:
		return 0;
	
	#query stored answers
	if combinations.size() > n:
		if combinations[n][k] != -1:
			return combinations[n][k];
	else:
		#expand combinations
		for i in range(combinations.size(), n+1):
			var row = [];
			row.resize(i+1);
			row.fill(-1);
			combinations.push_back(row);
	
	#recursion
	var ans = 1 if (k == 0 or k == n) else (combinations_dp(n-1, k) + combinations_dp(n-1, k-1));
	combinations[n][k] = ans;
	return ans;

func world_to_pos_t(pos:Vector2) -> Vector2i:
	return (pos / TILE_WIDTH).floor();

func pos_t_to_world(pos_t:Vector2i) -> Vector2:
	return (Vector2(pos_t) + Vector2(0.5, 0.5)) * TILE_WIDTH;

func world_to_xt(x:float) -> int:
	return floori(x / TILE_WIDTH);

func xt_to_world(x:int) -> float:
	return (x + 0.5) * TILE_WIDTH;

#doesn't do ZERO->EMPTY optimization
func tile_val_to_id(power:int, ssign:int) -> int:
	if power == -1: #zero
		return TileId.ZERO;
	return (power + 1) * ssign + TileId.ZERO;

func id_to_tile_val(id:int):
	if id == TileId.ZERO:
		return [-1, 1];
	var signed_incremented_pow:int = id - TileId.ZERO;
	return [absi(signed_incremented_pow) - 1, signi(signed_incremented_pow)];

func is_approx_equal(a:float, b:float, tolerance:float) -> bool:
	if absf(a - b) <= tolerance:
		return true;
	return false;

#func set_tile_push_limit(_tile_push_limit):
#	abilities["tile_push_limit"] = _tile_push_limit;
#
#	#change physicsEnabler size
#	var size:Vector2 = PHYSICS_ENABLER_BASE_SIZE + abilities["tile_push_limit"] * 2 * GV.TILE_WIDTH * Vector2.ONE;
#	PHYSICS_ENABLER_SHAPE.set_size(size);
