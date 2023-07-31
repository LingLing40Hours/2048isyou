class_name PlayerSnapshot
extends Node
#used to store an undoable player action
#player/tile position/value before push/merge/split
#baddie position and velocity (if knocked?)
#don't save snapshots for player sliding by itself

#only allow undo when not changing level
#upon die(), revert to last savepoint

var new_tiles:Array[ScoreTile] = []; #created by action
var tiles:Array[ScoreTile] = []; #changed by action
var tile_duplicates:Array[ScoreTile] = [];
var tiles_all_player:bool = true;

var baddies:Array[CharacterBody2D] = [];
var baddie_duplicates:Array[CharacterBody2D] = [];

var level:Node2D;
var index:int;


func _init(level_):
	level = level_;
	index = level.player_snapshots.size();

func add_tile(tile):
	tiles.push_back(tile);
	
	#check if non-player
	if not tile.is_player:
		tiles_all_player = false;
	
	#duplicate tile
	tile_duplicates.push_back(tile.duplicate_custom());
	
	#save snapshot location
	tile.snapshot_locations.push_back(Vector2i(index, tiles.size() - 1));
	
	#save baddies
	if tile.is_player:
		save_nearby_baddies(tile.get_node("PhysicsEnabler2"), GV.PLAYER_SNAPSHOT_BADDIE_RANGE);

func add_new_tile(tile):
	new_tiles.push_back(tile);
	
	#save snapshot location
	tile.snapshot_locations_new.push_back(Vector2i(index, new_tiles.size() - 1));
	print("new snapshot location at ", Vector2i(index, new_tiles.size() - 1));

#not a slide of 1+ players
func meaningful() -> bool:
	return not tiles_all_player or new_tiles;

func reset_baddie_flags():
	for baddie in baddies:
		baddie.snapshotted = false;

func save_nearby_baddies(shapecast, side_length):
	shapecast.enabled = true;
	var temp_size:Vector2 = shapecast.shape.size;
	shapecast.shape.size = Vector2(side_length, side_length);
	shapecast.force_shapecast_update();
	
	for i in shapecast.get_collision_count():
		var body = shapecast.get_collider(i);
		
		if body.is_in_group("baddie") and not body.snapshotted: #save position and velocity using duplicate			
			baddies.push_back(body);
			baddie_duplicates.push_back(body.duplicate_custom());
			body.snapshotted = true;
			
			#save snapshot location
			body.snapshot_locations.push_back(Vector2i(index, baddies.size() - 1));
	
	shapecast.shape.size = temp_size;
	shapecast.enabled = false;

func checkout(): #reset to snapshot
	#remove new tiles
	for new_tile in new_tiles:
		if is_instance_valid(new_tile):
			new_tile.queue_free();
	
	reset_objects("tiles", "tile_duplicates", "ScoreTiles");
	reset_objects("baddies", "baddie_duplicates", "Baddies");
	
	queue_free();

#removes changed objects (if they still exist) and adds their duplicates
#category_name is name of the node in level under which objects are organized
func reset_objects(objects_name, duplicates_name, category_name):
	if objects_name not in self or duplicates_name not in self or not level.has_node(category_name):
		print("RESET ERROR");
		return;
	
	var objects = get(objects_name);
	var duplicates = get(duplicates_name);
	
	for object_index in objects.size():
		var object = objects[object_index];
		
		#remove changed object
		if is_instance_valid(object):
			object.queue_free();
		
		#update object reference in previous snapshot
		var dup = duplicates[object_index];
		var locations = dup.snapshot_locations;
		if locations:
			var location:Vector2i = locations[locations.size() - 1];
			if location.x == index - 1:
				var prev_snapshot = level.player_snapshots[location.x];
				prev_snapshot.get(objects_name)[location.y] = dup;
				#print("UPDATED REF");
		
		#update tile reference in previous new_tiles
		if dup is ScoreTile:
			var locations_new = dup.snapshot_locations_new;
			if locations_new:
				var location_new:Vector2i = locations_new[locations_new.size() - 1];
				if location_new.x == index - 1:
					var prev_snapshot = level.player_snapshots[location_new.x];
					prev_snapshot.get("new_tiles")[location_new.y] = dup;
					print("UPDATED NEW REF");
		
		#add duplicate
		level.get_node(category_name).call_deferred("add_child", dup);
