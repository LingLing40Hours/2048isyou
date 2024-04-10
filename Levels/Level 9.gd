extends Level


func set_level_name():
	if GV.savepoint_id % 2:
		game.current_level_name = $DownIsUp;
	else:
		game.current_level_name = $UpIsDown;
	game.current_level_name.modulate.a = 0;
