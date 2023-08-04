class_name SavePoint
extends Area2D

@onready var game:Node2D = $"/root/Game";


func _ready():
	connect("body_entered", _on_body_entered);

func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level: #save level
		game.save_level();
