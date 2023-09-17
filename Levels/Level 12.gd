extends Level

signal initial_chunks_instanced;
signal initial_chunks_readied;
var initial_chunks_instantiated:bool; #shared
var initial_chunks_ready:bool;
var initial_chunk_count:int; #main then chunker
var initial_ready_count:int;

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");
var packed_chunk:PackedScene = preload("res://Levels/Chunk.tscn");
var tile_noise = FastNoiseLite.new();
var wall_noise = FastNoiseLite.new();
var difficulty:float = 0; #probability of hostile, noise roughness

var semaphore:Semaphore;
var thread:Thread; #handles chunk loading/unloading
var load_mutex:Mutex;
var unload_mutex:Mutex;
var initial_mutex:Mutex;
var instanced_mutex:Mutex;
var loaded_mutex:Mutex;
var exit_mutex:Mutex;
var exit_thread:bool = false;

#chunk_pos_c:Vector2i, bool
var load_queue:Dictionary; #shared; dict for fast lookup
var unload_queue:Dictionary; #shared

#chunk_pos_c:Vector2i, chunk:Chunk
var modified_chunks:Dictionary; #chunks modified by gameplay
var instanced_chunks:Dictionary; #chunks waiting to enter scene tree
var loaded_chunks:Dictionary; #CM thread; chunks both instanced and added to active tree

#bounding rect
var loaded_pos_c_min:Vector2i;
var loaded_pos_c_max:Vector2i; #inclusive

var load_start_time:int;
var load_end_time:int;
var player_global_spawn_pos_t:Vector2i = Vector2i.ZERO;
var player_local_spawn_pos_t:Vector2i = player_global_spawn_pos_t % GV.CHUNK_WIDTH_T;

@onready var last_cam_pos:Vector2 = $TrackingCam.position;


func _enter_tree():
	super._enter_tree();
	#set position bounds (before tracking cam _ready())
	min_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MIN, GV.INT64_MIN);
	max_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MAX, GV.INT64_MAX);

func _ready():
	chunked = true;
	super._ready();
	
	#load player
	initial_chunks_readied.connect(load_player);
	
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
	unload_mutex = Mutex.new();
	initial_mutex = Mutex.new();
	instanced_mutex = Mutex.new();
	loaded_mutex = Mutex.new();
	exit_mutex = Mutex.new();
	semaphore = Semaphore.new();
	exit_thread = false;
	thread = Thread.new();
	
	#load initial chunks
	initial_chunks_instantiated = false;
	initial_chunks_ready = false;
	initial_ready_count = 0;
	loaded_pos_c_min = GV.world_to_pos_c(last_cam_pos - half_resolution - Vector2(GV.CHUNK_LOAD_BUFFER, GV.CHUNK_LOAD_BUFFER));
	loaded_pos_c_max = GV.world_to_pos_c(last_cam_pos + half_resolution + Vector2(GV.CHUNK_LOAD_BUFFER, GV.CHUNK_LOAD_BUFFER));
	initial_chunk_count = (loaded_pos_c_max.x - loaded_pos_c_min.x + 1) * (loaded_pos_c_max.y - loaded_pos_c_min.y + 1);
	print("INITIAL CHUNK COUNT: ", initial_chunk_count);
	enqueue_for_load(loaded_pos_c_min, loaded_pos_c_max);
	
	#start thread
	load_start_time = Time.get_ticks_usec();
	thread.start(manage_chunks);

func _on_chunk_ready():
	if initial_ready_count < initial_chunk_count:
		initial_ready_count += 1;
		if initial_ready_count == initial_chunk_count:
			initial_chunks_readied.emit();
			load_end_time = Time.get_ticks_usec();
			print("initial load time: ", load_end_time - load_start_time);

func _process(_delta):
	#mark chunks for load/unload based on camera pos
	initial_mutex.lock();
	var ic_loaded:bool = initial_chunks_instantiated;
	initial_mutex.unlock();
	if ic_loaded and $TrackingCam.position != last_cam_pos:
		#update loaded_pos_c_min, loaded_pos_c_max, load_queue, unload_queue
		var temp_pos_c_min:Vector2i = loaded_pos_c_min;
		var temp_pos_c_max:Vector2i = loaded_pos_c_max;
		var track_dir:Vector2i = ($TrackingCam.position - last_cam_pos).sign();
		if track_dir.x:
			var load_min_x:float = $TrackingCam.position.x - half_resolution.x - (GV.CHUNK_LOAD_BUFFER if track_dir.x < 0 else GV.CHUNK_UNLOAD_BUFFER);
			var load_max_x:float = $TrackingCam.position.x + half_resolution.x + (GV.CHUNK_LOAD_BUFFER if track_dir.x > 0 else GV.CHUNK_UNLOAD_BUFFER);
			temp_pos_c_min.x = GV.world_to_xc(load_min_x);
			temp_pos_c_max.x = GV.world_to_xc(load_max_x);
		if track_dir.y:
			var load_min_y:float = $TrackingCam.position.y - half_resolution.y - (GV.CHUNK_LOAD_BUFFER if track_dir.y < 0 else GV.CHUNK_UNLOAD_BUFFER);
			var load_max_y:float = $TrackingCam.position.y + half_resolution.y + (GV.CHUNK_LOAD_BUFFER if track_dir.y > 0 else GV.CHUNK_UNLOAD_BUFFER);
			temp_pos_c_min.y = GV.world_to_xc(load_min_y);
			temp_pos_c_max.y = GV.world_to_xc(load_max_y);
		update_chunk_queues(loaded_pos_c_min, loaded_pos_c_max, temp_pos_c_min, temp_pos_c_max);
		loaded_pos_c_min = temp_pos_c_min;
		loaded_pos_c_max = temp_pos_c_max;
		
		#update last_cam_pos
		last_cam_pos = $TrackingCam.position;
	
	#add an instanced chunk to active tree (all at once is too much to handle in one frame)
	if not instanced_chunks.is_empty():
		var load_pos:Vector2i = instanced_chunks.keys().back();
		call_deferred("add_chunk", load_pos, instanced_chunks[load_pos]); #defer bc this is slow

func add_chunk(pos_c:Vector2i, chunk:Chunk):
	add_child(chunk);
	
	#move chunk from instanced to loaded
	instanced_mutex.lock();
	instanced_chunks.erase(pos_c);
	instanced_mutex.unlock();
	loaded_mutex.lock();
	loaded_chunks[pos_c] = chunk;
	loaded_mutex.unlock();

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
#			queue_mutex.lock();
#			if unload_queue.has(pos_c):
#				unload_queue.erase(pos_c);
#			else:
#				load_queue[pos_c] = true;
#				semaphore.post();
#			queue_mutex.unlock();
			
			unload_mutex.lock();
			if unload_queue.has(pos_c):
				unload_queue.erase(pos_c);
				unload_mutex.unlock();
				continue;
			unload_mutex.unlock();
			
			if instanced_chunks.has(pos_c):
				continue;
			
			load_mutex.lock();
			load_queue[pos_c] = true;
			load_mutex.unlock();
			semaphore.post();

func enqueue_for_unload(pos_c_min:Vector2i, pos_c_max:Vector2i):
	#print("unload ", pos_c_min, pos_c_max);
	for cy in range(pos_c_min.y, pos_c_max.y + 1):
		for cx in range(pos_c_min.x, pos_c_max.x + 1):
			var pos_c:Vector2i = Vector2i(cx, cy);
#			queue_mutex.lock();
#			if load_queue.has(pos_c):
#				load_queue.erase(pos_c);
#			else:
#				unload_queue[pos_c] = true;
#				semaphore.post();
#			queue_mutex.unlock();
			
			load_mutex.lock();
			if load_queue.has(pos_c):
				load_queue.erase(pos_c);
				load_mutex.unlock();
				continue;
			load_mutex.unlock();
			
			instanced_mutex.lock();
			if instanced_chunks.has(pos_c): #move to loaded_chunks
				var chunk:Chunk = instanced_chunks[pos_c];
				instanced_chunks.erase(pos_c);
				instanced_mutex.unlock();
				loaded_mutex.lock();
				loaded_chunks[pos_c] = chunk;
				loaded_mutex.unlock();
			else:
				instanced_mutex.unlock();
			
			#mark for unload
			unload_mutex.lock();
			unload_queue[pos_c] = true;
			unload_mutex.unlock();
			semaphore.post();

#based on camera position
func manage_chunks():
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
		
		#unload chunks
		unload_mutex.lock();
		if not unload_queue.is_empty():
			var unload_pos:Vector2i = unload_queue.keys().back();
			unload_queue.erase(unload_pos);
			unload_mutex.unlock();
			#print("unload_positions: ", unload_positions);
			loaded_mutex.lock();
			loaded_chunks[unload_pos].queue_free();
			loaded_chunks.erase(unload_pos);
			loaded_mutex.unlock();
		else:
			unload_mutex.unlock();
		
		#load chunks
		load_mutex.lock();
		if not load_queue.is_empty():
			var load_pos:Vector2i = load_queue.keys().back();
			load_queue.erase(load_pos);
			load_mutex.unlock();
			#print("load_positions: ", load_positions);
			var chunk:Chunk = instantiate_chunk(load_pos);
			instanced_mutex.lock();
			instanced_chunks[load_pos] = chunk;
			instanced_mutex.unlock();
			if initial_load_count < initial_chunk_count:
				initial_load_count += 1;
		else:
			load_mutex.unlock();
		
		#flag, signal
		initial_mutex.lock();
		if not initial_chunks_instantiated and initial_load_count == initial_chunk_count:
			initial_chunks_instantiated = true;
			call_deferred("emit_signal", "initial_chunks_instanced");
		initial_mutex.unlock();
	
func instantiate_chunk(chunk_pos:Vector2i) -> Chunk:
	#print("generate chunk ", chunk_pos); #print in thread is slow
	var start_time:int = Time.get_ticks_usec();
	
	#get cell function
	var func_cell_str:String = "instantiate_cell_or_border" if contains_world_border(chunk_pos) else "instantiate_cell";
	var func_cell:Callable = Callable(self, func_cell_str);
	
	var ans:Chunk = packed_chunk.instantiate();
	ans.pos_c = chunk_pos;
	#ans.call_deferred("set_position", GV.pos_c_to_world(chunk_pos));
	ans.position = GV.pos_c_to_world(chunk_pos);
	var start_tile_pos:Vector2i = GV.pos_c_to_pos_t(chunk_pos);
	
	#connect ready to increment_ready_count
	ans.ready.connect(_on_chunk_ready);
	
	for tx in GV.CHUNK_WIDTH_T:
		var global_tx:int = start_tile_pos.x + tx;
		for ty in GV.CHUNK_WIDTH_T:
			func_cell.call(ans, Vector2i(global_tx, start_tile_pos.y + ty), Vector2i(tx, ty));
	
	var end_time:int = Time.get_ticks_usec();
	print("chunk instance time: ", end_time - start_time);
	return ans;

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
		if pos_t.x >= GV.BORDER_MIN_POST_T.x and pos_t.x <= GV.BORDER_MAX_POS_T.x:
			return true;
	return false;

func instantiate_cell_or_border(chunk:Chunk, global_tile_pos:Vector2i, local_tile_pos:Vector2i):
	if is_world_border(global_tile_pos):
		

#updates chunk cells; add tile as child or updates tilemap accordingly
func instantiate_cell(chunk:Chunk, global_tile_pos:Vector2i, local_tile_pos:Vector2i):
	#print("generate tile ", global_tile_pos);
	var n_wall:float = wall_noise.get_noise_2d(global_tile_pos.x, global_tile_pos.y); #[-1, 1]
	if absf(n_wall) < 0.009:
		#$Walls.set_cell(0, global_tile_pos, 0, Vector2i.ZERO);
		chunk.get_node("Walls").set_cell(0, local_tile_pos, 0, Vector2i.ZERO);
		chunk.cells[local_tile_pos.y][local_tile_pos.x] = GV.StuffId.BLACK_WALL;
		#print("black instantiated");
		return;
	if absf(n_wall) < 0.02:
		#$Walls.set_cell(0, global_tile_pos, 1, Vector2i.ZERO);
		chunk.get_node("Walls").set_cell(0, local_tile_pos, 1, Vector2i.ZERO);
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
	tile.power = GV.TILE_GEN_POW_MAX if (n_tile == 1.0) else int((GV.TILE_GEN_POW_MAX + 2) * n_tile) - 1;
	
	#set chunk cells
	chunk.cells[local_tile_pos.y][local_tile_pos.x] = GV.tile_val_to_id(tile.power, tile.ssign);
	
	#add tile
	chunk.add_child(tile);
	#chunk.call_deferred("add_child", tile);

	#debug
	#if Vector2i(tx, ty) == Vector2i(0, 1):
	#	tile.debug = true;

func load_player():
	var chunk_pos_t:Vector2i = GV.pos_t_to_pos_c(player_global_spawn_pos_t);
	var chunk:Chunk = loaded_chunks.get(chunk_pos_t);
	if chunk != null:
		#remove wall/tile at cell
		chunk.get_node("Walls").set_cell(0, player_local_spawn_pos_t, -1, Vector2i.ZERO);
		for child in chunk.get_children():
			if child is ScoreTile and child.position == GV.pos_t_to_world(player_local_spawn_pos_t):
				child.queue_free();
		chunk.cells[player_local_spawn_pos_t.y][player_local_spawn_pos_t.x] = GV.StuffId.EMPTY;
		
		#add player
		var player:ScoreTile = score_tile.instantiate();
		player.position = GV.pos_t_to_world(player_local_spawn_pos_t);
		player.is_player = true;
		player.power = -1;
		player.ssign = 1;
		add_child(player);

func _exit_tree():
	#set exit condition
	exit_mutex.lock();
	exit_thread = true;
	exit_mutex.unlock();
	
	#unblock thread
	semaphore.post();
	
	#collect thread
	thread.wait_to_finish();
