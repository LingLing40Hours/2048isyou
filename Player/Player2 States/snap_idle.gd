extends State

var ray:RayCast2D = null;
var obstructed:bool = false;

func enter():
	actor.velocity = Vector2.ZERO;
	actor.slide_dir = Vector2.ZERO;
	ray = null;
	
func inPhysicsProcess(delta):
	#releasing a key should not induce slide
	#set slide direction
	if GV.focus_dir == -1:
		actor.slide_dir = Vector2(Input.get_axis("ui_left", "ui_right"), 0);
	elif GV.focus_dir == 1:
		actor.slide_dir = Vector2(0, Input.get_axis("ui_up", "ui_down"));
	
	#get ray
	if actor.slide_dir == Vector2(1, 0):
		ray = actor.get_node("Ray1");
	elif actor.slide_dir == Vector2(0, -1):
		ray = actor.get_node("Ray2");
	elif actor.slide_dir == Vector2(-1, 0):
		ray = actor.get_node("Ray3");
	elif actor.slide_dir == Vector2(0, 1):
		ray = actor.get_node("Ray4");
	
	#find if obstructed
	if ray != null and ray.is_colliding():
		var collider := ray.get_collider();
		if collider is TileMap and collider.is_in_group("wall"):
			var pos = collider.local_to_map(actor.position + ray.position + ray.target_position);
			var id = collider.get_cell_source_id(0, pos);
			obstructed = false if id == 1 else true;
		elif collider is ScoreTile:
			if collider.power == actor.power:
				#merge
				pass;
			else:
				#try to slide tile
				obstructed = true if not collider.slide(actor.slide_dir, false) else false;
	else:
		obstructed = false;


func changeParentState():
	if actor.slide_dir != Vector2.ZERO and not obstructed:
		return states.snap_sliding;
	return null;
