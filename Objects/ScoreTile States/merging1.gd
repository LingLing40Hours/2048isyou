extends State

const SLIDE_RATIO = 1/2.4;


func inPhysicsProcess(delta):
	#sliding into partner
	actor.slide_distance += actor.slide_speed * delta;
	
	if actor.slide_distance >= SLIDE_RATIO * GV.TILE_WIDTH:
		actor.partner.levelup();
	actor.move_and_collide(actor.velocity * delta);
	
func changeParentState():
	if actor.slide_distance >= SLIDE_RATIO * GV.TILE_WIDTH:
		return states.merging2;
	return null;
