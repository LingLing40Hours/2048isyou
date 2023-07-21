extends State

var next_state:Node2D;


func enter():
	next_state = null;
	
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2.ZERO;
	
func inPhysicsProcess(_delta):
	#don't overwrite slide_dir before state change happens
	if next_state != null:
		return;
	
	#don't split if just splitted
	if not actor.splitted and GV.abilities["split"]: #split
		if Input.is_action_pressed("split_left"):
			actor.split(Vector2(-1, 0));
		elif Input.is_action_pressed("split_right"):
			actor.split(Vector2(1, 0));
		elif Input.is_action_pressed("split_up"):
			actor.split(Vector2(0, -1));
		elif Input.is_action_pressed("split_down"):
			actor.split(Vector2(0, 1));
	
	if next_state == null and not Input.is_action_pressed("cc"): #slide/merge
		if GV.focus_dir == -1:
			actor.slide_dir = Vector2(Input.get_axis("ui_left", "ui_right"), 0);
		elif GV.focus_dir == 1:
			actor.slide_dir = Vector2(0, Input.get_axis("ui_up", "ui_down"));
		
		if actor.slide_dir != Vector2.ZERO:
			actor.slide(actor.slide_dir);


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
