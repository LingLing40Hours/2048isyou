extends State

var frame_count:int;
@onready var game:Node2D = $"/root/Game";


func enter():
	frame_count = 0;
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2i.ZERO;

	#snap to grid
	actor.snap_range(GV.PLAYER_SNAP_RANGE);

func inPhysicsProcess(_delta):
	frame_count += 1;

func handleInput(event):
	if actor.color == GV.ColorId.GRAY and game.current_level.update_last_input(event):
		actor.add_premove();

func changeParentState():
	if frame_count == GV.SNAP_FRAME_COUNT:
		return states.idle;
	return null;
