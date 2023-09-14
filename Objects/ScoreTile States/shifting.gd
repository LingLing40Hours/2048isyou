extends State

@onready var game:Node2D = $"/root/Game";

var ray_target:Vector2;
var target_velocity:Vector2;
var distance:float;
var to_area:Area2D;


#assume player is aligned
func enter():
	#add to snapshot
	game.current_level.current_snapshot.add_tile(actor);
	
	#extend ray
	ray_target = actor.shift_ray.target_position;
	actor.shift_ray.target_position = actor.slide_dir * GV.SHIFT_RAY_LENGTH;
	
	#find target velocity (ignore friction and areas)
	actor.shift_ray.collide_with_areas = false;
	actor.shift_ray.force_raycast_update();
	var total_distance = GV.SHIFT_RAY_LENGTH;
	if actor.shift_ray.is_colliding():
		total_distance = (actor.shift_ray.get_collision_point() - actor.position).length() - GV.TILE_WIDTH/2;
	target_velocity = total_distance * GV.SHIFT_DISTANCE_TO_SPEED_MAX * actor.slide_dir;
	actor.shift_ray.collide_with_areas = true;
	actor.shift_ray.force_raycast_update();
	
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
			actor.shift_ray.add_exception(to_area);
			actor.shift_ray.force_raycast_update();
			update_target_parameters();
	
	var collision = actor.move_and_collide(actor.velocity * delta);
	if collision:
		if collision.get_collider().is_in_group("baddie"):
			actor.die();
			
		actor.velocity = Vector2.ZERO;

func update_target_parameters():
	#find distance (used for target velocity calculation)
	to_area = null;
	if actor.shift_ray.is_colliding():
		distance = (actor.shift_ray.get_collision_point() - actor.position).length() - GV.TILE_WIDTH/2;
		var collider = actor.shift_ray.get_collider();
		if collider is Area2D:
			distance = (round(distance/GV.TILE_WIDTH) + 1) * GV.TILE_WIDTH;
			to_area = collider;
	else:
		distance = GV.RESOLUTION.x;
	#print("SHIFT DISTANCE: ", distance);

func handleInput(_event):
	#allow early input
	await game.current_level.processed_action_input;
	actor.get_next_action();

func changeParentState():
	if actor.velocity == Vector2.ZERO:
		return states.snap;
	return null;
	
func exit():
	#reset ray length, exceptions
	actor.shift_ray.clear_exceptions();
	actor.shift_ray.target_position = ray_target;
	actor.shift_ray.force_raycast_update();
