extends Baddie

@onready var ray_cast = $RayCast2D;
@onready var game:Node2D = $"/root/Game";


@export var speed = 50;
@export var distance_limit:float = 200;

func _physics_process(delta):
	#do not know the excat node path of player
	var player = game.current_level.players[0]
	#raycast always points towards the player
	ray_cast.set_target_position(player.position - self.position)
	
	if ray_cast.is_colliding() and ray_cast.get_collider().is_in_group("player"):
		#do not know the exact build_in function of calculating the distance between two points
		var distance = ((player.position.x - self.position.x) ** 2 + (player.position.y - self.position.y) ** 2) ** 0.5
		
		# chase the player if close enough
		if distance < distance_limit:
			get_node("AnimatedSprite2D").play("chase")
			
			var direction = (player.position - self.position).normalized()
			velocity.x = direction.x * speed
			velocity.y = direction.y * speed
			
			var collision_info = move_and_collide(velocity * delta)
			if collision_info:

				var collider = collision_info.get_collider();
				if collider.is_in_group("player"):
					collider.die();
		else:
			get_node("AnimatedSprite2D").play("idle")
