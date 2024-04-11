extends Node2D

@onready var GV:Node = $"/root/GV";

@onready var fader:AnimationPlayer = $"Overlay/AnimationPlayer";
@onready var right_sidebar:VBoxContainer = $"GUI/HBoxContainer/RightSideBar";
@onready var mode_label:Label = right_sidebar.get_node("MoveMode");

@onready var combine_sound = $"Audio/Combine";
@onready var slide_sound = $"Audio/Slide";
@onready var split_sound = $"Audio/Split";
@onready var shift_sound = $"Audio/Shift";

var current_level:Node2D;
var current_level_name:Label;
var levels = [];
var level_saves = [];
var next_level_index:int;


func _ready():
	#load levels
	level_saves.resize(GV.LEVEL_COUNT);
	
	for i in range(GV.LEVEL_COUNT):
		levels.append(load("res://Levels/Level "+str(i)+".tscn"));
	add_level(GV.current_level_index);
	
	#init mode label
	change_move_mode(GV.player_snap);
	
	#generate hash numbers
	#$Pathfinder.generate_hash_numbers(GV.RESOLUTION_T);
	
	#testing

signal toggle_game_paused(is_paused : bool)

var game_paused : bool = false:
	get:
		return game_paused
	set(value):
		game_paused = value
		get_tree().paused = game_paused
		emit_signal("toggle_game_paused", game_paused)

func _input(event):
	if event.is_action_pressed("change_move_mode") and GV.abilities["move_mode"]:
		change_move_mode(not GV.player_snap);
		
		#update player(s) state
		for player in current_level.players:
			if player.get_state() not in ["merging1", "merging2", "combining", "splitting"]:
				var next_state;
				if GV.player_snap:
					next_state = "snap";
					#update player pos_t
					player.pos_t = GV.world_to_pos_t(player.position);
				else:
					next_state = "slide";
				player.change_state(next_state);
	elif event.is_action_pressed("ui_cancel"):
		game_paused = !game_paused;

#defer this until previous level has been freed
func add_level(n):
	var level:Node2D;
	
	if GV.reverting and GV.current_savepoint_ids:
		print("LOAD FROM SAVEPOINT");
		GV.savepoint_id = GV.current_savepoint_ids.pop_back();
		GV.level_last_savepoint_ids[n] = GV.savepoint_id;
		var packed_level = GV.current_savepoint_saves.pop_back();
		level_saves[n] = packed_level; #rollback level save to savepoint
		level = packed_level.instantiate();
		
		#migrate old snapshots to new level
		level.player_snapshots = GV.temp_player_snapshots;
		level.player_snapshots.resize(GV.current_snapshot_sizes.pop_back());
		
		#update snapshots' level refs
		for snapshot in level.player_snapshots:
			snapshot.level = level;
		
		GV.current_level_from_save = true;
	elif GV.reverting: #and current_savepoint_ids empty
		print("LOAD FROM INITIAL");
		level_saves[n] = null;
		#clear last savepoint id
		GV.level_last_savepoint_ids[n] = GV.level_initial_savepoint_ids[n];
		
		GV.savepoint_id = GV.level_initial_savepoint_ids[n];
		GV.current_savepoint_powers = [GV.level_initial_player_powers[n]];
		GV.current_savepoint_ssigns = [GV.level_initial_player_ssigns[n]];
		level = levels[n].instantiate();
		GV.current_level_from_save = false;
	elif level_saves[n]:
		print("LOAD FROM SAVE");
		level = level_saves[n].instantiate();
		GV.current_level_from_save = true;
	else:
		print("NO SAVE FOUND");
		level = levels[n].instantiate();
		GV.current_level_from_save = false;
	
	current_level = level;
	
	#remove and free saved player
	if current_level is Level:
		var player_saved = current_level.player_saved;
		if is_instance_valid(player_saved):
			current_level.get_node("ScoreTiles").remove_child(current_level.player_saved);
			player_saved.free();
	
	#migrate old snapshot locations
	if GV.reverting and GV.current_level_from_save:
		var scoretiles = current_level.get_node("ScoreTiles");
		var baddies = current_level.get_node("Baddies");
		var tiles_snapshot_locations = GV.current_savepoint_tiles_snapshot_locations.pop_back();
		var tiles_snapshot_locations_new = GV.current_savepoint_tiles_snapshot_locations_new.pop_back();
		var baddies_snapshot_locations = GV.current_savepoint_baddies_snapshot_locations.pop_back();
		
		for tile_itr in scoretiles.get_child_count():
			var tile = scoretiles.get_child(tile_itr);
			tile.snapshot_locations = tiles_snapshot_locations[tile_itr];
			tile.snapshot_locations_new = tiles_snapshot_locations_new[tile_itr];
		for baddie_itr in baddies.get_child_count():
			baddies.get_child(baddie_itr).snapshot_locations = baddies_snapshot_locations[baddie_itr];
	
	add_child(level);
	GV.changing_level = false;
	
	#update right sidebar visibility
	#right_sidebar.visible = true if n else false;

#update current level and current level index
func change_level(n):
	if (n >= GV.LEVEL_COUNT):
		return;
	
	current_level.queue_free();
	call_deferred("add_level", n);
	GV.current_level_index = n;
	
	if GV.reverting: #save player snapshots
		GV.temp_player_snapshots = current_level.player_snapshots.duplicate();
	elif current_level is Level: #clear saves for old level
		current_level.player_snapshots.clear();
		GV.current_savepoint_ids.clear();
		GV.current_savepoint_saves.clear();
		GV.current_snapshot_sizes.clear();
		GV.current_savepoint_powers.clear();
		GV.current_savepoint_ssigns.clear();

		GV.temp_player_snapshots.clear();
		GV.temp_player_snapshot_locations.clear();
		GV.temp_player_snapshot_locations_new.clear();
		GV.current_savepoint_tiles_snapshot_locations.clear();
		GV.current_savepoint_tiles_snapshot_locations_new.clear();
		GV.current_savepoint_baddies_snapshot_locations.clear();
		
		#clear snapshot locations
		for scoretile in current_level.scoretiles.get_children():
			scoretile.snapshot_locations.clear();
			scoretile.snapshot_locations_new.clear();
		for baddie in current_level.baddies.get_children():
			baddie.snapshot_locations.clear();

func change_level_faded(n):
	if (n >= GV.LEVEL_COUNT):
		return;
	next_level_index = n;
	
	#set speed scale and fade
	if GV.reverting:
		fader.speed_scale = GV.FADER_SPEED_SCALE_MINOR;
	else:
		fader.speed_scale = GV.FADER_SPEED_SCALE_MAJOR;
	fader.play("fade_in_black");

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "fade_in_black": #fade out black
		change_level(next_level_index);
		fader.play("fade_out_black");
	elif anim_name == "fade_out_black":
		if current_level_name != null and not GV.reverting: #fade in level name
			var tween = current_level_name.create_tween().set_trans(Tween.TRANS_LINEAR);
			tween.finished.connect(_on_level_name_faded_in);
			tween.tween_property(current_level_name, "modulate:a", 1, GV.LEVEL_NAME_FADE_IN_TIME);
			

func change_move_mode(snap):
	GV.player_snap = snap;
	
	#update label
	var s:String = "Mode: ";
	s += "snap" if snap else "slide";
	mode_label.text = s;

func _on_level_name_faded_in(): #display level name
	var timer = get_tree().create_timer(GV.LEVEL_NAME_DISPLAY_TIME);
	timer.timeout.connect(_on_level_name_displayed);

func _on_level_name_displayed(): #fade out level name
	if current_level_name != null:
		var tween = current_level_name.create_tween().set_trans(Tween.TRANS_LINEAR);
		tween.tween_property(current_level_name, "modulate:a", 0, GV.LEVEL_NAME_FADE_OUT_TIME);

func save_level(savepoint_id):
	print("SAVE LEVEL");
	#pack
	var packed_level = PackedScene.new();
	packed_level.pack(current_level);
	
	#find save path
	var save_path:String;
	if savepoint_id == -1:
		save_path = "res://Saves/Level%d.tscn" % GV.current_level_index;
	else:
		save_path = "res://Saves/Level%d_%d.tscn" % [GV.current_level_index, GV.current_savepoint_ids.size()];
	
	#save and store in array(s)
	ResourceSaver.save(packed_level, save_path);
	level_saves[GV.current_level_index] = packed_level;
	if savepoint_id != -1:
		GV.current_savepoint_saves.push_back(packed_level);
