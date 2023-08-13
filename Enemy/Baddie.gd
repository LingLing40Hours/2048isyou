class_name Baddie
extends CharacterBody2D

var packed_baddie:PackedScene;

var snapshotted:bool = false;
@export var snapshot_locations:Array[Vector2i] = [];

@onready var game:Node2D = $"root/Game";


func _ready():
	if !owner: #baddie is a snapshot duplicate, set owner
		owner = game.current_level;
	
	#update ref at last snapshot location
	if snapshot_locations:
		var location = snapshot_locations.back();
		game.current_level.player_snapshots[location.x].baddies[location.y] = self;
	
	#save packed scene of own type
	packed_baddie = load(scene_file_path);

func duplicate_custom() -> Baddie:
	var dup = packed_baddie.instantiate();
	dup.snapshot_locations = snapshot_locations.duplicate();
	
	return dup;
