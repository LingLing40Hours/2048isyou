extends SavePoint

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

func _on_body_exited(body):
	pass;
