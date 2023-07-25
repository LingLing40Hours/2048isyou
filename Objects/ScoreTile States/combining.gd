extends State

var frame_count:int;


func enter():
	#update power and texture
	actor.power += 1;
	actor.update_texture(actor.new_img, actor.power, actor.is_player);
	actor.new_img.modulate.a = 0;
	
	#set duang parameters
	frame_count = 0;
	duang_curr_angle = GV.DUANG_START_ANGLE;
	duang_speed = GV.DUANG_SPEED;
	fade_speed = GV.DUANG_FADE_SPEED;
	
	#set z_index
	actor.img.z_index = 4;
	actor.new_img.z_index = 3;

func inPhysicsProcess(delta):
	frame_count += 1;

func handleInput(event):
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
	actor.img.z_index = 0;
	actor.new_img.z_index = 0;

	#swap
	var temp = actor.img;
	actor.img = actor.new_img;
	actor.new_img = temp;
