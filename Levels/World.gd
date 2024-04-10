#tilemap-based for better performance
#-1 indicates cell hasn't been generated yet
#empty atlas coordinate indicates cell is empty
class_name World
extends Node2D

@export var resolution_t:Vector2i = GV.RESOLUTION_T;
@export var min_pos:Vector2 = Vector2.ZERO;
@export var max_pos:Vector2 = GV.RESOLUTION;
@export var player_pos_t:Vector2i = Vector2i.ZERO;
@onready var game:Node2D = $"/root/Game";

var tile_noise = FastNoiseLite.new();
var wall_noise = FastNoiseLite.new();

#bounding rect
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
var last_input_move:String;
var last_action_finished:bool = false;


func _enter_tree():
	#set resolution (before tracking cam _ready())
	resolution = Vector2(resolution_t * GV.TILE_WIDTH);
	half_resolution = resolution / 2;

	#set position bounds (before tracking cam _ready())
	min_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MIN, GV.INT64_MIN);
	max_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MAX, GV.INT64_MAX);
	
func _ready():
	set_level_name();
	
	if not GV.current_level_from_save: #first time entering lv
		#print("set initial SVID to ", GV.savepoint_id);
		GV.level_initial_savepoint_ids[GV.current_level_index] = GV.savepoint_id;

func _input(event):
	var nothing_changed:bool = false;
	var modifier_changed:bool = false;
	
	#last input modifier
	if event.is_action_pressed("cc"): #Cmd/Ctrl
		last_input_modifier = "split";
		modifier_changed = true;
	elif event.is_action_pressed("shift"):
		last_input_modifier = "shift";
		modifier_changed = true;
	elif event.is_action_released("cc") or event.is_action_released("shift"):
		last_input_modifier = "slide";
		modifier_changed = true;
	
	#last input move
	elif event.is_action_pressed("move_left"):
		last_input_move = "left";
	elif event.is_action_pressed("move_right"):
		last_input_move = "right";
	elif event.is_action_pressed("move_up"):
		last_input_move = "up";
	elif event.is_action_pressed("move_down"):
		last_input_move = "down";
	elif	(event.is_action_released("move_left") and last_input_move == "left") or \
			(event.is_action_released("move_right") and last_input_move == "right") or \
			(event.is_action_released("move_up") and last_input_move == "up") or \
			(event.is_action_released("move_down") and last_input_move == "down"):
		last_input_move = "";
	else:
		nothing_changed = true;
	
	var move_changed:bool = not modifier_changed and not nothing_changed;
	var meaningful:bool = (modifier_changed and last_input_move) or move_changed;
	
	if meaningful:
		atimer.stop();
		
	

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
	if GV.abilities["copy"]:
		#declare and init level array
		var level_array = [];
		for row_itr in resolution_t.y:
			var row = [];
			row.resize(resolution_t.x);
			row.fill(GV.TileId.EMPTY);
			level_array.push_back(row);
		
		#store tilemap stuff ids
		for row_itr in resolution_t.y:
			for col_itr in resolution_t.x:
				var id = $Walls.get_cell_source_id(0, Vector2i(col_itr, row_itr));
				if id == 0:
					level_array[row_itr][col_itr] = GV.BackId.BORDER_SQUARE;
				else:
					level_array[row_itr][col_itr] = id * GV.StuffId.MEMBRANE;
		
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
	if $Cells.get_cell_atlas_coords(GV.LayerId.BACK, pos_t) != Vector2i(-1, -1) or $Cells.get_cell_atlas_coords(GV.LayerId.TILE, pos_t) != Vector2i(-1, -1):
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

	#tile
	var n_tile:float = clamp(tile_noise.get_noise_2d(pos_t.x, pos_t.y), -1, 1); #[-1, 1]
	var ssign:int = int(signf(n_tile));
	n_tile = pow(absf(n_tile), 1); #[0, 1]; use power > 1 to bias towards 0
	var power:int = GV.TILE_GEN_POW_MAX if (n_tile == 1.0) else int((GV.TILE_GEN_POW_MAX + 2) * n_tile) - 1;
	var tile_id:int = GV.tile_val_to_id(power, ssign);
	$Cells.set_cell(GV.LayerId.TILE, pos_t, GV.LayerId.TILE, Vector2i(tile_id-1, GV.TypeId.REGULAR));
