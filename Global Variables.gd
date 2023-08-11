extends Node

var rng = RandomNumberGenerator.new();
var factorials:Array[int] = [1];
var combinations:Array[Array] = [[1]];

var TILE_WIDTH:float = 40; #px
var RESOLUTION:Vector2 = Vector2(1600, 1200);
var RESOLUTION_T:Vector2 = RESOLUTION/TILE_WIDTH;

var LEVEL_COUNT:int = 12;
var current_level_index:int = 11;
var current_level_from_save:bool = false;
var level_scores = [];
var changing_level:bool = false;
var reverting:bool = false; #if true, fade faster and don't show lv name
#var through_goal:bool = false; #changing level via goal

#save-related stuff
#note non-export variables are not saved in packed scene
const PLAYER_SNAPSHOT_BADDIE_RANGE:float = 448;
var savepoint_id:int = -1; #id of savepoint at which player will spawn (after lv change)
var current_savepoints = []; #refs of saved savepoints
var current_savepoint_saves = []; #packed scene of level (at saved savepoints)
var current_snapshot_sizes = []; #size of player_snapshots (at saved savepoints)
var temp_player_snapshots = []; #keep player snapshots when reverting
var current_savepoint_powers = [];
var current_savepoint_ssigns = [];
var current_savepoint_snapshot_locations = []; #to reinstate after player spawns
var current_savepoint_snapshot_locations_new = [];

var level_last_savepoint_ids:Array[int] = []; #in lv0, for spawning player after "home"
var level_initial_savepoint_ids:Array[int] = []; #id of goal where player first enters level
var level_initial_player_powers:Array[int] = [];
var level_initial_player_ssigns:Array[int] = [];

const FADER_SPEED_SCALE_MAJOR:float = 1;
const FADER_SPEED_SCALE_MINOR:float = 1.2;
const LEVEL_NAME_FADE_IN_TIME:float = 1.6;
const LEVEL_NAME_DISPLAY_TIME:float = 3;
const LEVEL_NAME_FADE_OUT_TIME:float = 1.2;

const PLAYER_SPAWN_INVINCIBILITY_TIME:float = 0.25;
const PLAYER_COLLIDER_SCALE:float = 0.98;
var PLAYER_SNAP_RANGE:float = TILE_WIDTH * (1 - PLAYER_COLLIDER_SCALE);
const PLAYER_MU:float = 0.16; #coefficient of friction
const PLAYER_SLIDE_SPEED:float = 33;
const PLAYER_SLIDE_SPEED_MIN:float = 8;
const PLAYER_SPEED_RATIO:float = 0.9; #must be less than 1 so tile solidifies before premove
const TILE_SLIDE_SPEED:float = 320;
const COMBINING_MERGE_RATIO:float = 1/2.7;

const INPUT_REPEAT_DELAY:float = 0.1; #when movement held down, delay (s) between action calls

const COMBINING_FRAME_COUNT:int = 6; #9;
const SPLITTING_FRAME_COUNT:int = 6; #9;

enum ScaleAnim {
	DUANG=0,
	DWING
};

const DUANG_MODULATE:float = 0.2;
const DUANG_START_ANGLE:float = 1;
const DUANG_FACTOR:float = 1/sin(DUANG_START_ANGLE);
const DUANG_END_ANGLE:float = PI - DUANG_START_ANGLE;
const DUANG_SPEED:float = 0.07;
const DUANG_FADE_SPEED:float = 0.05;

const FADE_ANGLE:float = 1;
const DWING_START_ANGLE:float = 1;
const DWING_FACTOR:float = sin(DWING_START_ANGLE);
const DWING_END_ANGLE:float = PI - DWING_START_ANGLE;
const DWING_SPEED:float = 0.07;
const DWING_FADE_SPEED:float = 0.05;

var SHIFT_RAY_LENGTH:float = RESOLUTION.x;
const SHIFT_TIME:float = 6; #in frames
const SHIFT_LERP_WEIGHT:float = 0.6;
var SHIFT_LERP_WEIGHT_TOTAL:float = 0;
var SHIFT_DISTANCE_TO_SPEED_MAX:float;

var player_snap:bool = true; #move mode

var directions = {
	"left" : Vector2(-1, 0),
	"right" : Vector2(1, 0),
	"up" : Vector2(0, -1),
	"down" : Vector2(0, 1),
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
};

#stuff ids
enum StuffIds {
	ZERO = -20,
	NEG_ONE = -21,
	EMPTY = -22,
	SAVEPOINT = -23,
	GOAL = -24,
	BLACK_WALL = -40,
	MEMBRANE = -41,
	BLUE_WALL = -42,
	RED_WALL = -43,
};



func _ready():
	rng.randomize();
	
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
	SHIFT_DISTANCE_TO_SPEED_MAX = 60 / SHIFT_LERP_WEIGHT_TOTAL;


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
	return Vector2i(pos/TILE_WIDTH);
