class_name ScoreTile
extends CharacterBody2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";

@export var is_player:bool = false;
@export var power:int = 1;
@export var debug:bool = false;

var score_tile:PackedScene;
var img:Sprite2D = Sprite2D.new();
var new_img:Sprite2D = Sprite2D.new();
var partner:ScoreTile;

var slide_dir:Vector2 = Vector2.ZERO;
var splitted:bool = false; #created from split, not settled yet
var snap_slid:bool = false; #slid by player in snap mode


func _ready():
	#load score_tile
	score_tile = load("res://Objects/ScoreTile.tscn");
	
	#settings
	if is_player:
		if splitted:
			set_layers(false, true);
		else:
			set_masks(true);
		player_settings();
	else:
		#turn off physics
		set_physics(false);
	
	#add sprite
	update_texture(img, power, is_player);
	add_child(img);
	add_child(new_img);
	
	#set initial state
	var initial_state = "tile";
	if is_player:
		if GV.player_snap:
			initial_state = "snap";
		else:
			initial_state = "slide";
	$FSM.setState($FSM.states[initial_state]);


func _physics_process(_delta):
	if debug:
		print(get_state());


func slide(dir:Vector2) -> bool:
	if get_state() not in ["tile", "snap"]:
		return false;
	
	#determine whether to slide or merge or, if obstructed, idle
	var next_state:Node2D;
	var xaligned = true;
	var yaligned = true;
	if is_player: #ignore ray if not aligned with tile grid
		xaligned = fmod(position.x, GV.TILE_WIDTH) == GV.TILE_WIDTH/2;
		yaligned = fmod(position.y, GV.TILE_WIDTH) == GV.TILE_WIDTH/2;
		if (dir.x and not xaligned) or (dir.y and not yaligned):
			next_state = $FSM.states.sliding;
	
	if next_state == null:
		#find ray in slide direction
		var ray:RayCast2D;
		if dir == Vector2(1, 0):
			ray = $Ray1;
		elif dir == Vector2(0, -1):
			ray = $Ray2;
		elif dir == Vector2(-1, 0):
			ray = $Ray3;
		else:
			ray = $Ray4;
		
		if ray.is_colliding():
			var collider := ray.get_collider();
			
			if collider.is_in_group("wall"): #obstructed
				return false;
				
			if collider is ScoreTile:
				if not xaligned or not yaligned: #in snap mode, must be aligned to do stuff
					return false;
				if collider.power == power: #merge
					partner = collider;
					next_state = $FSM.states.merging1;
				elif is_player and collider.slide(dir): #try to slide collider
					collider.snap_slid = true;
					next_state = $FSM.states.sliding;
				else:
					return false;
			else:
				next_state = $FSM.states.sliding;
		else:
			next_state = $FSM.states.sliding;
	
	slide_dir = dir;
	$FSM.curState.next_state = next_state;
	return true;

func levelup(to_player):
	if to_player:
		is_player = true;
		set_masks(true);
		player_settings();
		set_physics(true);
	change_state("combining");

	
func get_state() -> String:
	return $FSM.curState.name;

func change_state(s:String):
	$FSM.setState($FSM.states[s]);


func _on_physics_enabler_body_entered(body):
	if body != self and body is ScoreTile and not body.is_player:
		#print("PHYSICS ON");
		body.set_physics(true);

func _on_physics_enabler_body_exited(body):
	if body != self and body is ScoreTile and not body.is_player:
		#print("PHYSICS OFF EXIT");
		body.set_physics(false);

func die():
	#play an animation
	game.change_level_faded(GV.current_level_index);


#layer 2 is for membrane and scoreTile raycasts
#layer 3 is for scoreTiles and physicsEnabler
func set_layers(state, layer_one):
	if layer_one:
		set_collision_layer_value(1, state);
	for i in range(4, 33):
		set_collision_layer_value(i, state);

func set_masks(state):
	set_collision_mask_value(1, state);
	for i in range(4, 33):
		set_collision_mask_value(i, state);

func set_physics(state):
	#set_process(state);
	#set_physics_process(state);
	$FSM.set_process(state);
	$FSM.set_physics_process(state);
	for i in range(1, 5):
		get_node("Ray"+str(i)).enabled = state;

func update_texture(s:Sprite2D, img_pow, dark):
	if dark:
		s.texture = load("res://Sprites/2_"+str(img_pow)+"_dark.png");
	else:
		s.texture = load("res://Sprites/2_"+str(img_pow)+".png");

#doesn't affect layers or masks or physics
func player_settings():
	#add to player list
	#print("add index: ", game.current_level.players.size());
	game.current_level.players.push_back(self);
		
	#add group
	add_to_group("player");
	
	#init PhysicsEnabler
	$PhysicsEnabler.monitoring = true;

	#disable rays' mask 2
	for i in range(1, 5):
		get_node("Ray"+str(i)).set_collision_mask_value(2, false);
	
	#reduce collider size
	$CollisionPolygon2D.scale = GV.PLAYER_COLLIDER_SCALE * Vector2.ONE;

#doesn't affect layers or masks or physics
func tile_settings():
	#remove from player list
	var index = game.current_level.players.rfind(self);
	#print("remove index: ", index);
	game.current_level.players.remove_at(index);
		
	#remove group
	remove_from_group("player");
	
	#disable PhysicsEnabler
	$PhysicsEnabler.monitoring = false;
	
	#enable rays' mask 2
	for i in range(1, 5):
		get_node("Ray"+str(i)).set_collision_mask_value(2, true);
	
	#reset collider size
	$CollisionPolygon2D.scale = Vector2.ONE;


func split(dir:Vector2) -> bool:
	if power == 0:
		return false;
	if get_state() != "snap":
		return false;
	
	if fmod(position.x, GV.TILE_WIDTH) != GV.TILE_WIDTH/2: #not xaligned
		return false;
	if fmod(position.y, GV.TILE_WIDTH) != GV.TILE_WIDTH/2: #not yaligned
		return false;
	
	#get ray in direction
	var ray:RayCast2D;
	if dir == Vector2(1, 0):
		ray = $Ray1;
	elif dir == Vector2(0, -1):
		ray = $Ray2;
	elif dir == Vector2(-1, 0):
		ray = $Ray3;
	else:
		ray = $Ray4;
	
	if ray.is_colliding():
		var collider := ray.get_collider();

		if collider.is_in_group("wall"): #obstructed
			return false;
			
		if collider is ScoreTile:
			#return false;
			if collider.power == power - 1: #merge split
				pass;
			elif collider.slide(dir): #slide split
				collider.snap_slid = true;
			else: #obstructed
				return false;
	
	slide_dir = dir;
	$FSM.curState.next_state = $FSM.states.splitting;
	return true;
