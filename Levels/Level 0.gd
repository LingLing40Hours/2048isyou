extends Node2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";


func _input(event):
	if event.is_action_pressed("ui_home"):
		pass;
	elif event.is_action_pressed("ui_restart"):
		pass;


func _on_start_button_pressed():
	game.change_level_faded(GV.current_level_index+1);
