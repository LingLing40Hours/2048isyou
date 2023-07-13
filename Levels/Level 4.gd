extends Node2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";


func _input(event):
	if event.is_action_pressed("ui_home"):
		game.change_level_faded(0);
	elif event.is_action_pressed("ui_restart"):
		game.change_level_faded(GV.current_level_index);
