extends Baddie

var speed = 250
var angular_speed = PI

func _physics_process(delta):
	rotation += angular_speed * delta

	var velocity = Vector2.UP.rotated(rotation) * speed
	
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:

		var collider = collision_info.get_collider();
		if collider.is_in_group("player"):
			collider.die();

