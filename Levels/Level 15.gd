extends World

var curr_goal_pos:Vector2i; #for testing


func _ready():
	super._ready();
	
	#init pathfinder
	$Pathfinder.set_player_pos(player_pos_t);
	$Pathfinder.set_player_last_dir(Vector2i.ZERO);
	$Pathfinder.set_tilemap($Cells);
	$Pathfinder.set_tile_push_limits(GV.tile_push_limits);
	$Pathfinder.generate_hash_keys();
	
	#connect tracking cam
	$TrackingCam.transition_started.connect(_on_camera_transition_started);

func viewport_to_tile_pos(viewport_pos:Vector2) -> Vector2i:
	var local_pos:Vector2 = $TrackingCam.position - GV.RESOLUTION/2 + viewport_pos;
	return $Cells.local_to_map(local_pos);

func _input(event):
	super._input(event);
	
	#if event is InputEventMouseButton and event.is_pressed():
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			curr_goal_pos = viewport_to_tile_pos(event.position);
			print("set curr_goal_pos to ", curr_goal_pos);
			return;
	for search_id in GV.SASearchId.IWDMDA+1:
		if event.is_action_pressed("debug"+str(search_id+1)):
			#print search_type, time, and path found
			var min:Vector2i = Vector2i(min(player_pos_t.x, curr_goal_pos.x), min(player_pos_t.y, curr_goal_pos.y)) - Vector2i(5, 5);
			var max:Vector2i = Vector2i(max(player_pos_t.x, curr_goal_pos.x), max(player_pos_t.y, curr_goal_pos.y)) + Vector2i(6, 6);
			var path:Array = $Pathfinder.pathfind_sa(search_id, 200, false, min, max, player_pos_t, curr_goal_pos);
			print(GV.SASearchId.keys()[search_id], "\t", $Pathfinder.get_sa_cumulative_search_time(search_id), "\t", path);
			$Pathfinder.rrd_clear_iad();
			$Pathfinder.reset_sa_cumulative_search_times();
			return;
