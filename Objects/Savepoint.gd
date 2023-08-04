class_name SavePoint
extends Area2D

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");

@export var id:int = 0; #unique id for each savepoint, except connected goals' ids must match
@export var spawn_point:Vector2;
@onready var game:Node2D = $"/root/Game";


func _ready():
	init_spawn_point();
	connect("body_entered", _on_body_entered);
	
	if id == GV.savepoint_id:
		spawn_player();
	elif GV.savepoint_id == -1 and id == GV.level_last_goal_ids[GV.current_level_index]:
		spawn_player();

func init_spawn_point():
	spawn_point = position;

func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level: #save level
		#save goal id
		GV.savepoint_id = id;
		
		game.save_level();

func spawn_player(): #spawns player at spawn_point
	print("SPAWN PLAYER");
	var player = score_tile.instantiate();
	player.is_player = true;
	player.power = GV.player_power;
	player.ssign = GV.player_ssign;
	player.position = spawn_point;
	#player.debug = true;
	game.current_level.get_node("ScoreTiles").add_child(player); #lv not ready yet, scoretiles not init
