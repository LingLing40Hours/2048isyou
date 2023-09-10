extends Level

const CM_TILE_GEN_POW_MAX = GV.TILE_GEN_POW_MAX;

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");
var packed_chunk:PackedScene = preload("res://Levels/Chunk.tscn");
var tile_noise = FastNoiseLite.new();
var wall_noise = FastNoiseLite.new();
var difficulty:float = 0; #probability of hostile, noise roughness

var semaphore:Semaphore;
var thread:Thread; #handles chunk loading/unloading
#var load_mutex:Mutex;
#var unload_mutex:Mutex;
var queue_mutex:Mutex;
var initial_mutex:Mutex;
var exit_mutex:Mutex;
var exit_thread:bool = false;

var initial_chunks_loaded:bool;
var load_queue:Dictionary; #use dictionary for faster lookup than array (in enqueue functions)
var unload_queue:Dictionary;
var modified_chunks:Dictionary; #chunk_pos:Vector2i, Chunk
#var constructed_chunks:Array[Chunk]; #chunks waiting to enter scene tree
var loaded_chunks:Dictionary;
var loaded_pos_c_min:Vector2i;
var loaded_pos_c_max:Vector2i; #inclusive

var load_start_time:int;
var load_end_time:int;

@onready var last_cam_pos:Vector2 = $TrackingCam.position;
@onready var walls:TileMap = $Walls; #for use in thread


func _ready():
	super._ready();
	
	#set chunked mode
	chunked = true;
	
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
	#load_mutex = Mutex.new();
	#unload_mutex = Mutex.new();
	queue_mutex = Mutex.new();
	initial_mutex = Mutex.new();
	exit_mutex = Mutex.new();
	semaphore = Semaphore.new();
	exit_thread = false;
	thread = Thread.new();
	#thread.set_thread_safety_checks_enabled(false);
	
	#load initial chunks
	initial_chunks_loaded = false;
	loaded_pos_c_min = GV.world_to_pos_c(last_cam_pos - half_resolution - Vector2(GV.CHUNK_LOAD_BUFFER, GV.CHUNK_LOAD_BUFFER));
	loaded_pos_c_max = GV.world_to_pos_c(last_cam_pos + half_resolution + Vector2(GV.CHUNK_LOAD_BUFFER, GV.CHUNK_LOAD_BUFFER));
	enqueue_for_load(loaded_pos_c_min, loaded_pos_c_max);
	
	#start thread
	load_start_time = Time.get_ticks_usec();
	thread.start(_manage_chunks);

func _process(_delta):
	initial_mutex.lock();
	var should_process:bool = initial_chunks_loaded;
	initial_mutex.unlock();
	if should_process and $TrackingCam.position != last_cam_pos:
		#update loaded_pos_c_min, loaded_pos_c_max, load_queue, unload_queue
		var temp_pos_c_min:Vector2i = loaded_pos_c_min;
		var temp_pos_c_max:Vector2i = loaded_pos_c_max;
		var track_dir:Vector2i = ($TrackingCam.position - last_cam_pos).sign();
		if track_dir.x:
			var load_min_x:float = $TrackingCam.position.x - half_resolution.x - GV.CHUNK_LOAD_BUFFER if track_dir.x < 0 else GV.CHUNK_UNLOAD_BUFFER;
			var load_max_x:float = $TrackingCam.position.x + half_resolution.x + GV.CHUNK_LOAD_BUFFER if track_dir.x > 0 else GV.CHUNK_UNLOAD_BUFFER;
			temp_pos_c_min.x = GV.world_to_xc(load_min_x);
			temp_pos_c_max.x = GV.world_to_xc(load_max_x);
		if track_dir.y:
			var load_min_y:float = $TrackingCam.position.y - half_resolution.y - GV.CHUNK_LOAD_BUFFER if track_dir.y < 0 else GV.CHUNK_UNLOAD_BUFFER;
			var load_max_y:float = $TrackingCam.position.y + half_resolution.y + GV.CHUNK_LOAD_BUFFER if track_dir.y > 0 else GV.CHUNK_UNLOAD_BUFFER;
			temp_pos_c_min.y = GV.world_to_xc(load_min_y);
			temp_pos_c_max.y = GV.world_to_xc(load_max_y);
		update_chunk_queues(loaded_pos_c_min, loaded_pos_c_max, temp_pos_c_min, temp_pos_c_max);
		loaded_pos_c_min = temp_pos_c_min;
		loaded_pos_c_max = temp_pos_c_max;
		
		#update last_cam_pos
		last_cam_pos = $TrackingCam.position;

#assume rects are inclusive and valid
func update_chunk_queues(old_pos_c_min:Vector2i, old_pos_c_max:Vector2i, new_pos_c_min:Vector2i, new_pos_c_max:Vector2i):
	var overlap_min:Vector2i = Vector2i(maxi(old_pos_c_min.x, new_pos_c_min.x), maxi(old_pos_c_min.y, new_pos_c_min.y));
	var overlap_max:Vector2i = Vector2i(mini(old_pos_c_max.x, new_pos_c_max.x), mini(old_pos_c_max.y, new_pos_c_max.y));
	if overlap_min.x > overlap_max.x or overlap_min.y > overlap_max.y: #no overlap
		enqueue_for_load(new_pos_c_min, new_pos_c_max);
		enqueue_for_unload(old_pos_c_min, old_pos_c_max);
	
	#old rect
	enqueue_for_unload(old_pos_c_min, Vector2i(old_pos_c_max.x, overlap_min.y - 1));
	enqueue_for_unload(Vector2i(old_pos_c_min.x, overlap_min.y), Vector2i(overlap_min.x - 1, overlap_max.y));
	enqueue_for_unload(Vector2i(overlap_max.x + 1, overlap_min.y), Vector2i(old_pos_c_max.x, overlap_max.y));
	enqueue_for_unload(Vector2i(old_pos_c_min.x, overlap_max.y + 1), old_pos_c_max);
	
	#new rect
	enqueue_for_load(new_pos_c_min, Vector2i(new_pos_c_max.x, overlap_min.y - 1));
	enqueue_for_load(Vector2i(new_pos_c_min.x, overlap_min.y), Vector2i(overlap_min.x - 1, overlap_max.y));
	enqueue_for_load(Vector2i(overlap_max.x + 1, overlap_min.y), Vector2i(new_pos_c_max.x, overlap_max.y));
	enqueue_for_load(Vector2i(new_pos_c_min.x, overlap_max.y + 1), new_pos_c_max);
	
	#post
	#semaphore.post();

func enqueue_for_load(pos_c_min:Vector2i, pos_c_max:Vector2i):
	for cy in range(pos_c_min.y, pos_c_max.y + 1):
		for cx in range(pos_c_min.x, pos_c_max.x + 1):
			var pos_c:Vector2i = Vector2i(cx, cy);
			queue_mutex.lock();
			if unload_queue.has(pos_c):
				unload_queue.erase(pos_c);
			else:
				load_queue[pos_c] = true;
			queue_mutex.unlock();
	semaphore.post();
			
#			unload_mutex.lock();
#			if unload_queue.has(pos_c):
#				unload_queue.erase(pos_c);
#				unload_mutex.unlock();
#				continue;
#			unload_mutex.unlock();
#
#			load_mutex.lock();
#			load_queue[pos_c] = true;
#			load_mutex.unlock();
#			semaphore.post();

func enqueue_for_unload(pos_c_min:Vector2i, pos_c_max:Vector2i):
	for cy in range(pos_c_min.y, pos_c_max.y + 1):
		for cx in range(pos_c_min.x, pos_c_max.x + 1):
			var pos_c:Vector2i = Vector2i(cx, cy);
			queue_mutex.lock();
			if load_queue.has(pos_c):
				load_queue.erase(pos_c);
			else:
				unload_queue[pos_c] = true;
			queue_mutex.unlock();
	semaphore.post();
			
#			load_mutex.lock();
#			if load_queue.has(pos_c):
#				load_queue.erase(pos_c);
#				load_mutex.unlock();
#				continue;
#			load_mutex.unlock();
#
#			unload_mutex.lock();
#			unload_queue[pos_c] = true;
#			unload_mutex.unlock();
#			semaphore.post();

#based on camera position
func _manage_chunks():
	Thread.set_thread_safety_checks_enabled(false);
	while true:
		semaphore.wait(); #wait
		
		#check for exit
		exit_mutex.lock();
		var should_exit = exit_thread;
		exit_mutex.unlock();
		if should_exit:
			break;
		
		#unload chunks
		var unload_positions:Array = unload_queue.keys();
		queue_mutex.lock();
		unload_queue.clear();
		queue_mutex.unlock();
		#print("unload_positions: ", unload_positions);
		for pos_c in unload_positions:
			loaded_chunks[pos_c].queue_free();
			loaded_chunks.erase(pos_c);
		
		#load chunks
		var load_positions:Array = load_queue.keys();
		queue_mutex.lock();
		load_queue.clear();
		queue_mutex.unlock();
		#print("load_positions: ", load_positions);
		for pos_c in load_positions:
			var chunk:Chunk = generate_chunk(pos_c);
			call_deferred("add_child", chunk);
			loaded_chunks[pos_c] = chunk;
		
		initial_mutex.lock();
		initial_chunks_loaded = true;
		initial_mutex.unlock();
		
		#debug
		load_end_time = Time.get_ticks_usec();
		print("LOAD TIME: ", load_end_time - load_start_time);
	
func generate_chunk(chunk_pos:Vector2i) -> Chunk:
	#var dt = Time.get_ticks_usec();
	#print(dt, "generate chunk ", chunk_pos);
	var ans:Chunk = packed_chunk.instantiate();
	ans.pos_c = chunk_pos;
	#ans.call_deferred("set_position", GV.pos_c_to_world(chunk_pos));
	ans.position = GV.pos_c_to_world(chunk_pos);
	var start_tile_pos:Vector2i = GV.pos_c_to_pos_t(chunk_pos);
	
	for tx in GV.CHUNK_WIDTH_T:
		var global_tx:int = start_tile_pos.x + tx;
		for ty in GV.CHUNK_WIDTH_T:
			generate_tile(ans, Vector2i(global_tx, start_tile_pos.y + ty), Vector2i(tx, ty));
#	if chunk_pos == Vector2i.ONE:
#		load_end_time = Time.get_ticks_usec();
#		print("LOAD TIME: ", load_end_time - load_start_time);
	return ans;

#updates chunk cells and if tile, adds to chunk as child
func generate_tile(chunk:Chunk, global_tile_pos:Vector2i, local_tile_pos:Vector2i):
	#print("generate tile ", global_tile_pos);
	if global_tile_pos == Vector2i.ZERO: #player
		chunk.cells[local_tile_pos.y][local_tile_pos.x] = GV.StuffId.POS_ONE;
		
		var player = score_tile.instantiate();
		#player.call_deferred("set_position", GV.pos_t_to_world(local_tile_pos)); #relative
		player.position = GV.pos_t_to_world(local_tile_pos);
		player.is_player = true;
		player.power = 0;
		player.ssign = 1;
		chunk.add_child(player);
		#chunk.call_deferred("add_child", player);
		#print("player instantiated");
		return;
	
	var n_wall:float = wall_noise.get_noise_2d(global_tile_pos.x, global_tile_pos.y); #[-1, 1]
	if absf(n_wall) < 0.009:
		walls.set_cell(0, global_tile_pos, 0, Vector2i.ZERO);
		chunk.cells[local_tile_pos.y][local_tile_pos.x] = GV.StuffId.BLACK_WALL;
		#print("black instantiated");
		return;
	if absf(n_wall) < 0.02:
		walls.set_cell(0, global_tile_pos, 1, Vector2i.ZERO);
		chunk.cells[local_tile_pos.y][local_tile_pos.x] = GV.StuffId.MEMBRANE;
		#print("membrane instantiated");
		return;
	
	#tile, position
	var tile:ScoreTile = score_tile.instantiate();
	#mutex.lock(); exit_thread = true; mutex.unlock(); return; #debug
	#tile.call_deferred("set_position", GV.pos_t_to_world(local_tile_pos));
	tile.position = GV.pos_t_to_world(local_tile_pos);
	
	#set power, ssign; this may set ssign of zero as -1
	var n_tile:float = tile_noise.get_noise_2d(global_tile_pos.x, global_tile_pos.y); #[-1, 1]
	tile.ssign = int(signf(n_tile));
	n_tile = pow(absf(n_tile), 1); #use this step to bias toward/away from 0
	tile.power = CM_TILE_GEN_POW_MAX if (n_tile == 1.0) else int((CM_TILE_GEN_POW_MAX + 2) * n_tile) - 1;
	
	#set chunk cells
	chunk.cells[local_tile_pos.y][local_tile_pos.x] = GV.tile_val_to_id(tile.power, tile.ssign);
	
	#add tile
	chunk.add_child(tile);
	#chunk.call_deferred("add_child", tile);

	#debug
	#if Vector2i(tx, ty) == Vector2i(0, 1):
	#	tile.debug = true;

func _exit_tree():
	#set exit condition
	exit_mutex.lock();
	exit_thread = true;
	exit_mutex.unlock();
	
	#unblock thread
	semaphore.post();
	
	#collect thread
	thread.wait_to_finish();
