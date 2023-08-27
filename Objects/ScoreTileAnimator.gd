class_name ScoreTileAnimator
extends Node
#used to animate ScoreTile combining/splitting
#parent.img modulate.a and scale may start at any value
#if halted, swap images, stop modifying parent.img and fade out and free img
#else finish animation with scale = Vector2.ONE and parent img at 100% opacity

var img:Sprite2D;
var anim_new_power:int;
var anim_new_ssign:int;
var anim_scale_type:int;
var anim_old_z:int; #z_index of old img during animation
var anim_new_z:int; #z_index of new img during animation
var anim_scale_speed:float;
var anim_fade_speed:float;
var anim_curr_angle:float;
var anim_end_angle:float;
var halted:bool = false;
@onready var parent = get_parent();


func _init(power, ssign, scale_type, z_index_old, z_index_new):
	#anim parameters
	anim_new_power = power;
	anim_new_ssign = ssign;
	anim_scale_type = scale_type;
	anim_old_z = z_index_old;
	anim_new_z = z_index_new;

func _ready():
	#halt other animators
	for animator in parent.animators:
		animator.halt();
	
	#add to parent's animator list
	parent.animators.push_back(self);
	
	#add image
	img = Sprite2D.new();
	parent.img.z_index = anim_old_z;
	img.z_index = anim_new_z;
	img.modulate.a = 0;
	parent.update_texture(img, anim_new_power, anim_new_ssign, parent.is_player);
	parent.add_child(img);
	
	#more anim parameters
	if anim_scale_type == GV.ScaleAnim.DUANG:
		anim_scale_speed = GV.DUANG_SPEED;
		anim_fade_speed = GV.DUANG_FADE_SPEED;
		anim_end_angle = GV.DUANG_END_ANGLE;
		
		if parent.img.scale == Vector2.ONE:
			anim_curr_angle = GV.DUANG_START_ANGLE;
		else:
			anim_curr_angle = asin(clamp(parent.img.scale.x/GV.DUANG_FACTOR, -1, 1));
	else:
		anim_scale_speed = GV.DWING_SPEED;
		anim_fade_speed = GV.DWING_FADE_SPEED;
		anim_end_angle = GV.DWING_END_ANGLE;
		
		if parent.img.scale == Vector2.ONE:
			anim_curr_angle = GV.DWING_START_ANGLE;
		else:
			anim_curr_angle = asin(clamp(GV.DWING_FACTOR/parent.img.scale.x, -1, 1));

func _physics_process(_delta):
	if halted: #fade out img
		img.modulate.a = max(0, img.modulate.a - anim_fade_speed);
		if img.modulate.a == 0:
			img.queue_free();
			exit();
	else:
		var finished = true;
	
		if anim_scale_type == GV.ScaleAnim.DUANG:
			#fade out parent.img
			if parent.img.modulate.a != 0:
				parent.img.modulate.a = max(0, parent.img.modulate.a - anim_fade_speed);
				finished = false;
			
			#fade in img
			if img.modulate.a != 1:
				img.modulate.a = min(1, img.modulate.a + anim_fade_speed);
				finished = false;
			
			#duang
			if img.modulate.a >= GV.DUANG_START_MODULATE and anim_curr_angle < anim_end_angle: #do duang
				anim_curr_angle = min(anim_end_angle, anim_curr_angle + anim_scale_speed);
				parent.img.scale = Vector2.ONE * GV.DUANG_FACTOR * sin(anim_curr_angle);
				img.scale = parent.img.scale;
				finished = false;
		else:
			if anim_curr_angle >= GV.FADE_START_ANGLE:
				#fade out parent.img
				if parent.img.modulate.a != 0:
					parent.img.modulate.a = max(0, parent.img.modulate.a - anim_fade_speed);
					finished = false;
				
				#fade in img
				if img.modulate.a != 1:
					img.modulate.a = min(1, img.modulate.a + anim_fade_speed);
					finished = false;
				
			#dwing
			if anim_curr_angle < anim_end_angle:
				anim_curr_angle = min(anim_end_angle, anim_curr_angle + anim_scale_speed);
				parent.img.scale = Vector2.ONE * GV.DWING_FACTOR / sin(anim_curr_angle);
				img.scale = parent.img.scale;
				finished = false;
				
		if finished:
			#swap and free old img
			var old_img:Sprite2D = parent.img;
			parent.img = img;
			parent.img.z_index = 0;
			old_img.queue_free();
			exit();


func halt():
	if halted:
		return;
	
	#swap images
	var temp:Sprite2D = parent.img;
	parent.img = img;
	img = temp;
	
	#parent img z_index will be set to anim_old_z
	#maintain relative z_index between img and parent.img
	img.z_index += anim_old_z - parent.img.z_index;
	
	#fade out img
	halted = true;

func exit():
	#remove from parent's animator list
	var index = parent.animators.rfind(self);
	parent.animators.remove_at(index);
	
	queue_free();
