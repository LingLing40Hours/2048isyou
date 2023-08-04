class_name Level
extends Node2D

#unlocker areas must not be collision layer1, else they interfere with tile movement

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";
@onready var scoretiles:Node2D = $ScoreTiles;
@onready var savepoints:Node2D = $SavePoints;
@onready var baddies:Node2D = $Baddies;
@onready var freedom:Area2D = $Freedom;

var players = []; #if player, add here in _ready()

var initial_goal_id:int = -1; #id of goal where player first enters level
#the first player to enter any savepoint, whose value will be respawned
#on save, other players will become regular tiles
var player_saved:ScoreTile;
var player_power:int;
var player_ssign:int;

var player_snapshots:Array[PlayerSnapshot] = [];
var current_snapshot:PlayerSnapshot; #last in array, might not be meaningful, baddie flags not reset


func _ready():
	if not GV.current_level_from_save: #first time entering lv
		initial_goal_id = GV.goal_id;
		

func _input(event):
	if not GV.changing_level:
		if event.is_action_pressed("home"):
			on_home();
		elif event.is_action_pressed("restart"):
			on_restart();
		elif event.is_action_pressed("move"): #new snapshot
			#print("NEW SNAPSHOT");
			if is_instance_valid(current_snapshot):
				current_snapshot.reset_baddie_flags();
				if not current_snapshot.meaningful():
					player_snapshots.pop_back();
					current_snapshot.remove();
			current_snapshot = PlayerSnapshot.new(self);
			player_snapshots.push_back(current_snapshot);
		elif event.is_action_pressed("undo"):
			if GV.abilities["undo"] and player_snapshots:
				var snapshot = player_snapshots.pop_back();
				if snapshot.meaningful():
					snapshot.reset_baddie_flags();
					snapshot.checkout();
				elif player_snapshots:
					#print("USING PREV SNAPSHOT");
					snapshot.remove();
					snapshot = player_snapshots.pop_back();
					snapshot.checkout();


#isn't freed, isn't null, and has non-player tile
func is_snapshot_valid(snapshot):
	if is_instance_valid(snapshot) and snapshot.has_non_player():
		return true;
	return false;

func save():
	var save_dict = {
		
	};

func on_home():
	if GV.abilities["home"]:
		GV.changing_level = true;
		GV.goal_id = -1;
		game.change_level_faded(0);

func on_restart():
	if GV.abilities["restart"]:
		GV.changing_level = true;
		GV.goal_id = initial_goal_id;
		game.change_level_faded(GV.current_level_index);
