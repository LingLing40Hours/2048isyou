extends Node

'''	move_and_slide()
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index);
		var collider := collision.get_collider();
		if collider.is_in_group("wall"):
			vx *= -1;
			vy *= -1;
			velocity.x = vx;
			velocity.y = vy;
		elif collider.is_in_group("player"):
			collider.die();'''

'''func _physics_process(delta):
	match state:
		States.SLIDING:
			#sliding into empty space
			slide_distance += slide_speed;
			if slide_distance >= GV.TILE_WIDTH:
				position = slide_target;
				state = States.IDLE;
				#re-enable collisions
				for i in range(1, 33):
					set_collision_layer_value(i, true);
			else:
				position += slide_step;
				
		States.MERGING:
			#sliding into partner
			slide_distance += slide_speed;
			if slide_distance >= GV.TILE_WIDTH:
				queue_free(); #done sliding
			else:
				if slide_distance >= GV.TILE_WIDTH/2 and not leveluped:
					partner.levelup();
					leveluped = true;
				position += slide_step;
			
		States.COMBINING:
			#fade out img, fade in new img, do scaling animation
			img.modulate.a -= fade_speed;
			new_img.modulate.a += fade_speed;
			
			if new_img.modulate.a >= duang_modulate: #do duang
				if duang_curr_angle >= duang_end_angle: #end of state
					#swap(img, new_img);
					img.scale = Vector2.ONE;
					state = States.IDLE;
				else:
					img.scale = Vector2.ONE * duang_factor * sin(duang_curr_angle);
					new_img.scale = img.scale;
					duang_curr_angle += duang_speed;
				
		States.IDLE:
			pass;'''

'''		if collider is ScoreTile:
			#slide if normal_dir and player_dir agree
			var slide_dir:Vector2 = collision.get_normal() * (-1);
			if abs(slide_dir.x) >= abs(slide_dir.y):
				#slide_dir.y = 0;
				if slide_dir.x > 0 and dir.x > 0:
					collider.slide(Vector2(1, 0));
				elif dir.x < 0:
					collider.slide(Vector2(-1, 0));
			else:
				#slide_dir.x = 0;
				if slide_dir.y > 0 and dir.y > 0:
					collider.slide(Vector2(0, 1));
				elif dir.y < 0:
					collider.slide(Vector2(0, -1));'''

'''
		if collider.is_in_group("wall"):
			if actor.is_player:
				var pos = collider.local_to_map(actor.position + ray.position + ray.target_position);
				var id = collider.get_cell_source_id(0, pos);
				obstructed = false if id == 1 else true;
			else:
				return true;
'''



'''
func slide(slide_dir:Vector2, collide_with_player:bool) -> bool:
	if get_state() != "tile" and get_state() != "snap":
		return false;
		
	#find ray in slide direction
	var ray:RayCast2D;
	if slide_dir == Vector2(1, 0):
		ray = $Ray1;
	elif slide_dir == Vector2(0, -1):
		ray = $Ray2;
	elif slide_dir == Vector2(-1, 0):
		ray = $Ray3;
	else:
		ray = $Ray4;
	
	#determine whether to slide or merge or, if obstructed, idle
	if ray.is_colliding():
		var collider := ray.get_collider();
		if collider.is_in_group("wall"): #obstructed
			return false;
		if collider is ScoreTile:
			if collider.power == power: #merge
				change_state("merging1");
				game.combine_sound.play();
				partner = collider;
				img.z_index -= 1;
			else:
				return false;
	else:
		change_state("sliding");
		game.slide_sound.play();
	
	#find slide parameters
	slide_distance = 0;
	velocity = slide_dir * slide_speed;
	slide_target = position + slide_dir * GV.TILE_WIDTH;
	
	#while sliding, disable collision with (non-player?) objects
	disable_collision(collide_with_player);
	
	return true;
'''

'''
func levelup():
	change_state("combining");
	power += 1;
	update_texture(new_img);
	new_img.modulate.a = 0;
	new_img.scale = Vector2.ONE;
	duang_curr_angle = duang_start_angle;
'''

'''
	if	focus_dir and (\
		Input.is_action_just_released("ui_left") or\
		Input.is_action_just_released("ui_right") or\
		Input.is_action_just_released("ui_up") or\
		Input.is_action_just_released("ui_down")):
			focus_dir = 0;
'''


'''
var focus_dir:int = 0; #-1 for x, 1 for y, 0 for neither
func _physics_process(_delta):
	#releasing direction key loses focus
	if focus_dir == -1 and (Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right")):
		focus_dir = 0;
	elif focus_dir == 1 and (Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down")):
		focus_dir = 0;
	
	#pressing direction key sets focus
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		focus_dir = -1;
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		focus_dir = 1;
'''

'''
	if next_state == null and not Input.is_action_pressed("cc"): #slide/merge
		if GV.focus_dir == -1:
			actor.slide_dir = Vector2(Input.get_axis("ui_left", "ui_right"), 0);
		elif GV.focus_dir == 1:
			actor.slide_dir = Vector2(0, Input.get_axis("ui_up", "ui_down"));
		
		if actor.slide_dir != Vector2.ZERO:
			actor.slide(actor.slide_dir);
'''

'''
	#split
	if next_state == null:
		if event.is_action_pressed("split_left"):
			actor.split(Vector2(-1, 0));
		elif event.is_action_pressed("split_right"):
			actor.split(Vector2(1, 0));
		elif event.is_action_pressed("split_up"):
			actor.split(Vector2(0, -1));
		elif event.is_action_pressed("split_down"):
			actor.split(Vector2(0, 1));
	
	#shift
	if next_state == null:
		if event.is_action_pressed("shift_left"):
			actor.shift(Vector2(-1, 0));
		elif event.is_action_pressed("shift_right"):
			actor.shift(Vector2(1, 0));
		elif event.is_action_pressed("shift_up"):
			actor.shift(Vector2(0, -1));
		elif event.is_action_pressed("shift_down"):
			actor.shift(Vector2(0, 1));
		
	#slide/merge
	if next_state == null and not event.is_action_pressed("cc") and not event.is_action_pressed("shift"):
		if event.is_action_pressed("ui_left"):
			actor.slide(Vector2(-1, 0));
		elif event.is_action_pressed("ui_right"):
			actor.slide(Vector2(1, 0));
		elif event.is_action_pressed("ui_up"):
			actor.slide(Vector2(0, -1));
		elif event.is_action_pressed("ui_down"):
			actor.slide(Vector2(0, 1));
'''

''' in snap.gd enter(), presnap logic
	#check presnap
	if actor.presnapped: #this implies snap was entered, collider offset is already fixed
		actor.slide(actor.next_dir);
		actor.presnapped = false;
'''

''' sliding.gd handleInput() code for presnapping
	if not actor.presnapped and not Input.is_action_pressed("cc") and not Input.is_action_pressed("shift"):
		if event.is_action_pressed("ui_left"):
			actor.next_dir = Vector2(-1, 0);
			actor.presnapped = true;
		elif event.is_action_pressed("ui_right"):
			actor.next_dir = Vector2(1, 0);
			actor.presnapped = true;
		elif event.is_action_pressed("ui_up"):
			actor.next_dir = Vector2(0, -1);
			actor.presnapped = true;
		elif event.is_action_pressed("ui_down"):
			actor.next_dir = Vector2(0, 1);
			actor.presnapped = true;
'''

'''
	if actor.next_move.is_null(): #check for premove
		actor.get_next_action();
		if actor.next_move.is_valid():
			duang_speed *= 6;
			fade_speed *= 6;
'''

''' old snap.gd code
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

''' slide with collider_receding
func slide(dir:Vector2) -> bool:
	if get_state() not in ["tile", "snap"]:
		return false;
	
	#determine whether to slide or merge or, if obstructed, idle
	var next_state:Node2D;
	var xaligned = is_xaligned();
	var yaligned = is_yaligned();
	if is_player: #ignore ray if not aligned with tile grid
		if (dir.x and not xaligned) or (dir.y and not yaligned):
			next_state = $FSM.states.sliding;
	
	if next_state == null:
		#find ray in slide direction
		var ray = get_ray(dir);
		if splitted or (pusher != null and pusher.splitted):
			ray.force_raycast_update();
		
		if ray.is_colliding():
			var collider := ray.get_collider();
			
			if collider.is_in_group("wall"): #obstructed
				return false;
				
			if collider is ScoreTile:
				if not xaligned or not yaligned: #in snap mode, must be aligned to do stuff
					return false;
				if collider.get_state() not in ["tile", "snap"]:
					return false;
				
				collider.pusher = self;
				var CFSM = collider.get_node("FSM");
				var collider_receding = CFSM.curState.next_state in [CFSM.states.sliding, CFSM.states.merging1];
				
				if power == 1 and not is_player:
					print(CFSM.curState.next_state);
					print("collider stable: ", not collider_receding);
				
				if power in [-1, collider.power] and not collider_receding: #merge as 0 or equal power
					partner = collider;
					collider.partner = self;
					next_state = $FSM.states.merging1;
				elif is_player and collider.slide(dir): #try to slide collider
					collider.snap_slid = true;
					next_state = $FSM.states.sliding;
				elif collider.is_player and collider_receding: #collider is making way
					next_state = $FSM.states.sliding;
				elif collider.power == -1 and not collider_receding: #merge with 0
					partner = collider;
					collider.partner = self;
					next_state = $FSM.states.merging1;
				else:
					collider.pusher = null;
					return false;
			else:
				next_state = $FSM.states.sliding;
		else:
			next_state = $FSM.states.sliding;
	
	slide_dir = dir;
	$FSM.curState.next_state = next_state;
	return true;
'''

''' using duplicate instead
#remember to update texture and settings too
func set_tile_params(tile, index):
	tile.is_player = tile_is_players[index];
	tile.position = tile_positions[index];
	tile.power = tile_powers[index];
	tile.ssign = tile_ssigns[index];
'''

'''
	#if a tile/baddie is null, instantiate a new one
	#otherwise it still exists, revert its parameters (NAH)
'''

''' in Level.gd
func _physics_process(_delta):
	#create and save snapshot
	if tiles_changed:
		if has_non_player(tiles_changed):
			print("NEW SNAPSHOT");
			var snapshot = PlayerSnapshot.new(self, tiles_changed, tiles_created);
			player_snapshots.push_back(snapshot);
			
		tiles_changed.clear();
'''

'''
func _init(level_, tiles_:Array[ScoreTile], new_tiles_:Array[ScoreTile]):
	level = level_;
	tiles = tiles_.duplicate();
	new_tiles = new_tiles_.duplicate();
	
	for tile_index in tiles.size():
		var tile = tiles[tile_index];
		
		#duplicate tile
		tile_duplicates.push_back(tile.duplicate_custom());
		
		#save snapshot location
		tile.snapshot_locations.push_back(Vector2i(level.player_snapshots.size(), tile_index));
	
		#save baddies
		if tile.is_player:
			save_nearby_baddies(tile.get_node("PhysicsEnabler2"), GV.PLAYER_SNAPSHOT_BADDIE_RANGE);

	#reset baddie flags
	for baddie in baddies:
		baddie.snapshotted = false;
'''

#var tile_is_players:Array[bool] = [];
#var tile_positions:Array[Vector2] = [];
#var tile_powers:Array[int] = [];
#var tile_ssigns:Array[int] = [];

'''
func has_non_player():
	for tile in tiles:
		if not tile.is_player:
			return true;
	return false;
'''

'''
		#update object reference in previous snapshot
		var dup = duplicates[object_index];
		var locations = dup.snapshot_locations;
		if locations:
			var location:Vector2i = locations[locations.size() - 1];
			if location.x == index - 1:
				var prev_snapshot = level.player_snapshots[location.x];
				prev_snapshot.get(objects_name)[location.y] = dup;
				print("UPDATED REF at ", location);
			elif location.x == index: #snapshot consumed, remove snapshot location
				locations.pop_back();
'''

'''
				#debug
				if player_snapshots:
					var s = player_snapshots[0];
					for t in s.tiles:
						print(t);
'''

'''
	var test = "save_%03d.tscn";
	print(test % 1);
'''

''' this overwrites test.tscn
	var test = PackedScene.new();
	test.pack(current_level);
	ResourceSaver.save(test, "res://test.tscn");
'''

''' previously at the end of add_level(n)
	#init player position
	if GV.spawn_point != Vector2.ZERO:
		level.get_node("Player").position = GV.spawn_point;
'''

''' from lv5.gd
func _ready():
	#init random score tiles
	for score_tile in scoretiles.get_children():
		score_tile.power = GV.rng.randi_range(1, 11);
		score_tile.update_texture(score_tile.img, score_tile.power, score_tile.ssign, false);

'''

'''
	#if lv change through goal, prepare for and do save
	if GV.through_goal:
		if is_instance_valid(current_level.player_saved): #wasn't freed by freedom
			#free player so it doesn't trigger lv change when lv loads
			current_level.player_saved.remove_from_players();
			current_level.player_saved.free();
		
		#convert other players to tiles
		for player in current_level.players:
			player.is_player = false;
		current_level.players.clear();
		
		#clear snapshots
		current_level.player_snapshots.clear();
		
		#save level
		save_level();
'''

'''
	if GV.through_goal:
		#convert other players to tiles to prepare for save
		for player in current_level.players:
			player.is_player = false;
		
	#free player so it doesn't trigger lv change when lv loads
	#also to respawn at spawn point, not wherever it got saved
	if is_instance_valid(current_level.player_saved): #player saved and not freed by freedom
		#current_level.player_saved.remove_from_players(); #player array not saved
		#current_level.player_saved.free();
		
		#save level
		save_level();
'''

'''
#isn't freed, isn't null, and has non-player tile
func is_snapshot_valid(snapshot):
	if is_instance_valid(snapshot) and snapshot.has_non_player():
		return true;
	return false;
'''

''' in level.gd, upon undo
				#reset savepoint.saved to false, but don't perform save if player is on savepoint
				#so that a revert after this goes to previous savepoint
'''

''' under change_level, if GV.reverting
		#update all snapshot_location refs
		for tile in current_level.scoretiles.get_children():
			for location in tile.snapshot_locations:
				GV.temp_player_snapshots[location.x].tiles[location.y] = tile;
			for location_new in tile.snapshot_locations_new:
				GV.temp_player_snapshots[location_new.x].new_tiles[location_new.y] = tile;
		for baddie in current_level.baddies.get_children():
			for location in baddie.snapshot_locations:
				GV.temp_player_snapshots[location.x].baddies[location.y] = baddie;
'''

''' previously in savepoint.spawn_player()
	#update ref in last snapshot location(s)
	if player.snapshot_locations:
		var location = player.snapshot_locations.back();
		game.current_level.player_snapshots[location.x].tiles[location.y] = player;
	if player.snapshot_locations_new:
		var location_new = player.snapshot_locations_new.back();
		game.current_level.player_snapshots[location_new.x].new_tiles[location_new.y] = player;
'''

''' pack does not duplicate member arrays
	var packed_tile = load("res://Objects/ScoreTile.tscn");
	var test = packed_tile.instantiate();
	test.snapshot_locations.push_back(Vector2i(1,1));
	print(test.snapshot_locations);
	packed_tile.pack(test);
	test = packed_tile.instantiate();
	test.snapshot_locations.push_back(Vector2i(2,2));
	print(test.snapshot_locations);
	test.free();
	test = packed_tile.instantiate();
	print(test.snapshot_locations);
'''

'''
#if input, pushes to next_moves and next_dirs
func get_next_action():
	var event_name:String = "";
	var action:Callable;
	var s_dir:String;
	
	#find movement type
	if Input.is_action_pressed("cc"):
		action = func_split;
		event_name += "split_";
	elif Input.is_action_pressed("shift"):
		action = func_shift;
		event_name += "shift_";
	else:
		action = func_slide;
		event_name += "move_";
	
	#find direction
	if Input.is_action_pressed("move_left"):
		s_dir = "left";
	elif Input.is_action_pressed("move_right"):
		s_dir = "right";
	elif Input.is_action_pressed("move_up"):
		s_dir = "up";
	elif Input.is_action_pressed("move_down"):
		s_dir = "down";
	
	#check if movement pressed
	if s_dir:
		#check if movement just pressed
		event_name += s_dir;
		if Input.is_action_just_pressed(event_name):
			next_dirs.push_back(GV.directions[s_dir]);
			next_moves.push_back(action);
'''

''' wall grains
	if n_wall < -0.98 or (n_wall > 0.2 and n_wall < 0.22):
		$Walls.set_cell(0, Vector2i(tx, ty), 0, Vector2i.ZERO);
	elif n_wall < -0.955 or (n_wall > 0 and n_wall < 0.025):
		$Walls.set_cell(0, Vector2i(tx, ty), 1, Vector2i.ZERO);
'''

''' trick for pusher updating
	#create and slide/merge player in slide_dir
	player = actor.score_tile.instantiate();
	if actor.partner != null:
		actor.partner.pusher = player;
		actor.partner = null;
'''

'''
		var track_dir:Vector2i = ($TrackingCam.position - last_cam_pos).sign();
		var track_corner_dpos:Vector2 = Vector2(half_resolution.x * track_dir.x, half_resolution.y * track_dir.y);
		var load_dpos:Vector2 = track_corner_dpos + GV.CHUNK_LOAD_BUFFER * track_dir;
		var unload_dpos:Vector2 = -track_corner_dpos - GV.CHUNK_UNLOAD_BUFFER * track_dir;
		var load_pos_c:Vector2i = GV.world_to_pos_c($TrackingCam.position + load_dpos);
		var unload_pos_c:Vector2i = GV.world_to_pos_c($TrackingCam.position + unload_dpos);
		
		if track_dir.x > 0:
			loaded_pos_c_max.x = min(loaded_pos_c_max.x, load_pos_c.x);
'''

'''
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
'''

#const CM_TILE_GEN_POW_MAX:int = GV.TILE_GEN_POW_MAX; #for thread safety?

'''
		#unload chunks
		unload_mutex.lock();
		if not unload_queue.is_empty():
			var unload_pos:Vector2i = unload_queue.keys().front();
			unload_queue.erase(unload_pos);
			unload_mutex.unlock();
			#print("unload_positions: ", unload_positions);
			loaded_mutex.lock();
			loaded_chunks[unload_pos].queue_free();
			loaded_chunks.erase(unload_pos);
			loaded_mutex.unlock();
		else:
			unload_mutex.unlock();
'''

'''
	#queue_free an unloaded chunk from active tree
	elif not unloaded_chunks.is_empty():
		var unload_pos:Vector2i = unloaded_chunks.keys().back();
		unloaded_chunks.erase(unload_pos);
		loaded_mutex.lock();
		loaded_chunks[unload_pos].queue_free();
		loaded_chunks.erase(unload_pos);
		loaded_mutex.unlock();
'''

#mutex.lock(); exit_thread = true; mutex.unlock(); return; #debug

''' in slide(), after get_shape()
		#if splitted, tile was newly added, shapecast hasn't updated
		#if pusher splitted, physics was just toggled off then on, shapecast hasn't updated
		#if next_moves nonempty, premoved, last shapecast update may have caught a tile corner
		if splitted or (pusher != null and pusher.splitted) or next_moves:
			shape.force_shapecast_update();
'''

'''
	#scale physicsEnablers
	$PhysicsEnabler/CollisionShape2D.shape.set_size($PhysicsEnabler/CollisionShape2D.shape.get_size() + GV.PHYSICS_ENABLER_DSIZE);
	$PhysicsEnabler2.shape.set_size($PhysicsEnabler2.shape.get_size() + GV.PHYSICS_ENABLER_DSIZE);
'''
