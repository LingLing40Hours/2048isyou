extends Node

var rng = RandomNumberGenerator.new();

var TILE_WIDTH:float = 40; #px
var RESOLUTION:Vector2 = Vector2(1600, 1200);
var RESOLUTION_T:Vector2 = RESOLUTION/TILE_WIDTH;

var LEVEL_COUNT:int = 7;
var current_level_index:int = 0;
var level_scores = [];
var changing_level:bool = false;
var spawn_point:Vector2 = Vector2(80, 160);

const LEVEL_NAME_FADE_IN_TIME:float = 1.6;
const LEVEL_NAME_DISPLAY_TIME:float = 3;
const LEVEL_NAME_FADE_OUT_TIME:float = 1.2;

const PLAYER_COLLIDER_SCALE:float = 0.98;
const PLAYER_MU:float = 0.16; #coefficient of friction
const PLAYER_SLIDE_SPEED:float = 33;
const PLAYER_SLIDE_SPEED_MIN:float = 8;
const PLAYER_SPEED_RATIO:float = 3/4.0;
const TILE_SLIDE_SPEED:float = 360;
const COMBINE_MERGE_RATIO:float = 1/2.4;

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

var player_snap:bool = true;

var abilities = {
	"home" : true,
	"restart" : true,
	"move_mode" : true,
	"undo" : true,
	"split" : true,
};


func _ready():
	rng.randomize();
	
	level_scores.resize(LEVEL_COUNT);
	level_scores.fill(0);


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
		
