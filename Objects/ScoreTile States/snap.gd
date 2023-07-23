extends State

var next_state:Node2D;


func enter():
	next_state = null;
	
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2.ZERO;
		
	#check presnap
	if actor.presnapped: #this implies snap was entered, collider offset is already fixed
		actor.slide(actor.next_dir);
		actor.presnapped = false;
	else: #snap to grid if offset within player collider
		var pos_t:Vector2i = actor.position/GV.TILE_WIDTH;
		var offset:Vector2 = actor.position - (Vector2(pos_t) + Vector2(0.5, 0.5)) * GV.TILE_WIDTH;
		if offset.x and abs(offset.x) <= GV.TILE_WIDTH * (1 - GV.PLAYER_COLLIDER_SCALE):
			actor.position.x -= offset.x;
		if offset.y and abs(offset.y) <= GV.TILE_WIDTH * (1 - GV.PLAYER_COLLIDER_SCALE):
			actor.position.y -= offset.y;
				
	
func inPhysicsProcess(_delta):
	if next_state != null or GV.changing_level:
		return;
	
	var event_name:String = "";
	
	#find movement type
	var action:Callable;
	if Input.is_action_pressed("cc"):
		action = Callable(actor, "split");
		event_name += "split_";
	elif Input.is_action_pressed("shift"):
		action = Callable(actor, "shift");
		event_name += "shift_";
	else:
		action = Callable(actor, "slide");
		event_name += "ui_";
	
	#find direction
	var dir:Vector2 = Vector2.ZERO;
	if Input.is_action_pressed("ui_left"):
		dir = Vector2(-1, 0);
	elif Input.is_action_pressed("ui_right"):
		dir = Vector2(1, 0);
	elif Input.is_action_pressed("ui_up"):
		dir = Vector2(0, -1);
	elif Input.is_action_pressed("ui_down"):
		dir = Vector2(0, 1);
	
	#check if movement pressed
	if dir != Vector2.ZERO:
		#check if movement just pressed
		event_name += GV.directions.find_key(dir);
		if Input.is_action_just_pressed(event_name):
			action.call(dir);


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
