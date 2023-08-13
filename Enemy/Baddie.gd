class_name Baddie
extends CharacterBody2D

var packed_baddie:PackedScene;

var snapshotted:bool = false;
var snapshot_locations:Array[Vector2i] = [];

@onready var game:Node2D = $"root/Game";


func _ready():
	if !owner: #baddie is a snapshot duplicate, set owner
		owner = game.current_level;
	
	#save packed scene of own type
	packed_baddie = load(scene_file_path);

func duplicate_custom() -> Baddie:
	var dup = packed_baddie.instantiate();
	dup.snapshot_locations = snapshot_locations.duplicate();
	
	return dup;
