class_name PlayerSnapshot
extends Node
#used to store an undoable player action
#player/tile position/value before push/merge/split
#baddie position and velocity (if knocked?)
#don't save snapshots for player sliding by itself

#only allow undo when not changing level
#upon die(), revert to last savepoint

var baddie_positions:Array[Vector2] = [];
var baddie_velocities:Array[Vector2] = [];
var player_position:Vector2;
var tile_position:Vector2;


func _init(player_pos, tile_pos):
	player_position = player_pos;
	tile_position = tile_pos;

func undo():
	pass;

func redo():
	pass;
