extends State

var next_state:Node2D;
@onready var game:Node2D = $"/root/Game";


func enter():
	next_state = null;
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2i.ZERO;

	#snap
	actor.snap_range(GV.PLAYER_SNAP_RANGE);
	
	#emit signal (after slide_dir reset)
	actor.enter_snap.emit(get_parent().prevState);

func inPhysicsProcess(_delta):
	actor.try_premove();

func handleInput(event):
	var accelerate:bool = (game.current_level.last_input_move == "");
	if actor.color == GV.ColorId.GRAY and game.current_level.update_last_input(event):
		actor.add_premove(false, accelerate);

func changeParentState():
	return next_state;
