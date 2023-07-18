extends State

var target:Vector2;
var target_t:Vector2;
var target_distance:float;
var slide_distance:float = 0;
var slide_done:bool = false;


func enter():
	#reset stuff
	slide_distance = 0;
	slide_done = false;
	
	#find target in tile coords
	var pos_t = actor.position/GV.TILE_WIDTH;
	target_t = pos_t + actor.slide_dir;
	if actor.slide_dir.x:
		target_t.x = floorf(target_t.x) if actor.slide_dir.x > 0 else ceilf(target_t.x);
	else:
		target_t.y = floorf(target_t.y) if actor.slide_dir.y > 0 else ceilf(target_t.y);
	
	#find target
	target = GV.TILE_WIDTH * target_t;
	target_distance = (target - actor.position).length();
	print("target distance: ", target_distance);
	
	#set slide velocity
	actor.velocity = GV.PLAYER_SNAP_SPEED * actor.slide_dir;
	
	#sound
	actor.game_audio.get_node("Slide").play();

func inPhysicsProcess(delta):
	slide_distance += GV.PLAYER_SNAP_SPEED * delta;
	if slide_distance < target_distance:
		var collision = actor.move_and_collide(actor.velocity * delta);
		if collision and (target - actor.position).length() > actor.safe_margin and collision.get_normal() == -actor.slide_dir:
			slide_done = true;
			print("STOPPED", actor.position);
	else:
		slide_done = true;
		actor.position = target;
		print("DONE", actor.position)

func changeParentState():
	if slide_done:
		return states.snap_idle;
	return null;
			
func same_sign_inclusive(a, b):
	if a == 0:
		return true;
	elif a > 0:
		return true if b >= 0 else false;
	else:
		return true if b <= 0 else false;
