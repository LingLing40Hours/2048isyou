extends SavePoint

@export var to_level:int = 0;


func init_spawn_point():
	pass;

func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level:
		#save goal id and player value
		GV.savepoint_id = id;
		GV.level_last_savepoint_ids[GV.current_level_index] = id;
		game.current_level.player_saved = body;
		GV.player_power = body.power;
		GV.player_ssign = body.ssign;
		
		#change level
		GV.changing_level = true;
		GV.through_goal = true;
		game.change_level_faded(to_level);

		#save level after cleanup work after overlayer turns black

