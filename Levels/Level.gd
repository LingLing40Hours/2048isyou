class_name Level
extends Node2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";

var players = []; #if player, add here in _ready()
var player_snapshots:Array[PlayerSnapshot] = [];
#last snapshot in array, might not have non-player tile, baddie flags not reset
var current_snapshot:PlayerSnapshot;


func _input(event):
	if not GV.changing_level:
		if event.is_action_pressed("home"):
			if GV.abilities["home"]:
				GV.changing_level = true;
				game.change_level_faded(0);
		elif event.is_action_pressed("restart"):
			if GV.abilities["restart"]:
				GV.changing_level = true;
				game.change_level_faded(GV.current_level_index);
		elif event.is_action_pressed("move"): #new snapshot
			print("NEW SNAPSHOT");
			if is_instance_valid(current_snapshot):
				current_snapshot.reset_baddie_flags();
				if not current_snapshot.meaningful():
					player_snapshots.pop_back();
			current_snapshot = PlayerSnapshot.new(self);
			player_snapshots.push_back(current_snapshot);
		elif event.is_action_pressed("undo"):
			if GV.abilities["undo"] and player_snapshots:
				var snapshot = player_snapshots.pop_back();
				if snapshot.meaningful():
					snapshot.reset_baddie_flags();
					snapshot.checkout();
				elif player_snapshots:
					print("USING PREV SNAPSHOT");
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
