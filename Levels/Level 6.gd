extends Level


func _on_unlocker_body_entered(body):
	if body.is_in_group("player"):
		GV.abilities["undo"] = true;
