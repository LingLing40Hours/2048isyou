extends State

var duang_curr_angle:float;
var duang_speed:float;
var fade_speed:float;
var changed:bool;


func enter():
	#update power and texture
	actor.power += 1;
	actor.update_texture(actor.new_img, actor.power, actor.is_player);
	actor.new_img.modulate.a = 0;
	actor.new_img.scale = Vector2.ONE;
	
	#set duang parameters
	duang_curr_angle = GV.DUANG_START_ANGLE;
	duang_speed = GV.DUANG_SPEED;
	fade_speed = GV.FADE_SPEED;
	
	#set z_index
	actor.img.z_index = 2;
	actor.new_img.z_index = 1;

func inPhysicsProcess(delta):
	#fade out img, fade in new img, do scaling animation
	changed = false;
	if actor.new_img.modulate.a < 1:
		actor.img.modulate.a = max(0, actor.img.modulate.a-fade_speed);
		actor.new_img.modulate.a = 1 - actor.img.modulate.a;
		changed = true;
	if actor.new_img.modulate.a >= GV.DUANG_MODULATE and duang_curr_angle < GV.DUANG_END_ANGLE: #do duang
		actor.img.scale = Vector2.ONE * GV.DUANG_FACTOR * sin(duang_curr_angle);
		actor.new_img.scale = actor.img.scale;
		duang_curr_angle += duang_speed;
		changed = true;

func changeParentState():
	if not changed:
		if actor.is_player:
			if GV.player_snap:
				return states.snap;
			return states.slide;
		return states.tile;
	return null;

func exit():
	actor.img.scale = Vector2.ONE;
	actor.new_img.scale = Vector2.ONE;
	actor.new_img.z_index = 0;

	#swap
	var temp = actor.img;
	actor.img = actor.new_img;
	actor.new_img = temp;
