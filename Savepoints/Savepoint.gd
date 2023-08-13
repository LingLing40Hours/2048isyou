class_name SavePoint
extends Area2D

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");
var spawned:bool = false;
@export var saved:bool = false;

@export var id:int = 0; #unique id for each savepoint, except connected goals' ids must match
@export var spawn_point:Vector2;
@onready var game:Node2D = $"/root/Game";


func _ready():
	init_spawn_point();
	connect("body_entered", _on_body_entered);
	connect("body_exited", _on_body_exited);
	
	if id == GV.savepoint_id:
		spawn_player();
	elif GV.savepoint_id == -1 and id == GV.level_last_savepoint_ids[GV.current_level_index]:
		spawn_player();

func init_spawn_point():
	spawn_point = position;

func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level and not saved and not spawned: #save level
		game.current_level.current_snapshot.enter_savepoint = true;
		#game.current_level.remove_last_snapshot_if_not_meaningful();
		save_id_and_player_value(body);
		
		game.save_level(id);
		saved = true;

func _on_body_exited(body):
	#check position to ensure body wasn't freed in add_level
	if body.is_in_group("player") and body.position != position and not GV.changing_level and not saved and spawned: #save level
		game.current_level.remove_last_snapshot_if_not_meaningful();
		save_id_and_player_value(body);
		
		game.save_level(id);
		saved = true;

func spawn_player(): #spawns player at spawn_point
	#print("SPAWN PLAYER AT SAVEPOINT ", id);
	spawned = true;
	var player = score_tile.instantiate();
	player.is_player = true;
	player.power = GV.current_savepoint_powers.pop_back();
	player.ssign = GV.current_savepoint_ssigns.pop_back();
	player.snapshot_locations = GV.current_savepoint_snapshot_locations.pop_back().duplicate();
	player.snapshot_locations_new = GV.current_savepoint_snapshot_locations_new.pop_back().duplicate();
	#update ref in last snapshot location(s)
	if player.snapshot_locations:
		var location = player.snapshot_locations.back();
		game.current_level.player_snapshots[location.x].tiles[location.y] = player;
	if player.snapshot_locations_new:
		var location_new = player.snapshot_locations_new.back();
		game.current_level.player_snapshots[location_new.x].tiles_new[location_new.y] = player;
	player.position = spawn_point;
	#player.debug = true;
	game.current_level.get_node("ScoreTiles").add_child(player); #lv not ready yet, scoretiles not init

func save_id_and_player_value(player):
	GV.savepoint_id = id;
	GV.level_last_savepoint_ids[GV.current_level_index] = id;
	game.current_level.player_saved = player;
	GV.current_savepoint_ids.push_back(id);
	#current_savepoint_saves gets save in game.save_level()
	GV.current_snapshot_sizes.push_back(game.current_level.player_snapshots.size());
	GV.current_savepoint_powers.push_back(player.power);
	GV.current_savepoint_ssigns.push_back(player.ssign);
	GV.current_savepoint_snapshot_locations.push_back(player.snapshot_locations.duplicate());
	GV.current_savepoint_snapshot_locations_new.push_back(player.snapshot_locations_new.duplicate());
