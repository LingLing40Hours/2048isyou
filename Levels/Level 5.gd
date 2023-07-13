extends Node2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";
@onready var score_tiles:Node2D = $ScoreTiles;


func _ready():
	for score_tile in score_tiles.get_children():
		score_tile.power = GV.rng.randi_range(1, 11);
		score_tile.update_texture(score_tile.img);
	
func _input(event):
	if event.is_action_pressed("ui_home"):
		game.change_level_faded(0);
	elif event.is_action_pressed("ui_restart"):
		game.change_level_faded(GV.current_level_index);
