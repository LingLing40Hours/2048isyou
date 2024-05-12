#unlocker areas must not be collision layer1, else they interfere with tile movement
class_name Level
extends Node2D

#the first player to enter any savepoint, whose value will be respawned
#on save, other players will become regular tiles
@export var player_saved:ScoreTile;
@export var resolution_t:Vector2i = GV.RESOLUTION_T;
@export var min_pos:Vector2 = Vector2.ZERO;
@export var max_pos:Vector2 = GV.RESOLUTION;

@onready var game:Node2D = $"/root/Game";
var scoretiles:Node2D;
var savepoints:Node2D;
var baddies:Node2D;

var resolution:Vector2;
var half_resolution:Vector2;
var chunked:bool = false;
var pooled:bool = false;

var players = []; #if player, add here in _ready()
var player_snapshots:Array[PlayerSnapshot] = [];
var current_snapshot:PlayerSnapshot; #last in array, might not be meaningful, baddie flags not reset

#for input repeat delay
var atimer:AccelTimer = AccelTimer.new();
var premove_streak_end_timer:AccelTimer = AccelTimer.new();
var last_input_type:int;
var last_input_modifier:String = "slide"; #one of ["split", "shift", "slide"], always non-empty
var last_input_move:String = "left"; #one of ["left", "right", "up", "down"]; always non-empty
var last_action_finished:bool = true;


func _enter_tree():
	#set resolution (before tracking cam _ready())
	resolution = Vector2(resolution_t * GV.TILE_WIDTH);
	half_resolution = resolution / 2;

	#set position bounds (before tracking cam _ready())
	min_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MIN, GV.INT64_MIN);
	max_pos = GV.TILE_WIDTH * Vector2(GV.INT64_MAX, GV.INT64_MAX);

func set_level_name():
	if has_node("LevelName"):
		game.current_level_name = $LevelName;
		game.current_level_name.modulate.a = 0;
	else:
		game.current_level_name = null;

#func _physics_process(delta):
#	print("frame");

func _ready():
	print("level player saved: ", player_saved);
	scoretiles = $ScoreTiles;
	savepoints = $SavePoints;
	baddies = $Baddies;
	
	set_level_name();
	
	if not GV.current_level_from_save: #first time entering lv
		#print("set initial SVID to ", GV.savepoint_id);
		GV.level_initial_savepoint_ids[GV.current_level_index] = GV.savepoint_id;

	#init input repeat delay stuff
	atimer.timeout.connect(_on_atimer_timeout);
	add_child(atimer);
	add_child(premove_streak_end_timer);

func on_undo():
	if not GV.abilities["undo"]:
		return;
	
	var cleared_premoves:bool = false;
	for player in players:
		if player.premoves:
			player.premoves.clear();
			player.premove_dirs.clear();
			cleared_premoves = true;
	if cleared_premoves:
		return;
	
	if player_snapshots:
		var snapshot = player_snapshots.pop_back();
		if snapshot.meaningful():
			#print("USING CURR SNAPSHOT");
			snapshot.reset_baddie_flags();
			snapshot.checkout();
		elif player_snapshots:
			#print("USING PREV SNAPSHOT");
			snapshot.remove();
			snapshot = player_snapshots.pop_back();
			snapshot.checkout();

		#if undid past savepoint, remove the savepoint save, reset savepoint status
		if GV.current_savepoint_ids and player_snapshots.size() < GV.current_snapshot_sizes.back():
			var id = GV.current_savepoint_ids.pop_back();
			for savepoint in savepoints.get_children():
				if savepoint.id == id:
					savepoint.saved = false;
			GV.current_savepoint_saves.pop_back();
			GV.current_snapshot_sizes.pop_back();
			GV.current_savepoint_powers.pop_back();
			GV.current_savepoint_ssigns.pop_back();
			
			#update last savepoint id
			if GV.current_savepoint_ids:
				GV.level_last_savepoint_ids[GV.current_level_index] = GV.current_savepoint_ids.back();
			else:
				GV.level_last_savepoint_ids[GV.current_level_index] = GV.level_initial_savepoint_ids[GV.current_level_index];

func on_copy():
	if GV.abilities["copy"]:
		#declare and init level array
		var level_array = [];
		for row_itr in resolution_t.y:
			var row = [];
			row.resize(resolution_t.x);
			row.fill(GV.StuffId.EMPTY);
			level_array.push_back(row);
		
		#store tilemap stuff ids
		for row_itr in resolution_t.y:
			for col_itr in resolution_t.x:
				var id = $Walls.get_cell_source_id(0, Vector2i(col_itr, row_itr));
				if id == 0:
					level_array[row_itr][col_itr] = GV.StuffId.BORDER;
				else:
					level_array[row_itr][col_itr] = id * GV.StuffId.MEMBRANE;
		
		#store savepoint stuff ids (there's no overlap with tilemap)
		for savepoint in savepoints.get_children():
			if savepoint is Goal:
				for node in savepoint.tile_centers.get_children():
					var pos_t = GV.world_to_pos_t(node.global_position);
					#bound check
					if pos_t.x >= 0 and pos_t.x < resolution_t.x and pos_t.y >= 0 and pos_t.y < resolution_t.y:
						level_array[pos_t.y][pos_t.x] = GV.StuffId.GOAL;
			else:
				var pos_t = GV.world_to_pos_t(savepoint.position);
				level_array[pos_t.y][pos_t.x] = GV.StuffId.SAVEPOINT;
		
		#store tile stuff ids (add value id as offset)
		for tile in scoretiles.get_children():
			var pos_t = GV.world_to_pos_t(tile.position);
			var id = GV.tile_val_to_id(tile.power, tile.ssign);
			if id == GV.StuffId.ZERO:
				id = GV.StuffId.EMPTY; #reduces astar branching
			level_array[pos_t.y][pos_t.x] += id;
		
		#add to clipboard
		DisplayServer.clipboard_set(str(level_array));
		
		return level_array;

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

func is_move_released(event) -> bool:
	for move in ["left", "right", "up", "down"]:
		if event.is_action_released(move):
			return true;
	return false;

func is_move_held() -> bool:
	for move in ["left", "right", "up", "down"]:
		if Input.is_action_pressed(move):
			return true;
	return false;

func is_last_move_held() -> bool:
	return Input.is_action_pressed(last_input_move);

func is_last_move_released(event) -> bool:
	return event.is_action_released(last_input_move);

func is_last_modifier_held() -> bool:
	return Input.is_action_pressed(last_input_modifier);

func is_last_action_held() -> bool:
	if last_input_modifier == "slide":
		return is_last_move_held();
	#return Input.is_action_pressed(last_input_modifier + "_" + last_input_move); #doesn't work
	return is_last_modifier_held() and is_last_move_held();

func is_last_modifier_or_move_held() -> bool:
	return is_last_modifier_held() or is_last_move_held();

#update last_input_modifier/move/type
#stop atimer if last_input_modifier/move changed/released
#return true to add premove
func update_last_input(event) -> bool:
	var m:String = get_event_modifier(event);
	if m: #shift/split pressed/released
		atimer.stop();
		var temp_last_input_modifier:String = last_input_modifier;
		last_input_modifier = m;
		
		if m != "slide":
			#shift/split pressed, add premove
			last_input_type = GV.InputType.MOVE;
			return is_last_move_held();
		if temp_last_input_modifier != "slide" and m == "slide" and is_last_move_held():
			#shift/split released but slide held, wait for timeout before starting move
			last_input_type = GV.InputType.MOVE;
			atimer.start(GV.MOVE_REPEAT_DELAY_F0, GV.MOVE_REPEAT_DELAY_DF, GV.MOVE_REPEAT_DELAY_DDF, GV.MOVE_REPEAT_DELAY_FMIN);
			return false;
		
	m = get_event_move(event);
	if m:
		atimer.stop();
		last_input_move = m;
		last_input_type = GV.InputType.MOVE;
		return true;
	if is_last_move_released(event):
		atimer.stop();
	
	return false; #event is unrelated to modifier/move, don't add premove

func _on_atimer_timeout():
	if not last_action_finished:
		return;
	if last_input_type == GV.InputType.UNDO and Input.is_action_pressed("undo"):
		on_undo();
		atimer.repeat();
		
func _input(event):
	if event.is_action_pressed("copy"):
		on_copy();
	elif not GV.changing_level:
		if event.is_action_pressed("home"):
			on_home();
		elif event.is_action_pressed("restart"):
			on_restart();
		elif event.is_action_pressed("slide"):
			pass;
		elif event.is_action_pressed("undo"):
			last_input_type = GV.InputType.UNDO;
			on_undo();
			atimer.start(GV.UNDO_REPEAT_DELAY_F0, GV.UNDO_REPEAT_DELAY_DF, GV.UNDO_REPEAT_DELAY_DDF, GV.UNDO_REPEAT_DELAY_FMIN);
		elif event.is_action_released("undo"):
			atimer.stop();
		elif event.is_action_pressed("revert"):
			on_revert();

func on_home():
	if GV.abilities["home"]:
		GV.changing_level = true;
		GV.reverting = false;
		GV.savepoint_id = -1;
		game.change_level_faded(0);

func on_restart():
	if GV.abilities["restart"]:
		#remove save
		game.level_saves[GV.current_level_index] = null;
		
		#reset last_savepoint_id
		GV.level_last_savepoint_ids[GV.current_level_index] = GV.level_initial_savepoint_ids[GV.current_level_index];
		
		GV.changing_level = true;
		GV.reverting = false;
		GV.savepoint_id = GV.level_initial_savepoint_ids[GV.current_level_index];
		GV.player_power = GV.level_initial_player_powers[GV.current_level_index];
		GV.player_ssign = GV.level_initial_player_ssigns[GV.current_level_index];
		game.change_level_faded(GV.current_level_index);

func on_revert():
	if GV.abilities["revert"]: #if savepoint save exists load it else do a discount restart
		GV.changing_level = true;
		GV.reverting = true;
		game.change_level_faded(GV.current_level_index);

func new_snapshot():
	#print("NEW SNAPSHOT");
	remove_last_snapshot_if_not_meaningful();
	current_snapshot = PlayerSnapshot.new(self);
	player_snapshots.push_back(current_snapshot);

func remove_last_snapshot_if_not_meaningful():
	if is_instance_valid(current_snapshot):
		current_snapshot.reset_baddie_flags();
		if not current_snapshot.meaningful():
			player_snapshots.pop_back();
			current_snapshot.remove();
			current_snapshot = null;
			#print("OVERWRITE LAST SNAPSHOT");
