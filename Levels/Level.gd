class_name Level
extends Node2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";

var players = []; #if player, add here in _ready()


func _input(event):
	if event.is_action_pressed("home"):
		game.change_level_faded(0);
	elif event.is_action_pressed("restart"):
		game.change_level_faded(GV.current_level_index);

