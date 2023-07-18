class_name ScoreTile
extends CharacterBody2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";

@export var is_player:bool = false;
@export var power:int = 1;

var slide_dir:Vector2 = Vector2.ZERO;

var img:Sprite2D = Sprite2D.new();
var new_img:Sprite2D = Sprite2D.new();

var partner:ScoreTile;


func _ready():
	#turn off physics
	if not is_player:
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


func slide(dir:Vector2, collide_with_player:bool) -> bool:
	if get_state() != "tile" and get_state() != "snap":
		return false;
		
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
	
	#determine whether to slide or merge or, if obstructed, idle
	if ray.is_colliding():
		var collider := ray.get_collider();
		if collider.is_in_group("wall"): #obstructed
			return false;
		if collider is ScoreTile:
			if collider.power == power: #merge
				change_state("merging1");
				game.combine_sound.play();
				partner = collider;
				img.z_index -= 1;
			else:
				return false;
	else:
		slide_dir = dir;
		change_state("sliding");
	
	return true;

func levelup():
	change_state("combining");

func swap(a:Sprite2D, b:Sprite2D):
	var temp := a;
	a = b;
	b = temp;
	
func get_state() -> String:
	return $FSM.curState.name;

func change_state(s:String):
	$FSM.setState($FSM.states[s]);


func _on_physics_enabler_body_entered(body):
	if body is ScoreTile:
		body.set_physics(true);

func _on_physics_enabler_body_exited(body):
	if body is ScoreTile:
		body.set_physics(false);

func die():
	#play an animation
	game.change_level_faded(GV.current_level_index);


func set_collision(state, layer_one):
	if layer_one:
		set_collision_layer_value(1, state);
	for i in range(3, 33):
		set_collision_layer_value(i, state);

func set_physics(state):
	$FSM.set_process(state);
	$FSM.set_physics_process(state);
	for i in range(1, 5):
		get_node("Ray"+str(i)).enabled = state;

func update_texture(s:Sprite2D, power, dark):
	if dark:
		s.texture = load("res://Sprites/2_"+str(power)+"_dark.png");
	else:
		s.texture = load("res://Sprites/2_"+str(power)+".png");
