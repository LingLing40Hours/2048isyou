extends World


func _ready():
	super._ready();
	
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

