#tilemap-based for better performance
#-1 indicates cell hasn't been generated yet
#empty atlas coordinate indicates cell is empty
#val represents Vector2i(pow, sign)
#coord represents atlas coord in tileset
class_name World
extends Node2D

signal premove_added;
signal action_finished;

@export var resolution_t:Vector2i = GV.RESOLUTION_T;
@export var min_pos:Vector2 = Vector2.ZERO;
@export var max_pos:Vector2 = GV.RESOLUTION;
@export var player_pos_t:Vector2i = Vector2i.ZERO;
@onready var game:Node2D = $"/root/Game";
var is_player_alive:bool = true;

var tile_noise = FastNoiseLite.new();
var wall_noise = FastNoiseLite.new();

var loaded_pos_t_min:Vector2i;
var loaded_pos_t_max:Vector2i; #inclusive

var resolution:Vector2;
var half_resolution:Vector2;

var premove_dirs:Array[Vector2i] = [];
var premoves:Array[String] = []; #slide, split, shift

#for input repeat delay
var atimer:AccelTimer = AccelTimer.new();
var last_input_type:int; #see GV.InputType
var last_input_modifier:String = "slide";
var last_input_move:String = "left";
var last_action_finished:bool = true;


func _enter_tree():
	#set resolution (before tracking cam _ready())
	resolution = Vector2(resolution_t * GV.TILE_WIDTH);
	half_resolution = resolution / 2;

	#set position bounds (before tracking cam _ready())
	min_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MIN, GV.INT64_MIN);
	max_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MAX, GV.INT64_MAX);
	
func _ready():
	#init pathfinder
	$Pathfinder.set_tilemap($Cells);
	
	#signals
	premove_added.connect(_on_premove_added);
	action_finished.connect(_on_action_finished);
	
	set_level_name();
	
	if not GV.current_level_from_save: #first time entering lv
		#print("set initial SVID to ", GV.savepoint_id);
		GV.level_initial_savepoint_ids[GV.current_level_index] = GV.savepoint_id;
	

func set_level_name():
	if has_node("LevelName"):
		game.current_level_name = $LevelName;
		game.current_level_name.modulate.a = 0;
	else:
		game.current_level_name = null;

func save():
	var save_dict = {
		
	};

func _exit_tree():
	#print_orphan_nodes();
	pass;

func is_world_border(pos_t:Vector2i) -> bool:
	if pos_t.x == GV.BORDER_MIN_POS_T.x or pos_t.x == GV.BORDER_MAX_POS_T.x:
		if pos_t.y >= GV.BORDER_MIN_POS_T.y and pos_t.y <= GV.BORDER_MAX_POS_T.y:
			return true;
	if pos_t.y == GV.BORDER_MIN_POS_T.y or pos_t.y == GV.BORDER_MAX_POS_T.y:
		if pos_t.x >= GV.BORDER_MIN_POS_T.x and pos_t.x <= GV.BORDER_MAX_POS_T.x:
			return true;
	return false;

func on_copy():
	if not GV.abilities["copy"]:
		return;
	
	#declare and init level array
	var level_array = [];
#	for row_itr in resolution_t.y:
#		var row = [];
#		row.resize(resolution_t.x);
#		row.fill(GV.TileId.EMPTY);
#		level_array.push_back(row);
	
	#add to clipboard
	DisplayServer.clipboard_set(str(level_array));
	
	return level_array;

#use tilemap, don't unload manually
func _on_camera_transition_started(target:Vector2, track_dir:Vector2i):
	var temp_pos_t_min:Vector2i = loaded_pos_t_min;
	var temp_pos_t_max:Vector2i = loaded_pos_t_max;
	if track_dir.x:
		var load_min_x:float = target.x - half_resolution.x - (GV.TILE_LOAD_BUFFER if track_dir.x < 0 else GV.TILE_UNLOAD_BUFFER);
		var load_max_x:float = target.x + half_resolution.x + (GV.TILE_LOAD_BUFFER if track_dir.x > 0 else GV.TILE_UNLOAD_BUFFER);
		temp_pos_t_min.x = GV.world_to_xt(load_min_x);
		temp_pos_t_max.x = GV.world_to_xt(load_max_x);
	if track_dir.y:
		var load_min_y:float = target.y - half_resolution.y - (GV.TILE_LOAD_BUFFER if track_dir.y < 0 else GV.TILE_UNLOAD_BUFFER);
		var load_max_y:float = target.y + half_resolution.y + (GV.TILE_LOAD_BUFFER if track_dir.y > 0 else GV.TILE_UNLOAD_BUFFER);
		temp_pos_t_min.y = GV.world_to_xt(load_min_y);
		temp_pos_t_max.y = GV.world_to_xt(load_max_y);
	update_map(loaded_pos_t_min, loaded_pos_t_max, temp_pos_t_min, temp_pos_t_max);
	loaded_pos_t_min = temp_pos_t_min;
	loaded_pos_t_max = temp_pos_t_max;
	
func update_map(old_pos_t_min:Vector2i, old_pos_t_max:Vector2i, new_pos_t_min:Vector2i, new_pos_t_max:Vector2i):
	var overlap_min:Vector2i = Vector2i(maxi(old_pos_t_min.x, new_pos_t_min.x), maxi(old_pos_t_min.y, new_pos_t_min.y));
	var overlap_max:Vector2i = Vector2i(mini(old_pos_t_max.x, new_pos_t_max.x), mini(old_pos_t_max.y, new_pos_t_max.y));
	if overlap_min.x > overlap_max.x or overlap_min.y > overlap_max.y: #no overlap
		load_rect(new_pos_t_min, new_pos_t_max);
	else:
		#new rect
		load_rect(new_pos_t_min, Vector2i(new_pos_t_max.x, overlap_min.y - 1));
		load_rect(Vector2i(new_pos_t_min.x, overlap_min.y), Vector2i(overlap_min.x - 1, overlap_max.y));
		load_rect(Vector2i(overlap_max.x + 1, overlap_min.y), Vector2i(new_pos_t_max.x, overlap_max.y));
		load_rect(Vector2i(new_pos_t_min.x, overlap_max.y + 1), new_pos_t_max);

func load_rect(pos_t_min:Vector2i, pos_t_max:Vector2i):
	for ty in range(pos_t_min.y, pos_t_max.y+1):
		for tx in range(pos_t_min.x, pos_t_max.x+1):
			var pos_t:Vector2i = Vector2i(tx, ty);
			generate_cell(pos_t);

func generate_cell(pos_t:Vector2i):
	if $Cells.get_cell_atlas_coords(GV.LayerId.BACK, pos_t) != -Vector2i.ONE or $Cells.get_cell_atlas_coords(GV.LayerId.TILE, pos_t) != -Vector2i.ONE:
		return; #cell was generated already
	if pos_t == player_pos_t:
		$Cells.set_cell(GV.LayerId.TILE, player_pos_t, GV.LayerId.TILE, Vector2i(GV.TileId.ZERO, GV.TypeId.PLAYER)); #player
		return;
	if is_world_border(pos_t):
		$Cells.set_cell(GV.LayerId.BACK, pos_t, GV.LayerId.BACK, Vector2i(GV.BackId.BORDER_SQUARE, 0));
		return;
	
	#back
	var n_wall:float = clamp(wall_noise.get_noise_2d(pos_t.x, pos_t.y), -1, 1); #[-1, 1]
	if absf(n_wall) < 0.009:
		$Cells.set_cell(GV.LayerId.BACK, pos_t, GV.LayerId.BACK, Vector2i(GV.BackId.BLACK_WALL, 0));
		return;
	if absf(n_wall) < 0.02:
		$Cells.set_cell(GV.LayerId.BACK, pos_t, GV.LayerId.BACK, Vector2i(GV.BackId.MEMBRANE, 0));
		return;
	$Cells.set_cell(GV.LayerId.BACK, pos_t, GV.LayerId.BACK, Vector2i(GV.BackId.EMPTY, 0)); #to mark cell as generated

	#tile
	var n_tile:float = clamp(tile_noise.get_noise_2d(pos_t.x, pos_t.y), -1, 1); #[-1, 1]
	var ssign:int = int(signf(n_tile));
	n_tile = pow(absf(n_tile), 1); #[0, 1]; use power > 1 to bias towards 0
	var power:int = GV.TILE_GEN_POW_MAX if (n_tile == 1.0) else int((GV.TILE_GEN_POW_MAX + 2) * n_tile) - 1;
	var tile_id:int = GV.tile_val_to_id(power, ssign);
	
	#type
	var type:int = GV.TypeId.REGULAR;
	var n_type:float = randf();
	if n_type < GV.P_GEN_INVINCIBLE:
		type = GV.TypeId.INVINCIBLE;
	elif n_type < GV.P_GEN_HOSTILE:
		type = GV.TypeId.HOSTILE;
	
	$Cells.set_cell(GV.LayerId.TILE, pos_t, GV.LayerId.TILE, Vector2i(tile_id-1, type));

func get_event_modifier(event) -> String:
	for modifier in ["split", "shift"]:
		if event.is_action_pressed(modifier):
			return modifier;
	for modifier in ["split", "shift"]:
		if event.is_action_released(modifier):
			return "slide";
	return "";

func get_event_move(event) -> String:
	for move in ["left", "right", "up", "down"]:
		if event.is_action_pressed(move):
			return move;
	return "";

func is_last_move_held() -> bool:
	return Input.is_action_pressed(last_input_move);

func _input(event):
	var modifier:String = get_event_modifier(event);
	if modifier:
		last_input_modifier = modifier;
		if modifier != "slide" and is_last_move_held():
			add_premove();
		return;
	
	var move:String = get_event_move(event);
	if move:
		last_input_move = move;
		last_input_type = GV.InputType.MOVE;
		add_premove();
		
func add_premove():
	premove_dirs.push_back(GV.directions[last_input_move]);
	premoves.push_back(last_input_modifier);
	premove_added.emit();

func _on_premove_added():
	if last_action_finished:
		consume_premove();

func _on_action_finished():
	last_action_finished = true;
	if premoves:
		consume_premove();

func get_tile_id(pos_t:Vector2i):
	return $Cells.get_cell_atlas_coords(GV.LayerId.TILE, pos_t).x + 1;

func get_type_id(pos_t:Vector2i):
	return $Cells.get_cell_atlas_coords(GV.LayerId.TILE, pos_t).y;

func get_back_id(pos_t:Vector2i):
	return $Cells.get_cell_atlas_coords(GV.LayerId.BACK, pos_t).x;

func is_tile(pos_t:Vector2i):
	return get_tile_id(pos_t) != 0;

func is_vals_mergeable(pow1:int, sign1:int, pow2:int, sign2:int):
	if pow1 == -1 or pow2 == -1:
		return true;
	if pow1 == pow2 and (pow1 < GV.TILE_POW_MAX or sign1 != sign2):
		return true;
	return false;

func is_ids_mergeable(tile_id1:int, tile_id2:int):
	if tile_id1 == 0 or tile_id2 == 0: #either cell empty
		return true;
	var val1:Vector2i = GV.id_to_tile_val(tile_id1);
	var val2:Vector2i = GV.id_to_tile_val(tile_id2);
	return is_vals_mergeable(val1.x, val1.y, val2.x, val2.y);

func is_id_splittable(tile_id:int):
	var val:Vector2i = GV.id_to_tile_val(tile_id);
	return not tile_id == GV.TileId.EMPTY and val.x > 0;

func is_pow_splittable(pow:int):
	return pow > 0;

func is_compatible(type_id:int, back_id:int):
	if back_id == GV.BackId.EMPTY:
		return true;
	if back_id in GV.B_WALL_OR_BORDER:
		return false;
	if back_id == GV.BackId.MEMBRANE:
		return type_id == GV.TypeId.PLAYER;
	#back_id in GV.B_SAVE_OR_GOAL
	return type_id == GV.TypeId.PLAYER or type_id == GV.TypeId.REGULAR;

#-1 if slide not possible
func get_slide_push_count(src_pos_t:Vector2i, dir:Vector2i):
	var curr_pos_t:Vector2i = src_pos_t;
	var curr_tile_id:int = get_tile_id(src_pos_t);
	var src_type_id:int = get_type_id(src_pos_t);
	var curr_type_id:int = src_type_id;
	var push_count:int = 0;
	var nearest_merge_push_count:int = -1;
	
	while push_count <= GV.abilities["tile_push_limit"]:
		#check for obstruction
		var temp_type_id:int = curr_type_id;
		curr_pos_t += dir;
		curr_type_id = get_type_id(curr_pos_t);
		var curr_back_id:int = get_back_id(curr_pos_t);
		if not is_compatible(temp_type_id, curr_back_id) or \
			(push_count > 0 and src_type_id in GV.T_ENEMY and curr_type_id == GV.TypeId.PLAYER):
			if nearest_merge_push_count != -1:
				return nearest_merge_push_count;
			return -1;
		
		#push/merge logic
		var temp_tile_id:int = curr_tile_id;
		curr_tile_id = get_tile_id(curr_pos_t);
		if temp_tile_id == GV.TileId.ZERO:
			if curr_tile_id == GV.TileId.EMPTY:
				return push_count; #bubble
			if curr_tile_id != GV.TileId.ZERO and nearest_merge_push_count != -1:
				return nearest_merge_push_count; #bubble fail
		
		if is_ids_mergeable(temp_tile_id, curr_tile_id):
			if curr_tile_id != GV.TileId.ZERO:
				return push_count;
			if nearest_merge_push_count == -1:
				nearest_merge_push_count = push_count;
		
		if push_count == GV.abilities["tile_push_limit"] and nearest_merge_push_count != -1:
			return nearest_merge_push_count;
		push_count += 1;
	return -1;

func get_tile_type_merge_priority(type_id:int):
	match type_id:
		-1:
			return -1;
		GV.TypeId.PLAYER:
			return 1;
		GV.TypeId.INVINCIBLE:
			return 3;
		GV.TypeId.HOSTILE:
			return 2;
		GV.TypeId.REGULAR:
			return 0;
		GV.TypeId.VOID:
			return 4;

#assumes tile ids are mergeable
func get_merged_tile_id(tile_id1:int, tile_id2:int):
	if tile_id1 == GV.TileId.EMPTY:
		return tile_id2;
	if tile_id2 == GV.TileId.EMPTY:
		return tile_id1;
	if tile_id1 == GV.TileId.ZERO:
		return tile_id2;
	if tile_id2 == GV.TileId.ZERO:
		return tile_id1;
	if sign(tile_id1 - GV.TileId.ZERO) != sign(tile_id2 - GV.TileId.ZERO):
		return GV.TileId.ZERO;
	return tile_id1 + sign(tile_id1 - GV.TileId.ZERO);

func get_merged_atlas_coords(coord1:Vector2i, coord2:Vector2i):
	var atlas_y:int = coord1.y if get_tile_type_merge_priority(coord1.y) > get_tile_type_merge_priority(coord2.y) else coord2.y;
	var atlas_x:int = get_merged_tile_id(coord1.x + 1, coord2.x + 1) - 1;
	return Vector2i(atlas_x, atlas_y);

#propagate tile type
func perform_slide(pos_t:Vector2i, dir:Vector2i, push_count:int):
	var merge_pos_t:Vector2i = pos_t + (push_count + 1) * dir;
	for dist_to_merge_pos_t in range(0, push_count + 1):
		var curr_pos_t:Vector2i = merge_pos_t - dist_to_merge_pos_t * dir;
		var prev_coord:Vector2i = $Cells.get_cell_atlas_coords(GV.LayerId.TILE, curr_pos_t - dir);
		var result_coord = prev_coord;
		if dist_to_merge_pos_t == 0: #merge at curr_pos_t
			var curr_coord:Vector2i = $Cells.get_cell_atlas_coords(GV.LayerId.TILE, curr_pos_t);
			result_coord = get_merged_atlas_coords(prev_coord, curr_coord);
		$Cells.set_cell(GV.LayerId.TILE, curr_pos_t, GV.LayerId.TILE, result_coord);
	
	#remove source tile
	$Cells.set_cell(GV.LayerId.TILE, pos_t, GV.LayerId.TILE, -Vector2i.ONE);

func get_shift_distance(src_pos_t:Vector2i, dir:Vector2i) -> int:
	var next_pos_t:Vector2i = src_pos_t + dir;
	var distance:int = 0;
	var src_type_id:int = get_type_id(src_pos_t);

	while is_compatible(src_type_id, get_back_id(next_pos_t)) and not is_tile(next_pos_t):
		distance += 1;
		next_pos_t += dir;
	return distance;

func perform_shift(pos_t:Vector2i, dir:Vector2i, distance:int):
	var dest_pos_t:Vector2i = pos_t + distance * dir;
	var src_coord:Vector2i = $Cells.get_cell_atlas_coords(GV.LayerId.TILE, pos_t);
	$Cells.set_cell(GV.LayerId.TILE, dest_pos_t, GV.LayerId.TILE, src_coord);
	$Cells.set_cell(GV.LayerId.TILE, pos_t, GV.LayerId.TILE, -Vector2i.ONE);

func set_player_pos_t(pos_t:Vector2i):
	player_pos_t = pos_t;
	$Pathfinder.set_player_pos(pos_t);

#update player_pos_t
func try_slide(pos_t:Vector2i, dir:Vector2i) -> bool:
	var push_count:int = get_slide_push_count(pos_t, dir);
	if push_count != -1:
		perform_slide(pos_t, dir, push_count);
		set_player_pos_t(player_pos_t + dir);
		if get_type_id(player_pos_t) != GV.TypeId.PLAYER:
			is_player_alive = false;
		return true;
	return false;

#update player_pos_t
func try_split(pos_t:Vector2i, dir:Vector2i) -> bool:
	var coord:Vector2i = $Cells.get_cell_atlas_coords(GV.LayerId.TILE, pos_t);
	var val:Vector2i = GV.id_to_tile_val(coord.x + 1);
	if not is_pow_splittable(val.x):
		return false;
	
	#halve tile, try_slide, then (re)set tile at pos_t
	var splitted_coord:Vector2i = Vector2i(coord.x - val.y, coord.y);
	$Cells.set_cell(GV.LayerId.TILE, pos_t, GV.LayerId.TILE, splitted_coord);
	if try_slide(pos_t, dir):
		var parent_coord:Vector2i = Vector2i(splitted_coord.x, GV.TypeId.REGULAR);
		$Cells.set_cell(GV.LayerId.TILE, pos_t, GV.LayerId.TILE, parent_coord);
		#don't update player_pos_t since try_slide() already did it
		return true;
	else:
		$Cells.set_cell(GV.LayerId.TILE, pos_t, GV.LayerId.TILE, coord);
		return false;

#update player_pos_t
func try_shift(pos_t:Vector2i, dir:Vector2i) -> bool:
	var distance:int = get_shift_distance(pos_t, dir);
	if distance:
		perform_shift(pos_t, dir, distance);
		set_player_pos_t(player_pos_t + distance * dir);
		return true;
	return false;

func consume_premove():
	#check that player is alive
	if not is_player_alive:
		premoves.clear();
		premove_dirs.clear();
		return;
	
	#get first premove
	var action:String = premoves.pop_front();
	var dir:Vector2i = premove_dirs.pop_front();
	
	#determine if premove is possible, clear premoves if not
	var action_func:Callable = Callable(self, "try_" + action);
	if action_func.call(player_pos_t, dir):
		#start animation
		#play sound effect
		#update last_action_finished, emit signal
		#update player_pos_t?
		#update player_last_dir?
		#update $Cells?
		$Pathfinder.set_player_last_dir(dir);
		action_finished.emit();
		pass;
	else:
		premoves.clear();
		premove_dirs.clear();
	
