extends State

var frame_count:int;
@onready var game:Node2D = $"/root/Game";




func enter():
	#print("SPLITTING");
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
	actor.get_parent().add_child(player);
	player.slide(actor.slide_dir); #this inits player state (assume player can slide)

	#set dwing parameters
	frame_count = 0;
	dwing_curr_angle = GV.DWING_START_ANGLE;
	dwing_speed = GV.DWING_SPEED;
	fade_speed = GV.DWING_FADE_SPEED;
	
	#play sound
	game.split_sound.play();

func inPhysicsProcess(delta):
	frame_count += 1;

func changeParentState():
	if frame_count == GV.SPLITTING_FRAME_COUNT:
		return states.tile;
	return null;

func exit():
	actor.img.z_index = 0;
	actor.new_img.z_index = 0;

	#swap
	var temp = actor.img;
	actor.img = actor.new_img;
	actor.new_img = temp;
