extends State

var next_state:Node2D;
@onready var game:Node2D = $"/root/Game";


func enter():
	next_state = null;
	
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2i.ZERO;

	#snap
	actor.snap_range(GV.PLAYER_SNAP_RANGE);
	
	#do premove (if premoved)
	if actor.next_moves:
		#var debug_dir = actor.next_dirs.front();
		
		var action = Callable(actor, actor.next_moves.front());
		var moved = action.call(actor.next_dirs.pop_front());
		if moved:
			actor.next_moves.pop_front(); #pop afterwards so call can check if it's a premove
		else: #move failed, clear all premoves
			#debug
			#print(actor.next_moves.front());
			#print(debug_dir);
			
			actor.next_moves.clear();
			actor.next_dirs.clear();
	
	#emit signal (after slide_dir reset)
	actor.enter_snap.emit(get_parent().prevState);
	
func handleInput(_event):
	if next_state != null or GV.changing_level:
		return;
	
	await game.current_level.processed_action_input;
	actor.get_next_action();
	if actor.next_moves:
		var action = Callable(actor, actor.next_moves.front());
		action.call(actor.next_dirs.pop_front());
		actor.next_moves.pop_front(); #pop afterwards so call can check if it's a premove

func changeParentState():
	return next_state;
