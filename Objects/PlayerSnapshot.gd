class_name PlayerSnapshot
extends Node
#used to store an undoable player action
#player/tile position/value before push/merge/split
#baddie position and velocity (if knocked?)
#don't save snapshots for player sliding by itself

#only allow undo when not changing level
#upon die(), revert to last savepoint

var tiles:Array[ScoreTile] = [];
var tile_is_players:Array[bool] = [];
var tile_positions:Array[Vector2] = [];
var tile_powers:Array[int] = [];
var tile_ssigns:Array[int] = [];

var baddies:Array[CharacterBody2D] = [];
var baddie_positions:Array[Vector2] = [];
var baddie_velocities:Array[Vector2] = [];


func _init(tiles_:Array[ScoreTile]):
	#tiles
	for tile in tiles_:
		tiles.push_back(tile);
		tile_is_players.push_back(tile.is_player);
		tile_positions.push_back(tile.position);
		tile_powers.push_back(tile.power);
		tile_ssigns.push_back(tile.ssign);
	
		#baddies
		if tile.is_player:
			save_nearby_baddies(tile.get_node("PhysicsEnabler2"), GV.PLAYER_SNAPSHOT_BADDIE_RANGE);


func save_nearby_baddies(shapecast, side_length):
	shapecast.enabled = true;
	var temp_size:Vector2 = shapecast.shape.size;
	shapecast.shape.size = Vector2(side_length, side_length);
	shapecast.force_shapecast_update();
	
	for i in shapecast.get_collision_count():
		var body = shapecast.get_collider(i);
		
		if body.is_in_group("baddie"): #save position and velocity
			baddies.push_back(body);
			baddie_positions.push_back(body.position);
			baddie_velocities.push_back(body.velocity);
	
	shapecast.shape.size = temp_size;
	shapecast.enabled = false;

func undo():
	#if a tile/baddie is null, instantiate a new one
	#otherwise revert its parameters
	pass;

func redo():
	pass;
