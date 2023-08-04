extends Level


func on_home():
	pass; #already home

func _on_unlocker_body_entered(body):
	if body.is_in_group("player"):
		GV.abilities["restart"] = true;
