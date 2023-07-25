class_name ScoreTileAnimator
extends Node
#used to animate ScoreTile combining/splitting
#modulate.a and scale may start at any value
#if interrupted, fade out and free img and stop modifying parent.img
#else finish animation with scale = Vector2.ONE and parent img at 100% opacity

var img:Sprite2D;
var anim_scale_type:int;
var anim_scale_speed:float;
var anim_fade_speed:float;
var anim_curr_angle:float = 1;
var animating:bool = false;
@onready var parent = get_parent();


func _init(power, scale_type, scale_speed, fade_speed):
	#add image
	img = Sprite2D.new();
	update_texture(img, power, parent.is_player);
	parent.add_child(img);
	
	#set scale type
	anim_scale_type = scale_type;
	
	#set speeds
	anim_scale_speed = scale_speed;
	anim_fade_speed = fade_speed;
	
	#set current angle
	if scale_type == GV.ScaleAnim.DUANG:
		if parent.img.scale == Vector2.ONE:
			anim_curr_angle = GV.DUANG_START_ANGLE;
		else:
			anim_curr_angle = asin(clamp(parent.img.scale.x/GV.DUANG_FACTOR, -1, 1));
	else:
		if parent.img.scale == Vector2.ONE:
			anim_curr_angle = GV.DWING_START_ANGLE;
		else:
			anim_curr_angle = asin(clamp(GV.DWING_FACTOR/parent.img.scale.x, -1, 1));
	
	#start animation
	animating = true;

func _process(_delta):
	if animating:
		animating = false;
		
		#fade
		#scale
	
	#fade out img, fade in new img, do scaling animation
	if actor.new_img.modulate.a < 1:
		actor.img.modulate.a = max(0, actor.img.modulate.a - fade_speed);
		actor.new_img.modulate.a = 1 - actor.img.modulate.a;
		changed = true;
	if actor.new_img.modulate.a >= GV.DUANG_MODULATE and duang_curr_angle < GV.DUANG_END_ANGLE: #do duang
		duang_curr_angle = min(GV.DUANG_END_ANGLE, duang_curr_angle + duang_speed);
		actor.img.scale = Vector2.ONE * GV.DUANG_FACTOR * sin(duang_curr_angle);
		actor.new_img.scale = actor.img.scale;
		changed = true;


	#fade out img, fade in new_img, shrinking animation
	if dwing_curr_angle >= GV.FADE_ANGLE and actor.new_img.modulate.a < 1:
		actor.img.modulate.a = max(0, actor.img.modulate.a - fade_speed);
		actor.new_img.modulate.a = 1 - actor.img.modulate.a;
		changed = true;
	if dwing_curr_angle < GV.DWING_END_ANGLE: #do dwing
		dwing_curr_angle = min(GV.DWING_END_ANGLE, dwing_curr_angle + dwing_speed);
		actor.img.scale = Vector2.ONE * GV.DWING_FACTOR / sin(dwing_curr_angle);
		actor.new_img.scale = actor.img.scale;
		changed = true;

func update_texture(s:Sprite2D, img_pow, dark):
	if dark:
		s.texture = load("res://Sprites/2_"+str(img_pow)+"_dark.png");
	else:
		s.texture = load("res://Sprites/2_"+str(img_pow)+".png");
