extends State

var frame_count:int;
@onready var game:Node2D = $"/root/Game";


func enter():
	#print("COMBINING");
	#reset frame count
	frame_count = 0;
	
	#start animation
	var animator = ScoreTileAnimator.new(actor.power, actor.ssign, GV.ScaleAnim.DUANG, 4, 3);
	actor.add_child(animator);
	
	#inherit partner's premoves
	if actor.color == GV.ColorId.GRAY:
		actor.premoves = actor.partner.premoves;
		actor.premove_dirs = actor.partner.premove_dirs;

func inPhysicsProcess(_delta):
	frame_count += 1;

func handleInput(event):
	if actor.color == GV.ColorId.GRAY and game.current_level.update_last_input(event):
		actor.add_premove();

func changeParentState():
	if frame_count == GV.COMBINING_FRAME_COUNT:
		if actor.color == GV.ColorId.GRAY:
			if GV.player_snap:
				return states.snap;
			return states.slide;
		return states.tile;
	return null;

func exit():
	actor.partner = null;
