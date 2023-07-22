extends State

var next_state:Node2D;


func enter():
	next_state = null;
	
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2.ZERO;
		
	#check presnap
	if actor.presnapped: #entered snap already, tiny offset is fixed
		actor.slide(actor.next_dir);
		actor.presnapped = false;
	else: #snap to grid if offset within player collider
		var pos_t:Vector2i = actor.position/GV.TILE_WIDTH;
		var offset:Vector2 = actor.position - (Vector2(pos_t) + Vector2(0.5, 0.5)) * GV.TILE_WIDTH;
		if offset.x and abs(offset.x) <= GV.TILE_WIDTH * (1 - GV.PLAYER_COLLIDER_SCALE):
			actor.position.x -= offset.x;
		if offset.y and abs(offset.y) <= GV.TILE_WIDTH * (1 - GV.PLAYER_COLLIDER_SCALE):
			actor.position.y -= offset.y;
				
	
func handleInput(event):
	if next_state != null or GV.changing_level:
		return;
	
	#don't split if just splitted
	if not actor.splitted and GV.abilities["split"]: #split
		if event.is_action_pressed("split_left"):
			actor.split(Vector2(-1, 0));
		elif event.is_action_pressed("split_right"):
			actor.split(Vector2(1, 0));
		elif event.is_action_pressed("split_up"):
			actor.split(Vector2(0, -1));
		elif event.is_action_pressed("split_down"):
			actor.split(Vector2(0, 1));
	
	if next_state == null and not event.is_action_pressed("cc"): #slide/merge
		if event.is_action_pressed("ui_left"):
			actor.slide(Vector2(-1, 0));
		elif event.is_action_pressed("ui_right"):
			actor.slide(Vector2(1, 0));
		elif event.is_action_pressed("ui_up"):
			actor.slide(Vector2(0, -1));
		elif event.is_action_pressed("ui_down"):
			actor.slide(Vector2(0, 1));

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
