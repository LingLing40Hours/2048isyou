extends Level

signal initial_tiles_gennied;
signal initial_tiles_readied;
var initial_tiles_generated:bool; #shared
var initial_tiles_ready:bool;
var initial_tile_count:int; #main then chunker
var initial_ready_count:int;

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");
var tile_noise = FastNoiseLite.new();
var wall_noise = FastNoiseLite.new();
var difficulty:float = 0; #probability of hostile, noise roughness

var semaphore:Semaphore;
var thread:Thread; #handles chunk loading/unloading
var load_mutex:Mutex;
var initial_mutex:Mutex;
#var constructed_mutex:Mutex;
var loaded_mutex:Mutex;
var exit_mutex:Mutex;
var exit_thread:bool = false;

#pools
var tile_pool:Array;
var max_tiles_per_frame:int = 4;

#pos_t, bool
var load_queue:Dictionary; #shared; dict for fast lookup
var pool_queue:Dictionary; #main thread;

#pos_t, ScoreTile
#var constructed_tiles:Dictionary; #shared
var loaded_tiles:Dictionary; #shared

#bounding rect
var loaded_pos_t_min:Vector2i;
var loaded_pos_t_max:Vector2i; #inclusive

var load_start_time:int;
var load_end_time:int;
var player_global_spawn_pos_t:Vector2i = Vector2i.ZERO;

@onready var last_cam_pos:Vector2 = $TrackingCam.position;


func _enter_tree():
	super._enter_tree();
	#set position bounds (before tracking cam _ready())
	min_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MIN, GV.INT64_MIN);
	max_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MAX, GV.INT64_MAX);

func _ready():
	pooled = true;
	super._ready();
	
	#load player
	initial_tiles_readied.connect(load_player);
	
	#randomize();
	tile_noise.set_seed(2);
	wall_noise.set_seed(2);
	#tile_noise.set_seed(randi());
	#wall_noise.set_seed(randi());
	tile_noise.set_frequency(0.07); #default 0.01
	wall_noise.set_frequency(0.03);
	tile_noise.set_fractal_octaves(3); #number of layers, default 5
	wall_noise.set_fractal_octaves(3);
	tile_noise.set_fractal_lacunarity(2); #frequency multiplier for subsequent layers, default 2.0
	wall_noise.set_fractal_lacunarity(2);
	tile_noise.set_fractal_gain(0.5); #strength of subsequent layers, default 0.5
	wall_noise.set_fractal_gain(0.3);
	#tile_noise.set_fractal_ping_pong_strength(10);
	#tile_noise.set_domain_warp_enabled(true);
	#wall_noise.set_domain_warp_enabled(true);
	
	#thread stuff
	load_mutex = Mutex.new();
	initial_mutex = Mutex.new();
	#constructed_mutex = Mutex.new();
	loaded_mutex = Mutex.new();
	exit_mutex = Mutex.new();
	semaphore = Semaphore.new();
	exit_thread = false;
	thread = Thread.new();
	
	#load initial chunks
	initial_tiles_generated = false;
	initial_tiles_ready = false;
	initial_ready_count = 0;
	loaded_pos_t_min = GV.world_to_pos_t(last_cam_pos - half_resolution - Vector2(GV.TILE_LOAD_BUFFER, GV.TILE_LOAD_BUFFER));
	loaded_pos_t_max = GV.world_to_pos_t(last_cam_pos + half_resolution + Vector2(GV.TILE_LOAD_BUFFER, GV.TILE_LOAD_BUFFER));
	initial_tile_count = (loaded_pos_t_max.x - loaded_pos_t_min.x + 1) * (loaded_pos_t_max.y - loaded_pos_t_min.y + 1);
	print("INITIAL TILE COUNT: ", initial_tile_count);
	enqueue_for_load(loaded_pos_t_min, loaded_pos_t_max);
	
	#start thread
	load_start_time = Time.get_ticks_usec();
	thread.start(generate_tiles);

func _on_cell_ready():
	if initial_ready_count < initial_tile_count:
		initial_ready_count += 1;
		if initial_ready_count == initial_tile_count:
			initial_tiles_ready = true;
			initial_tiles_readied.emit();
			load_end_time = Time.get_ticks_usec();
			print("initial load time: ", load_end_time - load_start_time);

func _process(_delta):
	var process_start_time:int = Time.get_ticks_usec();
	
	#mark chunks for load/unload based on camera pos
	if initial_tiles_ready and $TrackingCam.position != last_cam_pos:
		#update loaded_pos_c_min, loaded_pos_c_max, load_queue, unload_queue
		var temp_pos_t_min:Vector2i = loaded_pos_t_min;
		var temp_pos_t_max:Vector2i = loaded_pos_t_max;
		var track_dir:Vector2i = ($TrackingCam.position - last_cam_pos).sign();
		if track_dir.x:
			var load_min_x:float = $TrackingCam.position.x - half_resolution.x - (GV.TILE_LOAD_BUFFER if track_dir.x < 0 else GV.TILE_UNLOAD_BUFFER);
			var load_max_x:float = $TrackingCam.position.x + half_resolution.x + (GV.TILE_LOAD_BUFFER if track_dir.x > 0 else GV.TILE_UNLOAD_BUFFER);
			temp_pos_t_min.x = GV.world_to_xt(load_min_x);
			temp_pos_t_max.x = GV.world_to_xt(load_max_x);
		if track_dir.y:
			var load_min_y:float = $TrackingCam.position.y - half_resolution.y - (GV.TILE_LOAD_BUFFER if track_dir.y < 0 else GV.TILE_UNLOAD_BUFFER);
			var load_max_y:float = $TrackingCam.position.y + half_resolution.y + (GV.TILE_LOAD_BUFFER if track_dir.y > 0 else GV.TILE_UNLOAD_BUFFER);
			temp_pos_t_min.y = GV.world_to_xt(load_min_y);
			temp_pos_t_max.y = GV.world_to_xt(load_max_y);
		update_queues(loaded_pos_t_min, loaded_pos_t_max, temp_pos_t_min, temp_pos_t_max);
		loaded_pos_t_min = temp_pos_t_min;
		loaded_pos_t_max = temp_pos_t_max;
		
		#update last_cam_pos
		last_cam_pos = $TrackingCam.position;
	
	#add tiles to active tree
#	var tiles:Array[ScoreTile];
#	constructed_mutex.lock();
#	var tile_positions:Array = constructed_queue.keys().slice(0, max_tiles_per_frame);
#	for pos_t in tile_positions:
#		tiles.push_back(constructed_queue[pos_t]);
#		constructed_queue.erase(pos_t);
#	constructed_mutex.unlock();
#
#	for tile in tiles:
#		add_child(tile);
	
	#pool unloaded tiles
	var pool_positions:Array = pool_queue.keys().slice(0, max_tiles_per_frame);
	for pos_t in pool_positions:
		pool_queue.erase(pos_t);
		loaded_mutex.lock();
		var tile:ScoreTile = loaded_tiles[pos_t];
		loaded_tiles.erase(pos_t);
		loaded_mutex.unlock();
		pool_tile(tile);
	
	var process_end_time:int = Time.get_ticks_usec();
	print("process time: ", process_end_time - process_start_time);

#assume rects are inclusive and valid
func update_queues(old_pos_t_min:Vector2i, old_pos_t_max:Vector2i, new_pos_t_min:Vector2i, new_pos_t_max:Vector2i):
	var overlap_min:Vector2i = Vector2i(maxi(old_pos_t_min.x, new_pos_t_min.x), maxi(old_pos_t_min.y, new_pos_t_min.y));
	var overlap_max:Vector2i = Vector2i(mini(old_pos_t_max.x, new_pos_t_max.x), mini(old_pos_t_max.y, new_pos_t_max.y));
	if overlap_min.x > overlap_max.x or overlap_min.y > overlap_max.y: #no overlap
		enqueue_for_load(new_pos_t_min, new_pos_t_max);
		enqueue_for_unload(old_pos_t_min, old_pos_t_max);
	
	#old rect
	enqueue_for_unload(old_pos_t_min, Vector2i(old_pos_t_max.x, overlap_min.y - 1));
	enqueue_for_unload(Vector2i(old_pos_t_min.x, overlap_min.y), Vector2i(overlap_min.x - 1, overlap_max.y));
	enqueue_for_unload(Vector2i(overlap_max.x + 1, overlap_min.y), Vector2i(old_pos_t_max.x, overlap_max.y));
	enqueue_for_unload(Vector2i(old_pos_t_min.x, overlap_max.y + 1), old_pos_t_max);
	
	#new rect
	enqueue_for_load(new_pos_t_min, Vector2i(new_pos_t_max.x, overlap_min.y - 1));
	enqueue_for_load(Vector2i(new_pos_t_min.x, overlap_min.y), Vector2i(overlap_min.x - 1, overlap_max.y));
	enqueue_for_load(Vector2i(overlap_max.x + 1, overlap_min.y), Vector2i(new_pos_t_max.x, overlap_max.y));
	enqueue_for_load(Vector2i(new_pos_t_min.x, overlap_max.y + 1), new_pos_t_max);
	
	#post
	#semaphore.post();

func enqueue_for_load(pos_t_min:Vector2i, pos_t_max:Vector2i):
	#print("enqueue for load: ", pos_t_min, pos_t_max);
	for ty in range(pos_t_min.y, pos_t_max.y + 1):
		for tx in range(pos_t_min.x, pos_t_max.x + 1):
			var pos_t:Vector2i = Vector2i(tx, ty);
#			queue_mutex.lock();
#			if unload_queue.has(pos_t):
#				unload_queue.erase(pos_t);
#			else:
#				load_queue[pos_t] = true;
#				semaphore.post();
#			queue_mutex.unlock();
			
			if pool_queue.has(pos_t):
				pool_queue.erase(pos_t);
				continue;
			
#			if constructed_chunks.has(pos_t):
#				continue;
			
			load_mutex.lock();
			load_queue[pos_t] = true;
			load_mutex.unlock();
			semaphore.post();

func enqueue_for_unload(pos_t_min:Vector2i, pos_t_max:Vector2i):
	#print("unload ", pos_t_min, pos_t_max);
	for ty in range(pos_t_min.y, pos_t_max.y + 1):
		for tx in range(pos_t_min.x, pos_t_max.x + 1):
			var pos_t:Vector2i = Vector2i(tx, ty);
#			queue_mutex.lock();
#			if load_queue.has(pos_t):
#				load_queue.erase(pos_t);
#			else:
#				unload_queue[pos_t] = true;
#				semaphore.post();
#			queue_mutex.unlock();
			
			load_mutex.lock();
			if load_queue.has(pos_t):
				load_queue.erase(pos_t);
				load_mutex.unlock();
				continue;
			load_mutex.unlock();
			
			#queue for pool
			if loaded_tiles.has(pos_t):
				pool_queue[pos_t] = true;

#CM entry function
func generate_tiles():
	Thread.set_thread_safety_checks_enabled(false);
	var initial_load_count:int = 0;
	
	while true:
		semaphore.wait(); #wait
		
		#check for exit
		exit_mutex.lock();
		var should_exit = exit_thread;
		exit_mutex.unlock();
		if should_exit:
			break;
		
		#load tiles
		load_mutex.lock();
		var load_positions:Array = load_queue.keys();
		load_queue.clear();
		load_mutex.unlock();
		for pos_t in load_positions:
			var tile:ScoreTile = generate_cell(pos_t);
			if tile != null:
				loaded_mutex.lock();
				loaded_tiles[pos_t] = tile;
				loaded_mutex.unlock();
		initial_load_count = min(initial_tile_count, initial_load_count + load_positions.size());
		
		#flag, signal
		initial_mutex.lock();
		if not initial_tiles_generated and initial_load_count == initial_tile_count:
			initial_tiles_generated = true;
			call_deferred("emit_signal", "initial_tiles_gennied");
		initial_mutex.unlock();

#inits a tile in constructed_tiles or updates tilemap accordingly
func generate_cell(pos_t:Vector2i) -> ScoreTile:
	#print("generate tile ", global_tile_pos);
	var n_wall:float = wall_noise.get_noise_2d(pos_t.x, pos_t.y); #[-1, 1]
	if absf(n_wall) < 0.009:
		$Walls.set_cell(0, pos_t, 2, Vector2i.ZERO);
		initial_ready_count += 1;
		return null;
	if absf(n_wall) < 0.02:
		$Walls.set_cell(0, pos_t, 1, Vector2i.ZERO);
		initial_ready_count += 1;
		return null;
	
	#tile, position
	var tile:ScoreTile = get_tile();
	tile.position = GV.pos_t_to_world(pos_t);
	
	#set power, ssign; this may set ssign of zero as -1
	var n_tile:float = tile_noise.get_noise_2d(pos_t.x, pos_t.y); #[-1, 1]
	tile.ssign = int(signf(n_tile));
	n_tile = pow(absf(n_tile), 1); #use this step to bias toward/away from 0
	tile.power = GV.TILE_GEN_POW_MAX if (n_tile == 1.0) else int((GV.TILE_GEN_POW_MAX + 2) * n_tile) - 1;

	#re-enable tile collision
	tile.get_node("CollisionPolygon2D").disabled = false;
	tile.initialize();

	return tile;
	#debug
	#if Vector2i(tx, ty) == Vector2i(0, 1):
	#	tile.debug = true;

func load_player():
	#remove wall/tile at cell
	loaded_mutex.lock();
	if loaded_tiles.has(player_global_spawn_pos_t):
		var tile:ScoreTile = loaded_tiles[player_global_spawn_pos_t];
		loaded_tiles.erase(player_global_spawn_pos_t);
		loaded_mutex.unlock();
		pool_tile(tile);
	else:
		loaded_mutex.unlock();
	$Walls.set_cell(0, player_global_spawn_pos_t, -1, Vector2i.ZERO);
	
	#add player
	var player:ScoreTile = score_tile.instantiate();
	player.position = GV.pos_t_to_world(player_global_spawn_pos_t);
	player.is_player = true;
	player.power = -1;
	player.ssign = 1;
	scoretiles.add_child(player);

#called from CM
#returned tile is already child of level
func get_tile() -> ScoreTile:
	if not tile_pool.is_empty(): #retrieve from tile_pool
		var tile = tile_pool.pop_back();
		tile.show();
		tile.set_process_mode(PROCESS_MODE_INHERIT);
		return tile;
	
	#instantiate new tile
	var tile:ScoreTile = score_tile.instantiate();
	tile.ready.connect(_on_cell_ready);
	scoretiles.call_deferred("add_child", tile);
	print("ADD TILE");
	return tile;

#called from main
func pool_tile(tile:ScoreTile):
	tile.hide();
	tile.set_process_mode(PROCESS_MODE_DISABLED);
	tile.get_node("CollisionPolygon2D").disabled = true;
	tile.snapshot_locations.clear();
	tile.snapshot_locations_new.clear();
	if tile.is_player:
		tile.tile_settings();
	tile.is_player = false;
	tile.is_hostile = false;
	tile.debug = false;
	tile_pool.push_back(tile);

func contains_world_border(pos_c:Vector2i) -> bool:
	if pos_c.x == GV.BORDER_MIN_POS_C.x or pos_c.x == GV.BORDER_MAX_POS_C.x:
		if pos_c.y >= GV.BORDER_MIN_POS_C.y and pos_c.y <= GV.BORDER_MAX_POS_C.y:
			return true;
	if pos_c.y == GV.BORDER_MIN_POS_C.y or pos_c.y == GV.BORDER_MAX_POS_C.y:
		if pos_c.x >= GV.BORDER_MIN_POS_C.x and pos_c.x <= GV.BORDER_MAX_POS_C.x:
			return true;
	return false;

func is_world_border(pos_t:Vector2i) -> bool:
	if pos_t.x == GV.BORDER_MIN_POS_T.x or pos_t.x == GV.BORDER_MAX_POS_T.x:
		if pos_t.y >= GV.BORDER_MIN_POS_T.y and pos_t.y <= GV.BORDER_MAX_POS_T.y:
			return true;
	if pos_t.y == GV.BORDER_MIN_POS_T.y or pos_t.y == GV.BORDER_MAX_POS_T.y:
		if pos_t.x >= GV.BORDER_MIN_POS_T.x and pos_t.x <= GV.BORDER_MAX_POS_T.x:
			return true;
	return false;

func set_level_name():
	if $ParallaxBackground/Background.has_node("LevelName"):
		game.current_level_name = $ParallaxBackground/Background/LevelName;
		game.current_level_name.modulate.a = 0;
	else:
		game.current_level_name = null;

func _exit_tree():
	#set exit condition
	exit_mutex.lock();
	exit_thread = true;
	exit_mutex.unlock();
	
	#unblock thread
	semaphore.post();
	
	#collect thread
	thread.wait_to_finish();
