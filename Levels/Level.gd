#unlocker areas must not be collision layer1, else they interfere with tile movement
class_name Level
extends Node2D

signal repeat_input(input_type);

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
var last_input_type:int;
var last_input_modifier:String = "slide";
var last_input_move:String;
var last_action_finished:bool = true;


func set_level_name():
	if has_node("LevelName"):
		game.current_level_name = $LevelName;
		game.current_level_name.modulate.a = 0;
	else:
		game.current_level_name = null;

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
	repeat_input.connect(_on_repeat_input);
	add_child(atimer);

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

#update last_input_mod/move and accel timer
#return true to add premove
func update_last_input(event) -> bool:
	var modifier_pressed:bool = false;
	var move_changed:bool = false;
	
	#last input modifier
	if event.is_action_pressed("cc"): #Cmd/Ctrl
		last_input_modifier = "split";
		modifier_pressed = true;
	elif event.is_action_pressed("shift"):
		last_input_modifier = "shift";
		modifier_pressed = true;
	elif event.is_action_released("cc") or event.is_action_released("shift"):
		last_input_modifier = "slide";
		#if move is still held, wait for timeout before starting move
		print("RELEASE")
		print("last input move: ", last_input_move)
		if last_input_move:
			last_input_type = GV.InputType.MOVE;
			atimer.start(GV.MOVE_REPEAT_DELAY_F0, GV.MOVE_REPEAT_DELAY_DF, GV.MOVE_REPEAT_DELAY_DDF, GV.MOVE_REPEAT_DELAY_FMIN);
			return false;
	
	#last input move
	elif event.is_action_pressed("move_left"):
		last_input_move = "left";
		move_changed = true;
	elif event.is_action_pressed("move_right"):
		last_input_move = "right";
		move_changed = true;
	elif event.is_action_pressed("move_up"):
		last_input_move = "up";
		move_changed = true;
	elif event.is_action_pressed("move_down"):
		last_input_move = "down";
		move_changed = true;
	elif	(event.is_action_released("move_left") and last_input_move == "left") or \
			(event.is_action_released("move_right") and last_input_move == "right") or \
			(event.is_action_released("move_up") and last_input_move == "up") or \
			(event.is_action_released("move_down") and last_input_move == "down"):
		last_input_move = "";
		move_changed = true;
	
	if (modifier_pressed and last_input_move) or move_changed: #stop repeat
		atimer.stop();
		
		if last_input_move: #add premove
			last_input_type = GV.InputType.MOVE;
			return true;
	
	return false;

func _on_player_enter_snap(prev_state):
	if prev_state == null: #initial ready doesn't count
		return;
	
	last_action_finished = true;
	if atimer.is_timeouted(): #input hasn't changed, repeat last action
		#print("enter snap repeat")
		atimer.repeat();
		repeat_input.emit(last_input_type);
		last_action_finished = false;

func _on_atimer_timeout():
	print("TIMEOUT")
	print("last action finished: ", last_action_finished)
	if last_input_type != GV.InputType.MOVE or last_action_finished:
		#print("timeout repeat")
		atimer.repeat();
		repeat_input.emit(last_input_type);
		last_action_finished = false;

func _on_repeat_input(input_type:int):
	if input_type != GV.InputType.UNDO:
		return;
	
	on_undo();
	if not player_snapshots: #no more history
		atimer.stop();

func _input(event):
	if event.is_action_pressed("copy"):
		on_copy();
		atimer.stop();
	elif not GV.changing_level:
		if event.is_action_pressed("home"):
			on_home();
			atimer.stop();
		elif event.is_action_pressed("restart"):
			on_restart();
			atimer.stop();
		elif event.is_action_pressed("move"):
			pass;
		elif event.is_action_pressed("undo"):
			atimer.start(GV.UNDO_REPEAT_DELAY_F0, GV.UNDO_REPEAT_DELAY_DF, GV.UNDO_REPEAT_DELAY_DDF, GV.UNDO_REPEAT_DELAY_FMIN);
			last_input_type = GV.InputType.UNDO;
			on_undo();
		elif event.is_action_released("undo"):
			atimer.stop();
		elif event.is_action_pressed("revert"):
			on_revert();
			atimer.stop();

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
			print("OVERWRITE LAST SNAPSHOT");
