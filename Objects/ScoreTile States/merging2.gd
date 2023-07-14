extends State


func inPhysicsProcess(delta):
	#sliding into partner
	actor.slide_distance += actor.slide_speed * delta;
	if actor.slide_distance >= GV.TILE_WIDTH:
		actor.queue_free(); #done sliding
	else:
		actor.move_and_collide(actor.velocity * delta);
	
