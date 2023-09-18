extends Baddie

@onready var ray_cast = $RayCast2D;
@onready var area_2d = $Area2D;

@export var speed = 75;
@export var distance_limit:float = 200;

var chasing :bool = false; # boolean varible recording chaseing status
var chasing_counter = 0;

func _physics_process(delta):
	var player = game.current_level.players[0]
	#raycast always points towards the player
	ray_cast.set_target_position(player.position - self.position)
	var distance = ((player.position.x - self.position.x) ** 2 + (player.position.y - self.position.y) ** 2) ** 0.5
	
	# chase the player if close enough
	if ray_cast.is_colliding() and ray_cast.get_collider().is_in_group("player") and distance < distance_limit:
		get_node("AnimatedSprite2D").play("chase")
		chasing = true
		chasing_counter = 0;
		
		var direction = (player.position - self.position).normalized()
		velocity.x = direction.x * speed
		velocity.y = direction.y * speed

		var collision_info = move_and_collide(velocity * delta)
		if collision_info:
			var collider = collision_info.get_collider();
			if collider.is_in_group("player"):
				collider.die();
			
			elif collider is ScoreTile and chasing:
				var wall = game.current_level.get_node("Walls")
				print(collider.position)
				print(wall.local_to_map(collider.position))
				wall.set_cell(0, wall.local_to_map(collider.position), 2, Vector2i(0,0))
				collider.queue_free();
				
	# do a 3 seconds delay
	elif chasing and chasing_counter < 180:
		chasing_counter += 1;
		get_node("AnimatedSprite2D").play("chase");
	
	else:
		get_node("AnimatedSprite2D").play("idle");
		chasing = false;
		chasing_counter = 0;


func _on_area_2d_body_entered(body):
	if body.is_in_group("wall"):
		speed /= 3;


func _on_area_2d_body_exited(body):
	if body.is_in_group("wall"):
		speed *= 2;
