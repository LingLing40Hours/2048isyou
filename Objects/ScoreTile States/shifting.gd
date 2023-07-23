extends State

@onready var game:Node2D = $"/root/Game";

var ray_target:Vector2;
var target_velocity:Vector2;
var distance:float;


#assume player is aligned
func enter():
	#extend ray
	ray_target = actor.shift_ray.target_position;
	actor.shift_ray.target_position = actor.slide_dir * GV.SHIFT_RAY_LENGTH;
	actor.shift_ray.force_raycast_update();
	
	#find shift distance (used for target velocity calculation)
	if actor.shift_ray.is_colliding():
		distance = (actor.shift_ray.get_collision_point() - actor.global_position).length() - GV.TILE_WIDTH/2;
	else:
		distance = GV.RESOLUTION.x;
	
	#find target velocity (ignore friction)
	target_velocity = distance * GV.SHIFT_DISTANCE_TO_SPEED_MAX * actor.slide_dir;
	
	#play sound
	game.shift_sound.play();


func inPhysicsProcess(delta):
	#friction
	actor.velocity *= 1 - GV.PLAYER_MU;
	
	#accelerate
	actor.velocity = actor.velocity.lerp(target_velocity, GV.SHIFT_LERP_WEIGHT);
	
	var collision = actor.move_and_collide(actor.velocity * delta);
	if collision:
		if collision.get_collider().is_in_group("baddie"):
			actor.die();
			
		actor.velocity = Vector2.ZERO;

func changeParentState():
	if actor.velocity == Vector2.ZERO:
		return states.snap;
	return null;
	
func exit():
	#reset ray length
	actor.shift_ray.target_position = ray_target;
	actor.shift_ray.force_raycast_update();
