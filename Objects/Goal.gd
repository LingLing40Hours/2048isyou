extends Area2D

@onready var game:Node2D = $"/root/Game";
@export var to_level:int = 0;
@export var spawn_point:Vector2 = Vector2.ZERO;


func _on_body_entered(body):
	if body.is_in_group("player") and not GV.changing_level:
		GV.changing_level = true;
		GV.spawn_point = spawn_point;
		game.change_level_faded(to_level);
