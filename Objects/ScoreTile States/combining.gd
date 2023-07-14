extends State


var changed;


func inPhysicsProcess(delta):
	#fade out img, fade in new img, do scaling animation
	changed = false;
	if actor.new_img.modulate.a < 1:
		actor.img.modulate.a = max(0, actor.img.modulate.a-actor.fade_speed);
		actor.new_img.modulate.a = min(1, actor.new_img.modulate.a+actor.fade_speed);
		changed = true;
	if actor.new_img.modulate.a >= actor.duang_modulate and actor.duang_curr_angle < actor.duang_end_angle: #do duang
		actor.img.scale = Vector2.ONE * actor.duang_factor * sin(actor.duang_curr_angle);
		actor.new_img.scale = actor.img.scale;
		actor.duang_curr_angle += actor.duang_speed;
		changed = true;
	if not changed:
		actor.swap(actor.img, actor.new_img);
		actor.img.scale = Vector2.ONE;

func changeParentState():
	if not changed:
		return states.idle;
	return null;
