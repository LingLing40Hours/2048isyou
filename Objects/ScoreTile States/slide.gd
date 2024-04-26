extends State

@onready var game:Node2D = $"/root/Game";

	
func inPhysicsProcess(_delta):
	#friction
	actor.velocity *= 1 - GV.PLAYER_MU;

	#input
	var hdir = int(Input.get_axis("left", "right"));
	var vdir = int(Input.get_axis("up", "down"));
	var dir:Vector2i = Vector2i(hdir, vdir);
	
	#signal (before curr snapshot becomes meaningful)
	if dir != Vector2i.ZERO:
		actor.action_started.emit();
	
	#accelerate
	if not GV.changing_level:
		actor.velocity += dir * GV.PLAYER_SLIDE_SPEED;

	#clamping
	if actor.velocity.length() < GV.PLAYER_SLIDE_SPEED_MIN:
		actor.velocity = Vector2.ZERO;
	
	actor.move_and_slide()
	for index in actor.get_slide_collision_count():
		var collision:KinematicCollision2D = actor.get_slide_collision(index);
		var collider = collision.get_collider();
		
		if collider.is_in_group("baddie"):
			actor.die();
		
		elif collider is ScoreTile:
			#find slide direction
			var slide_dir:Vector2 = collision.get_normal() * (-1);
			if absf(slide_dir.x) >= absf(slide_dir.y):
				slide_dir.y = 0;
			else:
				slide_dir.x = 0;
			slide_dir = slide_dir.normalized();
			
			#slide if slide_dir and player_dir agree
			if (slide_dir.x && slide_dir.x == dir.x) or (slide_dir.y && slide_dir.y == dir.y):
				actor.tile_push_count = 0;
				collider.pusher = actor;
				collider.slide(Vector2i(slide_dir));
				game.current_level.current_snapshot.add_tile(actor);

func changeParentState():
	if GV.player_snap:
		return states.snap;
	return null;
