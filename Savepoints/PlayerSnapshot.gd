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
var enter_savepoint:bool = false;

var baddies:Array[CharacterBody2D] = [];
var baddie_duplicates:Array[CharacterBody2D] = [];

var level:Node2D;
var index:int;


func _init(level_):
	level = level_;
	index = level.player_snapshots.size();

func add_tile(tile):
	#print("ADD TILE");
	if tile.snapshot_locations and tile.snapshot_locations.back().x == index: #already added
		return;
	
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
		save_baddies(tile.get_nearby_baddies(GV.PLAYER_SNAPSHOT_BADDIE_RANGE));
	
	#debug

func add_new_tile(tile):
	new_tiles.push_back(tile);
	
	#save snapshot location
	tile.snapshot_locations_new.push_back(Vector2i(index, new_tiles.size() - 1));
	print("new snapshot location at ", Vector2i(index, new_tiles.size() - 1));

#not a slide of 1+ players
func meaningful() -> bool:
	return not tiles_all_player or new_tiles or enter_savepoint;

func reset_baddie_flags():
	for baddie in baddies:
		baddie.snapshotted = false;

func save_baddies(baddies_:Array[Baddie]):
	for baddie in baddies_:
		if not baddie.snapshotted: #save
			baddies.push_back(baddie);
			baddie_duplicates.push_back(baddie.duplicate_custom());
			baddie.snapshotted = true;
			
			#save snapshot location
			baddie.snapshot_locations.push_back(Vector2i(index, baddies.size() - 1));

func checkout(): #reset to snapshot
	if baddies:
		print("BADDIES!!!");
	
	#remove new tiles
	for new_tile in new_tiles:
		if is_instance_valid(new_tile):
			if new_tile.is_player:
				new_tile.remove_from_players();
			new_tile.queue_free();
			
	reset_objects("tiles", "tile_duplicates", "scoretiles");
	reset_objects("baddies", "baddie_duplicates", "baddies");
	
	queue_free();

#removes changed objects (if they still exist) and adds their duplicates
#category_name is name of node ref in level under which objects are organized
func reset_objects(objects_name, duplicates_name, category_name):
	if objects_name not in self or duplicates_name not in self or category_name not in level:
		print("RESET ERROR");
		return;
	
	var objects = get(objects_name);
	var duplicates = get(duplicates_name);
	
	for object_index in objects.size():
		var object = objects[object_index];
		
		#remove changed object
		if is_instance_valid(object):
			if object is ScoreTile and object.is_player:
				object.remove_from_players();
			object.queue_free();
			#print("REMOVE TILE at ", object.position);
		
		#update object reference in last snapshot
		var dup = duplicates[object_index];
		var locations = dup.snapshot_locations;
		if locations:
			var location:Vector2i = locations.back();
			var last_snapshot = level.player_snapshots[location.x];
			last_snapshot.get(objects_name)[location.y] = dup;
			#print("UPDATED REF at ", location);
		
		#update tile reference in last new_tiles
		if dup is ScoreTile:
			var locations_new = dup.snapshot_locations_new;
			if locations_new:
				var location_new:Vector2i = locations_new.back();
				var last_snapshot = level.player_snapshots[location_new.x];
				last_snapshot.get("new_tiles")[location_new.y] = dup;
				#print("UPDATED NEW REF at ", location_new);
		
		#add duplicate
		level.get(category_name).call_deferred("add_child", dup);
		#print("ADD DUPLICATE at ", dup.position);

#assume self is current snapshot (and thus objects are valid)
func remove():
	for tile in tiles:
		tile.snapshot_locations.pop_back();
	for tile in new_tiles:
		tile.snapshot_locations_new.pop_back();
	for baddie in baddies:
		baddie.snapshot_locations.pop_back();
	
	queue_free();
