extends Level


func on_home():
	pass; #already home


func _on_restart_unlocker_body_entered(body):
	if body.is_in_group("player"):
		GV.abilities["restart"] = true;

func _on_shift_unlocker_body_entered(body):
	if body.is_in_group("player"):
		GV.abilities["shift"] = true;

func _on_revert_unlocker_body_entered(body):
	if body.is_in_group("player"):
		GV.abilities["revert"] = true;
