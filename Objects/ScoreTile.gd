extends CharacterBody2D
class_name ScoreTile

@onready var GV:Node = $"/root/GV";
@onready var game:Node2D = $"/root/Game";
@onready var game_audio:Node2D = game.get_node("Audio");
@export var power:int = 1;
enum States {IDLE, SLIDING, MERGING, COMBINING};
var state:int = States.IDLE;

var slide_speed:float = 360;
var slide_distance:float = 0;
var slide_target:Vector2;

var combined:bool = false;

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
	#add sprite
	update_texture(img);
	add_child(img);
	add_child(new_img);

func update_texture(s:Sprite2D):
	s.texture = load("res://Sprites/2_"+str(power)+".png");
	
func _physics_process(delta):
	match state:
		States.IDLE:
			pass;
			
		States.SLIDING:
			#sliding into empty space
			slide_distance += slide_speed * delta;
			if slide_distance >= GV.TILE_WIDTH:
				position = slide_target;
				state = States.IDLE;
				#re-enable collisions
				for i in range(2, 33):
					set_collision_layer_value(i, true);
			else:
				move_and_collide(velocity * delta);
				
		States.MERGING:
			#sliding into partner
			slide_distance += slide_speed * delta;
			if slide_distance >= GV.TILE_WIDTH:
				queue_free(); #done sliding
			else:
				if slide_distance >= GV.TILE_WIDTH/2.4 and not combined:
					partner.levelup();
					combined = true;
				move_and_collide(velocity * delta);
			
		States.COMBINING:
			#fade out img, fade in new img, do scaling animation
			var changed:bool = false;
			if new_img.modulate.a < 1:
				img.modulate.a = max(0, img.modulate.a-fade_speed);
				new_img.modulate.a = min(1, new_img.modulate.a+fade_speed);
				changed = true;
			if new_img.modulate.a >= duang_modulate and duang_curr_angle < duang_end_angle: #do duang
				img.scale = Vector2.ONE * duang_factor * sin(duang_curr_angle);
				new_img.scale = img.scale;
				duang_curr_angle += duang_speed;
				changed = true;
			if not changed:
				swap(img, new_img);
				img.scale = Vector2.ONE;
				state = States.IDLE;

#norm in direction of tile
func slide(slide_dir:Vector2):
	if state != States.IDLE:
		return;
		
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
			return;
		if collider is ScoreTile:
			if collider.power == power: #merge
				state = States.MERGING;
				game_audio.get_node("Combine").play();
				partner = collider;
				img.z_index -= 1;
			else:
				return;
	else:
		state = States.SLIDING;
		game_audio.get_node("Slide").play();
	
	#find slide parameters
	slide_distance = 0;
	velocity = slide_dir * slide_speed;
	slide_target = position + slide_dir * GV.TILE_WIDTH;
	
	#while sliding, disable collision with non-player objects
	for i in range(2, 33):
		set_collision_layer_value(i, false);
		
func levelup():
	state = States.COMBINING;
	power += 1;
	update_texture(new_img);
	new_img.modulate.a = 0;
	new_img.scale = Vector2.ONE;
	duang_curr_angle = duang_start_angle;

func swap(a:Sprite2D, b:Sprite2D):
	var temp := a;
	a = b;
	b = temp;
	
