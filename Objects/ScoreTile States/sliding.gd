extends State


func inPhysicsProcess(delta):
	#sliding into empty space
	actor.slide_distance += actor.slide_speed * delta;
	if actor.slide_distance >= GV.TILE_WIDTH:
		actor.position = actor.slide_target;
		#re-enable collisions
		for i in range(1, 33):
			actor.set_collision_layer_value(i, true);
	else:
		actor.move_and_collide(actor.velocity * delta);

func changeParentState():
	if actor.position == actor.slide_target:
		return states.idle;
	return null;
