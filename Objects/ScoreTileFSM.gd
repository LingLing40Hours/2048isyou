class_name ScoreTile
extends CharacterBody2D

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";
@export var power:int = 1;

var slide_speed:float = 360;
var slide_distance:float = 0;
var slide_target:Vector2;

var img:Sprite2D = Sprite2D.new();
var new_img:Sprite2D = Sprite2D.new();
var fade_speed:float = 0.05;
var duang_modulate:float = 0.2;
var duang_start_angle:float = 1;
var duang_factor:float = 1/sin(duang_start_angle);
var duang_curr_angle:float;
var duang_end_angle:float = PI - duang_start_angle;
var duang_speed:float = 0.07;
var partner:ScoreTile;


func _ready():
	#turn off physics
	set_process(false);
	set_physics_process(false);
	for i in range(1, 5):
		get_node("Ray"+str(i)).enabled = false;
	
	#add sprite
	update_texture(img);
	add_child(img);
	add_child(new_img);
	
	#set initial state
	$FSM.setState($FSM.states["idle"]);

func update_texture(s:Sprite2D):
	s.texture = load("res://Sprites/2_"+str(power)+".png");


func slide(slide_dir:Vector2, collide_with_player:bool) -> bool:
	if get_state() != "idle":
		return false;
		
	#find ray in slide direction
	var ray:RayCast2D;
	if slide_dir == Vector2(1, 0):
		ray = $Ray1;
	elif slide_dir == Vector2(0, -1):
		ray = $Ray2;
	elif slide_dir == Vector2(-1, 0):
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
				game.get_node("Audio").get_node("Combine").play();
				partner = collider;
				img.z_index -= 1;
			else:
				return false;
	else:
		change_state("sliding");
		game.get_node("Audio").get_node("Slide").play();
	
	#find slide parameters
	slide_distance = 0;
	velocity = slide_dir * slide_speed;
	slide_target = position + slide_dir * GV.TILE_WIDTH;
	
	#while sliding, disable collision with (non-player?) objects
	if not collide_with_player:
		set_collision_layer_value(1, false);
	for i in range(2, 33):
		set_collision_layer_value(i, false);
	
	return true;

func levelup():
	change_state("combining");
	power += 1;
	update_texture(new_img);
	new_img.modulate.a = 0;
	new_img.scale = Vector2.ONE;
	duang_curr_angle = duang_start_angle;

func swap(a:Sprite2D, b:Sprite2D):
	var temp := a;
	a = b;
	b = temp;
	
func get_state() -> String:
	return $FSM.curState.name;

func change_state(s:String):
	$FSM.setState($FSM.states[s]);
