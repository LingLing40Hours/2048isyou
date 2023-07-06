extends Node

var LEVEL_COUNT:int = 5;
var current_level_index:int = 4;
var level_scores = [];

var PLAYER_MU:float = 0.16; #coefficient of friction
var PLAYER_SPEED:float = 33;
var PLAYER_SPEED_MIN:float = 8;
var TILE_WIDTH:float = 40; #px


func _ready():
	level_scores.resize(LEVEL_COUNT);
	level_scores.fill(0);
