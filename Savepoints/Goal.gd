class_name Goal
extends SavePoint

@onready var tile_centers = $TileCenters;
@export var to_level:int = 0;


func init_spawn_point():
	pass;

func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level:
		save_id_and_player_value(body);
		
		#convert other players to tiles to prepare for save
		for player in game.current_level.players:
			player.is_player = false;
		
		#save level
		game.save_level(-1);
		
		#change level
		GV.changing_level = true;
		GV.reverting = false;
		game.change_level_faded(to_level);

		#save level after cleanup work after overlayer turns black

func spawn_player(): #spawns player at spawn_point
	print(id, " SPAWN PLAYER");
	spawned = true;
	var player = score_tile.instantiate();
	player_spawned = player;
	player.is_player = true;
	player.power = GV.player_power;
	player.ssign = GV.player_ssign;
	player.position = spawn_point;
	#player.debug = true;
	game.current_level.get_node("ScoreTiles").add_child(player); #lv not ready yet, scoretiles not init

func save_id_and_player_value(player):
	GV.savepoint_id = id;
	GV.level_last_savepoint_ids[GV.current_level_index] = id;
	game.current_level.player_saved = player;
	GV.player_power = player.power;
	GV.player_ssign = player.ssign;
