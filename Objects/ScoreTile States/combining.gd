extends State

var frame_count:int;


func enter():
	#print("COMBINING");
	#reset frame count
	frame_count = 0;
	
	#start animation
	var animator = ScoreTileAnimator.new(actor.power, actor.ssign, GV.ScaleAnim.DUANG, 4, 3);
	actor.add_child(animator);

func inPhysicsProcess(_delta):
	frame_count += 1;

func handleInput(_event):
	if actor.next_move.is_null(): #check for premove
		actor.get_next_action();

func changeParentState():
	if frame_count == GV.COMBINING_FRAME_COUNT:
		if actor.is_player:
			if GV.player_snap:
				return states.snap;
			return states.slide;
		return states.tile;
	return null;

func exit():
	actor.partner = null;
