extends State

var frame_count:int;
var player:ScoreTile;
@onready var game:Node2D = $"/root/Game";


func enter():
	#print("SPLITTING");
	#reset frame count
	frame_count = 0;
	
	#update power, convert to tile
	actor.power -= 1;
	actor.is_player = false;
	actor.set_masks(false);
	actor.tile_settings();
	
	#start animation
	var animator = ScoreTileAnimator.new(actor.power, actor.ssign, GV.ScaleAnim.DWING, 2, 1);
	actor.add_child(animator);
	
	#create and slide/merge player in slide_dir
	player = actor.score_tile.instantiate();
	player.is_player = true;
	player.power = actor.power;
	player.position = actor.position;
	player.slide_dir = actor.slide_dir;
	player.splitted = true;
	actor.get_parent().add_child(player);
	player.enable_physics_immediately();
	player.slide(actor.slide_dir); #guaranteed to return true
	
	#play sound
	game.split_sound.play();

func inPhysicsProcess(_delta):
	frame_count += 1;

func changeParentState():
	if frame_count == GV.SPLITTING_FRAME_COUNT:
		return states.tile;
	return null;
