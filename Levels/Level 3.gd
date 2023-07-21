extends Level


func _ready():
	#unlock move mode switching
	GV.abilities["move_mode"] = true;
	#show ui popup
