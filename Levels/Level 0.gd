extends Level


func _input(event):
	if not GV.changing_level:
		if event.is_action_pressed("home"):
			pass;
		elif event.is_action_pressed("restart"):
			if GV.abilities["restart"]:
				GV.changing_level = true;
				game.change_level_faded(GV.current_level_index);
