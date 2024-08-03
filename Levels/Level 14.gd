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

	#randomize();
	#tile_noise.set_seed(2);
	#wall_noise.set_seed(2);
	tile_noise.set_seed(randi());
	wall_noise.set_seed(randi());
	tile_noise.set_frequency(0.07); #default 0.01
	wall_noise.set_frequency(0.03);
	tile_noise.set_fractal_octaves(3); #number of layers, default 5
	wall_noise.set_fractal_octaves(3);
	tile_noise.set_fractal_lacunarity(2); #frequency multiplier for subsequent layers, default 2.0
	wall_noise.set_fractal_lacunarity(2);
	tile_noise.set_fractal_gain(0.5); #strength of subsequent layers, default 0.5
	wall_noise.set_fractal_gain(0.3);
	
	#load cells
	loaded_pos_t_min = GV.world_to_pos_t($TrackingCam.position - half_resolution - Vector2(GV.TILE_LOAD_BUFFER, GV.TILE_LOAD_BUFFER));
	loaded_pos_t_max = GV.world_to_pos_t($TrackingCam.position + half_resolution + Vector2(GV.TILE_LOAD_BUFFER, GV.TILE_LOAD_BUFFER));
	load_rect(loaded_pos_t_min, loaded_pos_t_max);

	#print($Cells.get_cell_source_id(0, Vector2i.ZERO)) #layer, coord; unnecessary since layer is same as source id
	#print($Cells.get_cell_source_id(0, Vector2i(1, 0)))
	#print($Cells.get_cell_atlas_coords(0, Vector2i.ZERO))
	#print($Cells.get_cell_atlas_coords(0, Vector2i(1, 0)))

func viewport_to_tile_pos(viewport_pos:Vector2) -> Vector2i:
	var local_pos:Vector2 = $TrackingCam.position - GV.RESOLUTION/2 + viewport_pos;
	return $Cells.local_to_map(local_pos);

func _input(event):
	super._input(event);
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			curr_goal_pos = viewport_to_tile_pos(event.position);
			print("set curr_goal_pos to ", curr_goal_pos);
			return;
	#if event is InputEventMouseButton and event.is_pressed():
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#var click_pos:Vector2i = viewport_to_tile_pos(event.position);
			#$Pathfinder.rrd_init_iad(click_pos);
			#curr_goal_pos = click_pos;
			#print("curr_goal_pos: ", click_pos);
			##print($Cells.local_to_map(get_local_mouse_position())); #more offset error
		#elif event.button_index == MOUSE_BUTTON_RIGHT:
			#var click_pos:Vector2i = viewport_to_tile_pos(event.position);
			#print("rrd_resume_iad: ", curr_goal_pos, click_pos, $Pathfinder.rrd_resume_iad(curr_goal_pos, click_pos, GV.TypeId.PLAYER));
	for search_id in GV.SASearchId.IWDMDA+1:
		if event.is_action_pressed("debug"+str(search_id+1)):
			#print search_type, time, and path found
			var min:Vector2i = Vector2i(min(player_pos_t.x, curr_goal_pos.x), min(player_pos_t.y, curr_goal_pos.y)) - Vector2i(2, 2);
			var max:Vector2i = Vector2i(max(player_pos_t.x, curr_goal_pos.x), max(player_pos_t.y, curr_goal_pos.y)) + Vector2i(3, 3);
			var path:Array = $Pathfinder.pathfind_sa(search_id, 24, false, min, max, player_pos_t, curr_goal_pos);
			print(GV.SASearchId.keys()[search_id], "\t", $Pathfinder.get_sa_cumulative_search_time(search_id), "\t", path);
			$Pathfinder.rrd_clear_iad();
			$Pathfinder.reset_sa_cumulative_search_times();
			return;
	#if event.is_action_pressed("debug1"):
		#for i in 1000:
			#print("epoch: ", i);
			##generate random start pos
			#var start_pos:Vector2i = Vector2i(randi_range(-20, 19), randi_range(-15, 14));
			#while get_tile_id(start_pos) == GV.TileId.EMPTY:
				#start_pos = Vector2i(randi_range(-20, 19), randi_range(-15, 14));
			#
			##set type at start_pos to PLAYER
			#var start_atlas_coord:Vector2i = $Cells.get_cell_atlas_coords(GV.LayerId.TILE, start_pos);
			#$Cells.set_cell(GV.LayerId.TILE, start_pos, GV.LayerId.TILE, Vector2i(start_atlas_coord.x, GV.TypeId.PLAYER));
			##generate random end pos
			#var end_pos:Vector2i = start_pos + Vector2i(randi_range(-5, 5), randi_range(-5, 5));
			#while (!is_compatible(GV.TypeId.PLAYER, get_back_id(end_pos)) or end_pos.x < -20 or end_pos.x > 19 or end_pos.y < -15 or end_pos.y > 14):
				#end_pos = start_pos + Vector2i(randi_range(-5, 5), randi_range(-5, 5));
			#
			##get min, max
			#var min:Vector2i = Vector2i(min(start_pos.x, end_pos.x), min(start_pos.y, end_pos.y)) - Vector2i(2, 2);
			#var max:Vector2i = Vector2i(max(start_pos.x, end_pos.x), max(start_pos.y, end_pos.y)) + Vector2i(3, 3);
			##pathfind
			#for search_id in range(2, 7):
				#print(GV.SASearchId.keys()[search_id]);
				#$Pathfinder.pathfind_sa(search_id, 24, false, min, max, start_pos, end_pos);
				#$Pathfinder.rrd_clear_iad();
		#
		##print cumulative times
		#for search_id in range(2, 7):
			#print(GV.SASearchId.keys()[search_id], "\t\t", $Pathfinder.get_sa_cumulative_search_time(search_id));
		#
		##reset cumulative times
		#$Pathfinder.reset_sa_cumulative_search_times();
