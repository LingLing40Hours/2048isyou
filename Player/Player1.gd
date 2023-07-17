extends CharacterBody2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";

	
func _physics_process(_delta):
	#friction
	velocity *= 1-GV.PLAYER_MU;

	#input
	var hdir = Input.get_axis("ui_left", "ui_right")
	var vdir = Input.get_axis("ui_up", "ui_down");
	var dir:Vector2 = Vector2(hdir, vdir);
	velocity += dir * GV.PLAYER_SPEED;

	#clamping
	if velocity.length() < GV.PLAYER_SPEED_MIN:
		velocity = Vector2.ZERO;
	
	move_and_slide()
	#see baddie scripts for death detection
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index);
		var collider := collision.get_collider();
		if collider is ScoreTile:
			#find slide direction
			var slide_dir:Vector2 = collision.get_normal() * (-1);
			if abs(slide_dir.x) >= abs(slide_dir.y):
				slide_dir.y = 0;
			else:
				slide_dir.x = 0;
			slide_dir = slide_dir.normalized();
			
			#slide if slide_dir and player_dir agree
			if (slide_dir.x && slide_dir.x == dir.x) or (slide_dir.y && slide_dir.y == dir.y):
				collider.slide(slide_dir, true);

func die():
	#play an animation
	game.change_level_faded(GV.current_level_index);
	#game.call_deferred("change_level_faded", GV.current_level_index);
	


func _on_physics_enabler_body_entered(body):
	if body is ScoreTile:
		body.set_process(true);
		body.set_physics_process(true);
		for i in range(1, 5):
			body.get_node("Ray"+str(i)).enabled = true;
		#body.process_mode = Node.PROCESS_MODE_INHERIT;


func _on_physics_enabler_body_exited(body):
	if body is ScoreTile:
		body.set_process(false);
		body.set_physics_process(false);
		for i in range(1, 5):
			body.get_node("Ray"+str(i)).enabled = false;
		#body.process_mode = Node.PROCESS_MODE_DISABLED;
