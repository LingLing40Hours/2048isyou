extends Baddie

@export var vx:float = 0;
@export var vy:float = 180;


func _ready():
	super._ready();
	
	velocity.x = vx;
	velocity.y = vy;
	
func _physics_process(delta):
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())
		
		var collider = collision_info.get_collider();
		if collider.is_in_group("player"):
			collider.die();
			
