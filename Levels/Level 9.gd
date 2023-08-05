extends Level


func set_level_name():
	if GV.savepoint_id % 2:
		game.current_level_name = $Background/DownIsUp;
	else:
		game.current_level_name = $Background/UpIsDown;
