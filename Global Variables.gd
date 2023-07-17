extends Node

var LEVEL_COUNT:int = 7;
var current_level_index:int = 6;
var level_scores = [];

var PLAYER_MU:float = 0.16; #coefficient of friction
var PLAYER_SPEED:float = 33;
var PLAYER_SPEED_MIN:float = 8;
var TILE_WIDTH:float = 40; #px
var player_snap:bool = true;

var rng = RandomNumberGenerator.new();


func _ready():
	level_scores.resize(LEVEL_COUNT);
	level_scores.fill(0);
	
	rng.randomize();
