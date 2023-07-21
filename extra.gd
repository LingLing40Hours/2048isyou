extends Node

'''	move_and_slide()
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index);
		var collider := collision.get_collider();
		if collider.is_in_group("wall"):
			vx *= -1;
			vy *= -1;
			velocity.x = vx;
			velocity.y = vy;
		elif collider.is_in_group("player"):
			collider.die();'''

'''func _physics_process(delta):
	match state:
		States.SLIDING:
			#sliding into empty space
			slide_distance += slide_speed;
			if slide_distance >= GV.TILE_WIDTH:
				position = slide_target;
				state = States.IDLE;
				#re-enable collisions
				for i in range(1, 33):
					set_collision_layer_value(i, true);
			else:
				position += slide_step;
				
		States.MERGING:
			#sliding into partner
			slide_distance += slide_speed;
			if slide_distance >= GV.TILE_WIDTH:
				queue_free(); #done sliding
			else:
				if slide_distance >= GV.TILE_WIDTH/2 and not leveluped:
					partner.levelup();
					leveluped = true;
				position += slide_step;
			
		States.COMBINING:
			#fade out img, fade in new img, do scaling animation
			img.modulate.a -= fade_speed;
			new_img.modulate.a += fade_speed;
			
			if new_img.modulate.a >= duang_modulate: #do duang
				if duang_curr_angle >= duang_end_angle: #end of state
					#swap(img, new_img);
					img.scale = Vector2.ONE;
					state = States.IDLE;
				else:
					img.scale = Vector2.ONE * duang_factor * sin(duang_curr_angle);
					new_img.scale = img.scale;
					duang_curr_angle += duang_speed;
				
		States.IDLE:
			pass;'''

'''		if collider is ScoreTile:
			#slide if normal_dir and player_dir agree
			var slide_dir:Vector2 = collision.get_normal() * (-1);
			if abs(slide_dir.x) >= abs(slide_dir.y):
				#slide_dir.y = 0;
				if slide_dir.x > 0 and dir.x > 0:
					collider.slide(Vector2(1, 0));
				elif dir.x < 0:
					collider.slide(Vector2(-1, 0));
			else:
				#slide_dir.x = 0;
				if slide_dir.y > 0 and dir.y > 0:
					collider.slide(Vector2(0, 1));
				elif dir.y < 0:
					collider.slide(Vector2(0, -1));'''

'''
		if collider.is_in_group("wall"):
			if actor.is_player:
				var pos = collider.local_to_map(actor.position + ray.position + ray.target_position);
				var id = collider.get_cell_source_id(0, pos);
				obstructed = false if id == 1 else true;
			else:
				return true;
'''



'''
func slide(slide_dir:Vector2, collide_with_player:bool) -> bool:
	if get_state() != "tile" and get_state() != "snap":
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
				game.combine_sound.play();
				partner = collider;
				img.z_index -= 1;
			else:
				return false;
	else:
		change_state("sliding");
		game.slide_sound.play();
	
	#find slide parameters
	slide_distance = 0;
	velocity = slide_dir * slide_speed;
	slide_target = position + slide_dir * GV.TILE_WIDTH;
	
	#while sliding, disable collision with (non-player?) objects
	disable_collision(collide_with_player);
	
	return true;
'''

'''
func levelup():
	change_state("combining");
	power += 1;
	update_texture(new_img);
	new_img.modulate.a = 0;
	new_img.scale = Vector2.ONE;
	duang_curr_angle = duang_start_angle;
'''

'''
	if	focus_dir and (\
		Input.is_action_just_released("ui_left") or\
		Input.is_action_just_released("ui_right") or\
		Input.is_action_just_released("ui_up") or\
		Input.is_action_just_released("ui_down")):
			focus_dir = 0;
'''


'''
var focus_dir:int = 0; #-1 for x, 1 for y, 0 for neither
func _physics_process(_delta):
	#releasing direction key loses focus
	if focus_dir == -1 and (Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right")):
		focus_dir = 0;
	elif focus_dir == 1 and (Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down")):
		focus_dir = 0;
	
	#pressing direction key sets focus
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		focus_dir = -1;
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		focus_dir = 1;
'''

'''
	if next_state == null and not Input.is_action_pressed("cc"): #slide/merge
		if GV.focus_dir == -1:
			actor.slide_dir = Vector2(Input.get_axis("ui_left", "ui_right"), 0);
		elif GV.focus_dir == 1:
			actor.slide_dir = Vector2(0, Input.get_axis("ui_up", "ui_down"));
		
		if actor.slide_dir != Vector2.ZERO:
			actor.slide(actor.slide_dir);
'''
