class_name ScoreTile
extends CharacterBody2D

signal start_action; #tells spawning savepoint to save; should be emitted before current snapshot becomes meaningful
signal enter_snap(prev_state); #may be connected to action; emit AFTER slide_dir has been reset

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";
@onready var visibility_notifier := $VisibleOnScreenNotifier2D;
@onready var sprites:Node2D = $Sprites;

@export var is_player:bool = false;
@export var is_hostile:bool = false;
@export var power:int = 1;
@export var ssign:int = 1;
@export var debug:bool = false;

#ref locations in snapshot arrays, must be copied in custom duplicate
var snapshot_locations:Array[Vector2i] = [];
var snapshot_locations_new:Array[Vector2i] = [];

var score_tile:PackedScene = preload("res://Objects/ScoreTile.tscn");
var img:Sprite2D = Sprite2D.new();
var animators:Array[ScoreTileAnimator] = [];
var pusheds:Array[ScoreTile] = []; #tiles pushed by self; to update collider's pusher after player is instantiated in split
var pusher:ScoreTile; #player at start of line, not immediate neighbor
var partner:ScoreTile;
var shift_ray:RayCast2D = null;
var tile_push_count:int = 0; #if merge possible, don't multipush (except for 0 at end)

var physics_on:bool = true;
var physics_enabler_count:int = 0; #turn physics off when this reaches 0
var slide_dir:Vector2i = Vector2i.ZERO;
var next_dirs:Array[Vector2i] = []; #for premoving
var next_moves:Array[String] = []; #slide, split, shift
#var func_slide:Callable = Callable(self, "slide");
#var func_split:Callable = Callable(self, "split");
#var func_shift:Callable = Callable(self, "shift");

var splitted:bool = false; #created from split, not settled yet
var snap_slid:bool = false; #slid by player in snap mode; if true, don't play snap sound bc it would overlap with that of player
var invincible:bool = false; #spawn protection for player; see GV.PLAYER_SPAWN_INVINCIBILITY_TIME


func _ready():
	#visibility
	visibility_notifier.screen_entered.connect(sprites.show);
	visibility_notifier.screen_exited.connect(sprites.hide);
	
	#enter snap
	enter_snap.connect(game.current_level._on_player_enter_snap);
	
	#if tile is a snapshot duplicate, set owner
	if !owner:
		owner = game.current_level;
	
	#remove extra snapshot locations, update ref at last snapshot location
	while snapshot_locations:
		var location = snapshot_locations.back();
		if location.x >= game.current_level.player_snapshots.size():
			snapshot_locations.pop_back();
		else:
			game.current_level.player_snapshots[location.x].tiles[location.y] = self;
			break;
	while snapshot_locations_new:
		var location_new = snapshot_locations_new.back();
		if location_new.x >= game.current_level.player_snapshots.size():
			snapshot_locations_new.pop_back();
		else:
			game.current_level.player_snapshots[location_new.x].new_tiles[location_new.y] = self;
			break;
	
	#settings
	if power == 12:
		is_player = true;
	
	if is_player:
		if splitted:
			set_layers(false, true);
		else:
			set_masks(true);
			
			#spawn protection
			invincible = true;
			var timer = get_tree().create_timer(GV.PLAYER_SPAWN_INVINCIBILITY_TIME);
			timer.timeout.connect(_on_invincibility_timeout);
		
		player_settings();
		
		#set level's initial player value
		if not GV.current_level_from_save:
			GV.level_initial_player_powers[GV.current_level_index] = power;
			GV.level_initial_player_ssigns[GV.current_level_index] = ssign;
	else:
		#turn off physics
		set_physics(false);
		physics_on = false;
	
	#scale shapecasts (bc of floating point error)
	$Shape1.shape.size.y *= GV.PLAYER_COLLIDER_SCALE;
	$Shape2.shape.size.x *= GV.PLAYER_COLLIDER_SCALE;
	$Shape3.shape.size.y *= GV.PLAYER_COLLIDER_SCALE;
	$Shape4.shape.size.x *= GV.PLAYER_COLLIDER_SCALE;
	
	#add sprite
	update_texture(img, power, ssign, is_player, is_hostile);
	sprites.add_child(img);
	
	#set initial state
	var initial_state = "tile";
	if is_player:
		if GV.player_snap:
			initial_state = "snap";
		else:
			initial_state = "slide";
	$FSM.setState($FSM.states[initial_state]);
	
func _input(event):
	if event.is_action_pressed("debug"):
		#test pathfinder
		if is_player:
			game.current_level.repeat_input.disconnect(_on_repeat_input);
			game.current_level.new_snapshot();
			var pos_t = GV.world_to_pos_t(position);
			var path = $Pathfinder.pathfind(1, game.current_level.on_copy(), pos_t, Vector2i(9, 9));
			print("path length: ", path.size());
			print(path);
			print("pos_t: ", pos_t);
			for action in path:
				next_dirs.push_back(Vector2i(action.x, action.y));
				next_moves.push_back("split" if action.z else "slide");

func _physics_process(_delta):
	#debug_frame();
	pass;

func debug_frame():
	if debug:
		#print(get_collision_layer_value(1));
		#print("state: ", get_state());
		#print("value: ", pow(2, power) * ssign);
		#print("snapshot locs: ", snapshot_locations);
		#print("pusher: ", pusher);
		#print(next_dirs);
		#print("physics on: ", physics_on);
		pass;

func update_texture(s:Sprite2D, score_pow, score_sign, is_player, is_hostile):
	var texture_path:String = "res://Sprites/2_";
	
	#power
	if score_pow < 0:
		texture_path += "n";
	else:
		texture_path += str(score_pow);
	
	#sign
	if score_sign == -1 and score_pow >= 0:
		texture_path += "m";
	
	#dark
	if is_player:
		texture_path += "k";
	elif is_hostile:
		texture_path += "i";
	
	s.texture = load(texture_path + ".png");

func get_ray(dir:Vector2i) -> RayCast2D:
	if dir == Vector2i(1, 0):
		return $Ray1;
	elif dir == Vector2i(0, -1):
		return $Ray2;
	elif dir == Vector2i(-1, 0):
		return $Ray3;
	elif dir == Vector2i(0, 1):
		return $Ray4;
	else:
		return null;

func get_shape(dir:Vector2i) -> ShapeCast2D:
	if dir == Vector2i(1, 0):
		return $Shape1;
	elif dir == Vector2i(0, -1):
		return $Shape2;
	elif dir == Vector2i(-1, 0):
		return $Shape3;
	elif dir == Vector2i(0, 1):
		return $Shape4;
	else:
		return null;

#if input, pushes to next_moves and next_dirs
func get_next_action():
	#check if movement held
	if game.current_level.last_input_move:
		#get event name
		var prefix = game.current_level.last_input_modifier;
		if prefix == "slide":
			prefix = "move";
		var event_name = prefix + "_" + game.current_level.last_input_move;
		
		#check if just pressed
		if Input.is_action_just_pressed(event_name):
			#print("PREMOVE ADDED");
			next_dirs.push_back(GV.directions[game.current_level.last_input_move]);
			next_moves.push_back(game.current_level.last_input_modifier);

#assume level.last_input is valid
func _on_repeat_input(input_type:int):
	#don't repeat input if undo or there are unconsumed premoves
	if input_type != GV.InputType.MOVE or get_state() != "snap" or next_moves:
		return;
	
	#var action:Callable = get("func_" + game.current_level.last_input_modifier);
	var action:Callable = Callable(self, game.current_level.last_input_modifier);
	action.call(GV.directions[game.current_level.last_input_move]);
		

func slide(dir:Vector2i) -> bool:
	if get_state() not in ["tile", "snap"]:
		#print("SLIDE FAILED, state is ", get_state());
		return false;
	
	#reset tile push count
	tile_push_count = 0;
	
	#increment pusher tile count
	if is_instance_valid(pusher):
		pusher.tile_push_count += 1;
		if pusher.tile_push_count > GV.abilities["tile_push_limit"]: #exit early
			return false;
		
		#join pusher.pusheds
		pusher.pusheds.push_back(self);
	
	#find if at push limit
	var at_push_limit:bool = false;
	var push_count:int = pusher.tile_push_count if is_instance_valid(pusher) else tile_push_count;
	if push_count == GV.abilities["tile_push_limit"]:
		at_push_limit = true;
	
	#determine whether to slide or merge or, if obstructed, idle
	var next_state:Node2D;
	var xaligned = is_xaligned();
	var yaligned = is_yaligned();
	if is_player: #ignore ray if not aligned with tile grid
		if (dir.x and not xaligned) or (dir.y and not yaligned):
			next_state = $FSM.states.sliding;
	
	if next_state == null:
		next_state = $FSM.states.sliding;
		
		#find shapecast in slide direction
		var shape = get_shape(dir);
		#if splitted, tile was newly added, shapecast hasn't updated
		#if pusher splitted, physics was just toggled off then on, shapecast hasn't updated
		#if next_moves nonempty, premoved, last shapecast update may have caught a tile corner
		if splitted or (pusher != null and pusher.splitted) or next_moves:
			shape.force_shapecast_update();
		
		for i in shape.get_collision_count():
			var collider := shape.get_collider(i);
			
			if collider.is_in_group("wall"): #obstructed
				return false;
				
			if collider is ScoreTile:
				if not xaligned or not yaligned: #in snap mode, must be aligned to do stuff
					return false;
				if collider.get_state() not in ["tile", "snap"]:
					return false;
				
				#set collider pusher (required to call collider.slide())
				if not collider.is_player:
					if is_instance_valid(pusher):
						collider.pusher = pusher;
					else:
						collider.pusher = self;
				
				if collider.is_player and collider.slide(dir): #receding player
					next_state = $FSM.states.sliding;
				elif power in [-1, collider.power] and power < GV.TILE_POW_MAX: #merge as 0 or equal power
					partner = collider;
					collider.pusher = null;
					collider.partner = self;
					next_state = $FSM.states.merging1;
				elif at_push_limit and collider.power == -1: #merge with 0
					partner = collider;
					collider.pusher = null;
					collider.partner = self;
					next_state = $FSM.states.merging1;
				elif collider.slide(dir): #try to slide collider
					collider.snap_slid = true;
					next_state = $FSM.states.sliding;
				elif collider.power == -1: #merge with 0
					partner = collider;
					collider.pusher = null;
					collider.partner = self;
					next_state = $FSM.states.merging1;
				else:
					collider.pusher = null;
					pusheds.clear(); #only necessary if self is pusher (pusher == null)
					return false;
			else: #collider not wall or scoretile, proceed with slide
				next_state = $FSM.states.sliding;
	
	#check pusher tile count
	push_count = pusher.tile_push_count if is_instance_valid(pusher) else tile_push_count;
	if push_count > GV.abilities["tile_push_limit"]:
		pusheds.clear(); #only necessary if self is pusher (pusher == null)
		return false;
	
	#signal
	start_action.emit();
	
	slide_dir = dir;
	$FSM.curState.next_state = next_state;
	return true;


func split(dir:Vector2i) -> bool:
	if power <= 0: #1, -1, 0 cannot split
		return false;
	if get_state() != "snap":
		return false;
	if not GV.abilities["split"]:
		return false;
	if not is_xaligned() or not is_yaligned():
		return false;
	
	#get shapecast in direction
	var shape = get_shape(dir);
	if next_moves:
		shape.force_shapecast_update();
	
	for i in shape.get_collision_count():
		var collider := shape.get_collider(i);

		if collider.is_in_group("wall"): #obstructed
			return false;
			
		if collider is ScoreTile:
			if not collider.is_xaligned() or not collider.is_yaligned():
				return false;
			if collider.get_state() not in ["tile", "snap"]:
				return false;
			
			if collider.is_player and collider.slide(dir): #recede split
				continue;
			elif power - 1 == collider.power and collider.power < GV.TILE_POW_MAX: #merge split
				continue;
				
			#act as temporary pusher before splitted tile spawns
			tile_push_count = 0;
			collider.pusher = self;
			
			if collider.slide(dir): #slide split
				collider.snap_slid = true;
			else:
				collider.pusher = null;
				pusheds.clear();
				
				if collider.power == -1: #merge with 0
					pass;
				else: #obstructed
					return false;
	
	#signal
	start_action.emit();
	
	slide_dir = dir;
	$FSM.curState.next_state = $FSM.states.splitting;
	return true;


func shift(dir:Vector2i) -> bool:
	if get_state() != "snap":
		return false;
	if not GV.abilities["shift"]:
		return false;
	
	#get ray
	var ray = get_ray(dir);

	#consult ray if aligned with tile grid
	if (dir.x and is_xaligned()) or (dir.y and is_yaligned()):
		#check for obstruction
		if ray.is_colliding():
			var collider = ray.get_collider();
			if collider is ScoreTile or collider.is_in_group("wall"):
				return false;
	
	#signal
	start_action.emit();
	
	slide_dir = dir;
	shift_ray = ray;
	$FSM.curState.next_state = $FSM.states.shifting;
	return true;
	

func levelup():
	if get_state() not in ["tile", "snap"]:
		return;
	
	#update power
	if power == -1: #0, assume partner value
		power = partner.power;
		ssign = partner.ssign;
	elif partner.power == -1: #partner is 0, retain value
		pass;
	elif partner.ssign == ssign: #same sign same power merge
		power += 1;
	else: #opposite sign same power merge
		power = -1;
	#print("POWER: ", power);
	
	#convert to hostile
	is_hostile = partner.is_hostile;

	#convert to player
	if not is_player and partner.is_player:
		#print("CONVERT TO PLAYER");
		is_player = true;
		set_masks(true);
		set_physics(true);
		physics_on = true;
		
		player_settings();
		enable_physics_immediately();
	
	$FSM.curState.next_state = $FSM.states.combining;

	
func get_state() -> String:
	return $FSM.curState.name;

func change_state(s:String):
	$FSM.setState($FSM.states[s]);


func _on_physics_enabler_body_entered(body):
	if body != self and body is ScoreTile and not body.is_player:
		if body.physics_enabler_count == 0 and not body.physics_on:
			body.set_physics(true);
			body.physics_on = true;
			#print("PHYSICS ON");
		body.physics_enabler_count += 1;

func _on_physics_enabler_body_exited(body):
	if body != self and body is ScoreTile and not body.is_player:
		body.physics_enabler_count -= 1;
		if body.physics_enabler_count == 0 and body.physics_on:
			body.set_physics(false);
			body.physics_on = false;
			#print("PHYSICS OFF EXIT");

func enable_physics_immediately():
	$PhysicsEnabler2.enabled = true;
	$PhysicsEnabler2.force_shapecast_update();
	for i in $PhysicsEnabler2.get_collision_count():
		var body = $PhysicsEnabler2.get_collider(i);
		
		if body is ScoreTile and not body.is_player and not body.physics_on:
			body.set_physics(true);
			body.physics_on = true;
	$PhysicsEnabler2.enabled = false;

func get_nearby_baddies(side_length) -> Array[Baddie]:
	var ans:Array[Baddie] = [];
	
	$PhysicsEnabler2.enabled = true;
	var old_size:Vector2 = $PhysicsEnabler2.shape.size;
	$PhysicsEnabler2.shape.size = Vector2(side_length, side_length);
	$PhysicsEnabler2.force_shapecast_update();
	for i in $PhysicsEnabler2.get_collision_count():
		var body = $PhysicsEnabler2.get_collider(i);
		
		if body is Baddie:
			ans.push_back(body);
	
	$PhysicsEnabler2.shape.size = old_size;
	$PhysicsEnabler2.enabled = false;
	
	return ans;

func die():
	if invincible:
		return;
	
	#play an animation
	#spawn in checkpoint (if set)
	
	if not GV.changing_level:
		GV.changing_level = true;
		GV.reverting = true;
		game.change_level_faded(GV.current_level_index);


#layer 2 is for tile physics enabling
#layer 3 is for player ability unlocking
func set_layers(state, layer_one):
	if layer_one:
		set_collision_layer_value(1, state);
	for i in range(5, 33):
		set_collision_layer_value(i, state);

func set_masks(state):
	set_collision_mask_value(1, state);

func set_physics(state):
	#set_process(state);
	#set_physics_process(state);
	$FSM.set_process(state);
	$FSM.set_physics_process(state);
	for i in range(1, 5):
		get_node("Ray"+str(i)).enabled = state;
		get_node("Shape"+str(i)).enabled = state;

#doesn't affect layers or masks or physics
func player_settings():
	#connect signal
	game.current_level.repeat_input.connect(_on_repeat_input);
	
	#add to player list
	#print("add index: ", game.current_level.players.size());
	game.current_level.players.push_back(self);
		
	#add group
	add_to_group("player");
	
	#enable PhysicsEnabler
	$PhysicsEnabler.monitoring = true;
	
	#add to unlocker layer
	set_collision_layer_value(3, true);

	#disable membrane collision
	for i in range(1, 5):
		var ray:RayCast2D = get_node("Ray"+str(i));
		var shape:ShapeCast2D = get_node("Shape"+str(i));
		ray.set_collision_mask_value(4, false);
		shape.set_collision_mask_value(4, false);
		ray.set_collision_mask_value(32, true);
		shape.set_collision_mask_value(32, true);
	
	#reduce collider size
	$CollisionPolygon2D.scale = GV.PLAYER_COLLIDER_SCALE * Vector2.ONE;

#doesn't affect layers or masks or physics
func tile_settings():
	#disconnect signal
	game.current_level.repeat_input.disconnect(_on_repeat_input);
	
	#remove from player list
	remove_from_players();
		
	#remove group
	remove_from_group("player");
	
	#disable PhysicsEnabler
	$PhysicsEnabler.monitoring = false;
	
	#remove from unlocker layer
	set_collision_layer_value(3, false);
	
	#enable membrane collision
	for i in range(1, 5):
		var ray:RayCast2D = get_node("Ray"+str(i));
		var shape:ShapeCast2D = get_node("Shape"+str(i));
		ray.set_collision_mask_value(4, true);
		shape.set_collision_mask_value(4, true);
		ray.set_collision_mask_value(32, false);
		shape.set_collision_mask_value(32, false);
	
	#reset collider size
	$CollisionPolygon2D.scale = Vector2.ONE;

func remove_from_players():
	var index = game.current_level.players.rfind(self);
	game.current_level.players.remove_at(index);
	#print("remove index: ", index);

func is_xaligned():
	return fmod(absf(position.x), GV.TILE_WIDTH) == GV.TILE_WIDTH/2;

func is_yaligned():
	return fmod(absf(position.y), GV.TILE_WIDTH) == GV.TILE_WIDTH/2;

#use range = GV.PLAYER_SNAP_RANGE to fix collider offset
func snap_range(offset_range:float):
	var pos_t:Vector2i = GV.world_to_pos_t(position);
	var offset:Vector2 = position - GV.pos_t_to_world(pos_t);
	if offset.x and absf(offset.x) <= offset_range:
		position.x -= offset.x;
	if offset.y and absf(offset.y) <= offset_range:
		position.y -= offset.y;

func duplicate_custom() -> ScoreTile:
	var dup = score_tile.instantiate();
	
	dup.position = position;
	dup.velocity = Vector2.ZERO;
	dup.is_player = is_player;
	dup.power = power;
	dup.ssign = ssign;
	dup.snapshot_locations = snapshot_locations.duplicate();
	dup.snapshot_locations_new = snapshot_locations_new.duplicate();
	
	return dup;

func _on_invincibility_timeout():
	invincible = false;
