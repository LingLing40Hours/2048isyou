extends State

var fade_speed:float = 0.05;
var duang_modulate:float = 0.2;
var duang_start_angle:float = 1;
var duang_factor:float = 1/sin(duang_start_angle);
var duang_curr_angle:float;
var duang_end_angle:float = PI - duang_start_angle;
var duang_speed:float = 0.07;
var changed:bool;


func enter():
	#update power and texture
	actor.power += 1;
	actor.update_texture(actor.new_img, actor.power, actor.is_player);
	actor.new_img.modulate.a = 0;
	actor.new_img.scale = Vector2.ONE;
	
	#set duang parameters
	duang_curr_angle = duang_start_angle;

func inPhysicsProcess(delta):
	#fade out img, fade in new img, do scaling animation
	changed = false;
	if actor.new_img.modulate.a < 1:
		actor.img.modulate.a = max(0, actor.img.modulate.a-fade_speed);
		actor.new_img.modulate.a = min(1, actor.new_img.modulate.a+fade_speed);
		changed = true;
	if actor.new_img.modulate.a >= duang_modulate and duang_curr_angle < duang_end_angle: #do duang
		actor.img.scale = Vector2.ONE * duang_factor * sin(duang_curr_angle);
		actor.new_img.scale = actor.img.scale;
		duang_curr_angle += duang_speed;
		changed = true;
	if not changed:
		actor.swap(actor.img, actor.new_img);
		actor.img.scale = Vector2.ONE;

func changeParentState():
	if not changed:
		if actor.is_player:
			if GV.player_snap:
				return states.snap;
			return states.slide;
		return states.tile;
	return null;

