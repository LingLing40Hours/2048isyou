extends Control

@onready var game:Node2D = $"/root/Game";

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	game.toggle_game_paused.connect(_on_game_toggle_game_paused)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_game_toggle_game_paused(is_paused : bool):
	if (is_paused):
		show()
	else:
		hide()


func _on_resume_button_pressed():
	game.game_paused = false


func _on_exit_button_2_pressed():
	get_tree().quit()
