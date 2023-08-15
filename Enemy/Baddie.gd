class_name Baddie
extends CharacterBody2D

var packed_baddie:PackedScene;

var snapshotted:bool = false;
var snapshot_locations:Array[Vector2i] = [];

@onready var game:Node2D = $"/root/Game";


func _ready():
	if !owner: #baddie is a snapshot duplicate, set owner
		owner = game.current_level;
	
	#update ref at last snapshot location
	while snapshot_locations:
		var location = snapshot_locations.back();
		if location.x >= game.current_level.player_snapshots.size():
			snapshot_locations.pop_back();
		else:
			game.current_level.player_snapshots[location.x].baddies[location.y] = self;
			break;
	
	#save packed scene of own type
	packed_baddie = load(scene_file_path);

func duplicate_custom() -> Baddie:
	var dup = packed_baddie.instantiate();
	dup.snapshot_locations = snapshot_locations.duplicate();
	
	return dup;
