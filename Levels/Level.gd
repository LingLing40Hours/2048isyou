class_name Level
extends Node2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";

var players = []; #if player, add here in _ready()


func _input(event):
	if not GV.changing_level:
		if event.is_action_pressed("home"):
			if GV.abilities["home"]:
				GV.changing_level = true;
				game.change_level_faded(0);
		elif event.is_action_pressed("restart"):
			if GV.abilities["restart"]:
				GV.changing_level = true;
				game.change_level_faded(GV.current_level_index);

func save():
	var save_dict = {
		
	};
