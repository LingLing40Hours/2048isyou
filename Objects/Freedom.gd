extends Area2D


func _ready():
	connect("body_entered", _on_body_entered);

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.remove_from_players();
	body.queue_free();
