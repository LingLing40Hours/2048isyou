extends State

@onready var game:Node2D = $"/root/Game";

var slide_target:Vector2;
var target_distance:float;
var slide_distance:float;
var slide_speed:float;
var slide_done:bool;
var stop_margin:float;


func enter():
	#assert(actor.slide_dir != Vector2i.ZERO);
	
	#add to snapshot
	if not actor.is_hostile and (!is_instance_valid(actor.pusher) or not actor.pusher.is_hostile):
		if actor.splitted:
			game.current_level.current_snapshot.add_new_tile(actor);
		else:
			game.current_level.current_snapshot.add_tile(actor);
	
	#set slide parameters
	if actor.is_player:
		slide_speed = GV.TILE_SLIDE_SPEED * GV.PLAYER_SPEED_RATIO;
		stop_margin = slide_speed/60.0;
	else:
		slide_speed = GV.TILE_SLIDE_SPEED;
		stop_margin = slide_speed/60.0;
	slide_distance = 0;
	slide_done = false;
	#slide_target = actor.position + actor.slide_dir * GV.TILE_WIDTH;
	actor.velocity = actor.slide_dir * slide_speed;
	
	#find target in tile coords, which may have fractional component (player might not be aligned bc of slide mode)
	var pos_t:Vector2 = actor.position/GV.TILE_WIDTH - Vector2(0.5, 0.5);
	var target_t:Vector2 = pos_t + Vector2(actor.slide_dir);
	if actor.slide_dir.x:
		target_t.x = floorf(target_t.x) if actor.slide_dir.x > 0 else ceilf(target_t.x);
	else:
		target_t.y = floorf(target_t.y) if actor.slide_dir.y > 0 else ceilf(target_t.y);
	
	#find target
	slide_target = GV.TILE_WIDTH * (target_t + Vector2(0.5, 0.5));
	target_distance = (slide_target - actor.position).length();
	#print("target distance: ", target_distance);
	
	#turn off latter layers (4-32) when sliding to ignore obstructing baddie
	#disable collision with player if in snap mode so player can follow through with slide
	actor.set_layers(false, GV.player_snap);
	
	#play sound
	if not actor.snap_slid and not actor.splitted:
		game.slide_sound.play();

func inPhysicsProcess(delta):
	#sliding into empty space
	slide_distance += slide_speed * delta;
	if slide_distance < target_distance:
		var collision = actor.move_and_collide(actor.velocity * delta);
		
		if collision:
			if collision.get_collider().is_in_group("baddie"):
				actor.die();
				
			if (slide_target - actor.position).length() > stop_margin:
				var norm = collision.get_normal();
				if actor.slide_dir.x:
					if GV.same_sign_exclusive(actor.slide_dir.x, norm.x):
						slide_done = true;
				elif GV.same_sign_exclusive(actor.slide_dir.y, norm.y):
						slide_done = true;
	else:
		actor.position = slide_target;
		slide_done = true;

func handleInput(_event):
	if actor.is_player: #allow early input
		await game.current_level.processed_action_input;
		actor.get_next_action();

func changeParentState():
	if slide_done:
		if actor.is_player:
			return states.snap;
		return states.tile;
	return null;

func exit():
	#reset stuff
	actor.pusher = null;
	actor.pusheds.clear();
	actor.snap_slid = false;
	
	#re-enable collisions
	actor.set_layers(true, true);
	if actor.splitted:
		actor.splitted = false;
		actor.set_masks(true);
