extends State

var next_state:Node2D;


func enter():
	next_state = null;
	
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2.ZERO;

	#snap
	actor.snap_range(GV.PLAYER_SNAP_RANGE);
	
	#do premove (if premoved)
	if actor.next_move.is_valid():
		actor.next_move.call(actor.next_dir);
		actor.next_move = Callable();
	
func handleInput(_event):
	if next_state != null or GV.changing_level:
		return;
	
	actor.get_next_action();
	if actor.next_move.is_valid():
		actor.next_move.call(actor.next_dir);
		actor.next_move = Callable();

func changeParentState():
	return next_state;



'''
func changeParentState():
	if actor.slide_dir == Vector2.ZERO:
		return null;
	return next_state(actor.slide_dir);


#assume dir is unit vector along x or y axis
func next_state(dir:Vector2) -> Node2D:
	#get ray
	var ray:RayCast2D;
	if dir.x == 1:
		ray = actor.get_node("Ray1");
	elif dir.y == -1:
		ray = actor.get_node("Ray2");
	elif dir.x == -1:
		ray = actor.get_node("Ray3");
	else:
		ray = actor.get_node("Ray4");
	
	#check collision
	if ray.is_colliding():
		var collider := ray.get_collider();
		
		if collider.is_in_group("wall"):
			return null;
		elif collider is ScoreTile:
			if collider.power == actor.power:
				return states.merging1;
			else: #try to slide tile
				return states.sliding if collider.slide(actor.slide_dir, false) else null;

	return states.sliding;
'''
