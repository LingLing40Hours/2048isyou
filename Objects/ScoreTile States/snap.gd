extends State


func enter():
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2.ZERO;
	
func inPhysicsProcess(delta):
	#set slide direction; releasing a key should not induce slide
	if GV.focus_dir == -1:
		actor.slide_dir = Vector2(Input.get_axis("ui_left", "ui_right"), 0);
	elif GV.focus_dir == 1:
		actor.slide_dir = Vector2(0, Input.get_axis("ui_up", "ui_down"));


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
