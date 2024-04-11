extends State

@onready var game:Node2D = $"/root/Game";

#target_velocity is calculated s.t. shift takes same amount of time as slide, regardless of distance
var target_velocity:Vector2;
var total_shift_distance:float; #ignoring areas
var distance_to_next_snap:float;
var to_area:Area2D;


#assume player is aligned
func enter():
	#add to snapshot
	game.current_level.current_snapshot.add_tile(actor);
	
	#extend shape
	actor.shift_shape.enabled = true;
	actor.shift_shape.collide_with_areas = false;
	actor.shift_shape.target_position = GV.SHIFT_RAY_LENGTH * actor.slide_dir;
	actor.shift_shape.force_shapecast_update();
	
	#find target velocity (ignore friction and areas)
	total_shift_distance = GV.SHIFT_RAY_LENGTH;
	if actor.shift_shape.is_colliding():
		var dpos:Vector2 = actor.shift_shape.get_collision_point(0) - actor.position;
		total_shift_distance = abs(dpos.x) if actor.slide_dir.x else abs(dpos.y);
		total_shift_distance -= GV.TILE_WIDTH/2;
	target_velocity = total_shift_distance * GV.SHIFT_DISTANCE_TO_MAX_SPEED * actor.slide_dir;
	actor.shift_shape.collide_with_areas = true;
	actor.shift_shape.force_shapecast_update();
	
	update_dist_and_to_area();
	
	#play sound
	game.shift_sound.play();


func inPhysicsProcess(delta):
	#friction
	actor.velocity *= 1 - GV.PLAYER_MU;
	
	#accelerate
	actor.velocity = actor.velocity.lerp(target_velocity, GV.SHIFT_LERP_WEIGHT);
	
	#track distance travelled to ensure player doesn't clip through areas
	if to_area:
		var speed = actor.velocity.length() * delta;
		if distance_to_next_snap > speed:
			distance_to_next_snap -= speed;
		else:
			#slow down
			actor.velocity = distance_to_next_snap * 60 * actor.slide_dir;
			
			#update target parameters
			actor.shift_shape.add_exception(to_area); #to monitor next area/obstacle
			actor.shift_shape.force_shapecast_update();
			update_dist_and_to_area();
	
	var collision = actor.move_and_collide(actor.velocity * delta);
	if collision:
		if collision.get_collider().is_in_group("baddie"):
			actor.die();
			
		actor.velocity = Vector2.ZERO;

func update_dist_and_to_area():
	#find distance (considering areas)
	to_area = null;
	if actor.shift_shape.is_colliding():
		var dpos:Vector2i = actor.shift_shape.get_collision_point(0) - actor.position;
		distance_to_next_snap = abs(dpos.x) if actor.slide_dir.x else abs(dpos.y);
		distance_to_next_snap -= GV.TILE_WIDTH/2;
		var collider = actor.shift_shape.get_collider(0);
		if collider is Area2D:
			distance_to_next_snap = (round(distance_to_next_snap/GV.TILE_WIDTH) + 1) * GV.TILE_WIDTH;
			to_area = collider;
	else:
		distance_to_next_snap = GV.RESOLUTION.x;

func handleInput(event):
	var accelerate:bool = (game.current_level.last_input_move == "");
	if actor.color == GV.ColorId.GRAY and game.current_level.update_last_input(event):
		actor.add_premove(false, accelerate);

func changeParentState():
	if actor.velocity == Vector2.ZERO:
		return states.snap;
	return null;
	
func exit():
	var new_pos_t:Vector2i = GV.world_to_pos_t(actor.position);
	if game.current_level.pooled:
		game.current_level.move_tile(actor.pos_t, new_pos_t);
	actor.pos_t = new_pos_t;
	actor.snap_range(1);
	
	#reset ray length, exceptions
	actor.shift_shape.clear_exceptions();
	actor.shift_shape.target_position = Vector2.ZERO;
	actor.shift_shape.enabled = false;
