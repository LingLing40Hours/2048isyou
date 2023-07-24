class_name ScoreTileAnimator
extends Node

var anim_scale_speed:float;
var anim_fade_speed:float;
var anim_curr_angle:float = 1;
var animating:bool = false;
@onready var parent = get_parent();


func duang(duang_speed, fade_speed):
	#set speeds
	anim_scale_speed = duang_speed;
	anim_fade_speed = fade_speed;
	
	#set current angle
	if parent.img.scale == Vector2.ONE:
		anim_curr_angle = GV.DUANG_START_ANGLE;
	else:
		anim_curr_angle = asin(clamp(parent.img.scale.x/GV.DUANG_FACTOR, -1, 1));
	
	#start animation
	animating = true;

func dwing(dwing_speed, fade_speed):
	#set speeds
	anim_scale_speed = dwing_speed;
	anim_fade_speed = fade_speed;
	
	#set current angle
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
	
