extends State

var frame_count:int;


func enter():
	#reset frame count
	frame_count = 0;
	
	#update power
	if actor.power == -1:
		actor.power = actor.partner.power;
		actor.ssign = actor.partner.ssign;
	elif actor.partner.power == -1:
		pass;
	elif actor.partner.ssign == actor.ssign:
		actor.power += 1;
	else:
		actor.power = -1;
	print("POWER: ", actor.power);
	
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
