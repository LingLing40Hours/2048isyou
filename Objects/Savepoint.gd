extends Area2D

@onready var game:Node2D = $"/root/Game";


func _on_body_entered(body):
	if body.is_in_group("player"):
		game.save_level();
