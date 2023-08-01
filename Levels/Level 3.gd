extends Level


func _on_unlocker_body_entered(body):
	if body.is_in_group("player"):
		GV.abilities["move_mode"] = true;
		#show ui popup?
