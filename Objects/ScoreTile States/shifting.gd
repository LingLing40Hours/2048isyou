extends State

@onready var game:Node2D = $"/root/Game";

var target_velocity:Vector2;
var total_distance:float;
var distance:float;
var to_area:Area2D;


#assume player is aligned
func enter():
	#add to snapshot
	game.current_level.current_snapshot.add_tile(actor);
	
	#extend shape
	actor.shift_shape.collide_with_areas = false;
	actor.shift_settings(actor.shift_shape, actor.slide_dir);
	
	#find target velocity (ignore friction and areas)
	total_distance = GV.SHIFT_RAY_LENGTH;
	if actor.shift_shape.is_colliding():
		var dpos:Vector2 = actor.shift_shape.get_collision_point(0) - actor.position;
		total_distance = abs(dpos.x) if actor.slide_dir.x else abs(dpos.y);
		total_distance -= GV.TILE_WIDTH/2;
	target_velocity = total_distance * GV.SHIFT_DISTANCE_TO_SPEED_MAX * actor.slide_dir;
	actor.shift_shape.collide_with_areas = true;
	actor.shift_shape.force_shapecast_update();
	
	update_target_parameters();
	
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
		if distance > speed:
			distance -= speed;
		else:
			#slow down
			actor.velocity = distance * 60 * actor.slide_dir;
			
			#update target parameters
			actor.shift_shape.add_exception(to_area);
			actor.shift_shape.force_shapecast_update();
			update_target_parameters();
	
	var collision = actor.move_and_collide(actor.velocity * delta);
	if collision:
		if collision.get_collider().is_in_group("baddie"):
			actor.die();
			
		actor.velocity = Vector2.ZERO;

func update_target_parameters():
	#find distance (considering areas)
	to_area = null;
	if actor.shift_shape.is_colliding():
		var dpos:Vector2i = actor.shift_shape.get_collision_point(0) - actor.position;
		distance = abs(dpos.x) if actor.slide_dir.x else abs(dpos.y);
		distance -= GV.TILE_WIDTH/2;
		var collider = actor.shift_shape.get_collider(0);
		if collider is Area2D:
			distance = (round(distance/GV.TILE_WIDTH) + 1) * GV.TILE_WIDTH;
			to_area = collider;
	else:
		distance = GV.RESOLUTION.x;

func handleInput(_event):
	#allow early input
	await game.current_level.processed_action_input;
	actor.get_next_action();

func changeParentState():
	if actor.velocity == Vector2.ZERO:
		return states.snap;
	return null;
	
func exit():
	var new_pos_t:Vector2i = actor.pos_t + GV.world_to_xt(total_distance) * actor.slide_dir;
	if game.current_level.pooled:
		game.current_level.move_tile(actor.pos_t, new_pos_t);
	actor.pos_t = new_pos_t;
	
	#reset ray length, exceptions
	actor.shift_shape.clear_exceptions();
	actor.slide_settings(actor.shift_shape);
