extends State

var next_state:Node2D;
@onready var game:Node2D = $"/root/Game";


func enter():
	next_state = null;
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2i.ZERO;

	#snap
	actor.snap_range(GV.PLAYER_SNAP_RANGE);

func inPhysicsProcess(_delta):
	actor.consume_premove();

func handleInput(event):
	if actor.color == GV.ColorId.GRAY and game.current_level.update_last_input(event):
		actor.add_premove();

func changeParentState():
	return next_state;
