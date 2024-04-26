extends State

var next_state:Node2D;
@onready var game:Node2D = $"/root/Game";


func enter():
	next_state = null;
	
	#subscribe to premoves
	actor.premove_added.connect(_on_premove_added);
	
	#check for premove
	if actor.premoves:
		actor.consume_premove();

func _on_premove_added():
	actor.consume_premove();

func handleInput(event):
	if actor.color == GV.ColorId.GRAY and game.current_level.update_last_input(event):
		actor.add_premove();

func changeParentState():
	return next_state;

func exit():
	#unsubscribe from premoves
	actor.premove_added.disconnect(_on_premove_added);
