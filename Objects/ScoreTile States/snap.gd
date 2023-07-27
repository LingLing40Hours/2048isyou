extends State

var next_state:Node2D;


func enter():
	next_state = null;
	
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2.ZERO;

	#snap
	actor.snap_range(GV.PLAYER_SNAP_RANGE);
	
	#do premove (if premoved)
	if actor.next_move.is_valid():
		actor.next_move.call(actor.next_dir);
		actor.next_move = Callable();
	
func handleInput(_event):
	if next_state != null or GV.changing_level:
		return;
	
	actor.get_next_action();
	if actor.next_move.is_valid():
		actor.next_move.call(actor.next_dir);
		actor.next_move = Callable();

func changeParentState():
	return next_state;
