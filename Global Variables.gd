extends Node

var rng = RandomNumberGenerator.new();

var TILE_WIDTH:float = 40; #px
var RESOLUTION:Vector2 = Vector2(1600, 1200);
var RESOLUTION_T:Vector2 = RESOLUTION/TILE_WIDTH;

var LEVEL_COUNT:int = 7;
var current_level_index:int = 6;
var level_scores = [];

const PLAYER_MU:float = 0.16; #coefficient of friction
const PLAYER_SLIDE_SPEED:float = 33;
const PLAYER_SLIDE_SPEED_MIN:float = 8;
const PLAYER_SNAP_SPEED:float = 150;
const TILE_SLIDE_SPEED:float = 360;
const COMBINE_MERGE_RATIO:float = 1/2.4;

var player_snap:bool = true;
var focus_dir:int = 0; #-1 for x, 1 for y, 0 for neither


func _ready():
	rng.randomize();
	
	level_scores.resize(LEVEL_COUNT);
	level_scores.fill(0);

func _physics_process(delta):
	#releasing direction key loses focus
	if focus_dir == -1 and (Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right")):
		focus_dir = 0;
	elif focus_dir == 1 and (Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down")):
		focus_dir = 0;
	
	#pressing direction key sets focus
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		focus_dir = -1;
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		focus_dir = 1;
