class_name Level
extends Node2D

#unlocker areas must not be collision layer1, else they interfere with tile movement

@onready var game:Node2D = $"/root/Game";
@onready var scoretiles:Node2D = $ScoreTiles;
@onready var savepoints:Node2D = $SavePoints;
@onready var baddies:Node2D = $Baddies;
@onready var freedom:Area2D = $Freedom;

var players = []; #if player, add here in _ready()

#the first player to enter any savepoint, whose value will be respawned
#on save, other players will become regular tiles
@export var resolution_t:Vector2i = GV.RESOLUTION_T;
@export var player_saved:ScoreTile;

var player_snapshots:Array[PlayerSnapshot] = [];
var current_snapshot:PlayerSnapshot; #last in array, might not be meaningful, baddie flags not reset


func _ready():
	set_level_name();
	
	if not GV.current_level_from_save: #first time entering lv
		#print("set initial SVID to ", GV.savepoint_id);
		GV.level_initial_savepoint_ids[GV.current_level_index] = GV.savepoint_id;
		

func _input(event):
	if not GV.changing_level:
		if event.is_action_pressed("home"):
			on_home();
		elif event.is_action_pressed("restart"):
			on_restart();
		elif event.is_action_pressed("move"): #new snapshot
			print("NEW SNAPSHOT");
			remove_last_snapshot_if_not_meaningful();
			current_snapshot = PlayerSnapshot.new(self);
			player_snapshots.push_back(current_snapshot);
		elif event.is_action_pressed("undo"):
			if GV.abilities["undo"] and player_snapshots:
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
					GV.current_savepoint_snapshot_locations.pop_back();
					GV.current_savepoint_snapshot_locations_new.pop_back();
					
					#update last savepoint id
					if GV.current_savepoint_ids:
						GV.level_last_savepoint_ids[GV.current_level_index] = GV.current_savepoint_ids.back();
					else:
						GV.level_last_savepoint_ids[GV.current_level_index] = GV.level_initial_savepoint_ids[GV.current_level_index];
					
		elif event.is_action_pressed("revert"):
			on_revert();
		elif event.is_action_pressed("copy"):
			on_copy();


func save():
	var save_dict = {
		
	};

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
		GV.current_savepoint_powers = [GV.level_initial_player_powers[GV.current_level_index]];
		GV.current_savepoint_ssigns = [GV.level_initial_player_ssigns[GV.current_level_index]];
		game.change_level_faded(GV.current_level_index);

func on_revert():
	if GV.abilities["revert"]: #if savepoint save exists load it else do a discount restart
		GV.changing_level = true;
		GV.reverting = true;
		game.change_level_faded(GV.current_level_index);
			

func set_level_name():
	if $Background.has_node("LevelName"):
		game.current_level_name = $"Background/LevelName";
		game.current_level_name.modulate.a = 0;
	else:
		game.current_level_name = null;

func remove_last_snapshot_if_not_meaningful():
	if is_instance_valid(current_snapshot):
		current_snapshot.reset_baddie_flags();
		if not current_snapshot.meaningful():
			player_snapshots.pop_back();
			current_snapshot.remove();
			print("OVERWRITE LAST SNAPSHOT");

func on_copy():
	if GV.abilities["copy"]:
		#declare and init level array
		var level_array = [];
		for row_itr in resolution_t.y:
			var row = [];
			row.resize(resolution_t.x);
			row.fill(GV.StuffIds.EMPTY);
			level_array.push_back(row);
		
		#store non-baddie stuff ids
		for tile in scoretiles.get_children():
			var pos_t = GV.world_to_pos_t(tile.position);
			var id;
			if tile.power == -1:
				id = GV.StuffIds.ZERO;
			elif tile.power == 0 and tile.ssign == -1:
				id = GV.StuffIds.NEG_ONE;
			else:
				id = tile.power * tile.ssign;
			level_array[pos_t.y][pos_t.x] = id;
		
		for savepoint in savepoints.get_children():
			if savepoint is Goal:
				for node in savepoint.tile_centers.get_children():
					var pos_t = GV.world_to_pos_t(node.global_position);
					#bound check
					if pos_t.x >= 0 and pos_t.x < resolution_t.x and pos_t.y >= 0 and pos_t.y < resolution_t.y:
						level_array[pos_t.y][pos_t.x] = GV.StuffIds.GOAL;
			else:
				var pos_t = GV.world_to_pos_t(savepoint.position);
				level_array[pos_t.y][pos_t.x] = GV.StuffIds.SAVEPOINT;
		
		for row_itr in resolution_t.y:
			for col_itr in resolution_t.x:
				var id = $Walls.get_cell_source_id(0, Vector2i(col_itr, row_itr));
				if id != -1:
					level_array[row_itr][col_itr] = -id - 40;
		
		#add to clipboard
		DisplayServer.clipboard_set(str(level_array));
