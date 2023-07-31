class_name Baddie
extends CharacterBody2D

var packed_baddie:PackedScene;
var snapshotted:bool = false;
var snapshot_locations:Array[Vector2i] = [];


func duplicate_custom() -> Baddie:
	var dup = packed_baddie.instantiate();
	dup.snapshot_locations = snapshot_locations.duplicate();
	
	return dup;
