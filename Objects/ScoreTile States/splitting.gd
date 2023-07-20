extends State

@onready var game:Node2D = $"/root/Game";

var dwing_curr_angle:float;
var dwing_speed:float;
var fade_speed:float;
var changed:bool;


func enter():
	print("SPLITTING");
	actor.power -= 1;
	actor.is_player = false;
	actor.set_masks(false);
	actor.tile_settings();
	actor.update_texture(actor.new_img, actor.power, actor.is_player);
	actor.new_img.modulate.a = 0;

	#set z_index
	actor.img.z_index = 2;
	actor.new_img.z_index = 1;
	
	#create and slide/merge player in slide_dir
	var player = actor.score_tile.instantiate();
	player.is_player = true;
	player.power = actor.power;
	player.position = actor.position;
	player.slide_dir = actor.slide_dir;
	player.splitted = true;
	get_parent().add_child(player);
	player.slide(actor.slide_dir); #this inits player state (assume player can slide)

	#set dwing parameters
	dwing_curr_angle = GV.DWING_START_ANGLE;
	dwing_speed = GV.DWING_SPEED;
	fade_speed = GV.DWING_FADE_SPEED;
	
	#play sound
	game.split_sound.play();

func inPhysicsProcess(delta):
	#fade out img, fade in new_img, shrinking animation
	changed = false;
	if dwing_curr_angle >= GV.FADE_ANGLE and actor.new_img.modulate.a < 1:
		actor.img.modulate.a = max(0, actor.img.modulate.a - fade_speed);
		actor.new_img.modulate.a = 1 - actor.img.modulate.a;
		changed = true;
	if dwing_curr_angle < GV.DWING_END_ANGLE: #do dwing
		dwing_curr_angle = min(GV.DWING_END_ANGLE, dwing_curr_angle + dwing_speed);
		actor.img.scale = Vector2.ONE * GV.DWING_FACTOR / sin(dwing_curr_angle);
		actor.new_img.scale = actor.img.scale;
		changed = true;

func changeParentState():
	if not changed:
		return states.tile;
	return null;

func exit():
	actor.img.z_index = 0;
	actor.new_img.z_index = 0;

	#swap
	var temp = actor.img;
	actor.img = actor.new_img;
	actor.new_img = temp;
