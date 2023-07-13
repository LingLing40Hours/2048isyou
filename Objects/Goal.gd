extends Area2D

@onready var game:Node2D = $"/root/Game";
@export var to_level:int = 0;


func _on_body_entered(body):
	if body.is_in_group("player"):
		game.change_level_faded(to_level);
