extends State

var frame_count:int;
var player:ScoreTile;
@onready var game:Node2D = $"/root/Game";


func enter():
	#add to snapshot
	if not actor.is_hostile:
		game.current_level.current_snapshot.add_tile(actor);
	
	#reset frame count
	frame_count = 0;
	
	#update power, convert to tile
	actor.power -= 1;
	actor.color = GV.ColorId.ALL;
	actor.is_hostile = false;
	actor.set_masks(false);
	actor.tile_settings();
	actor.set_color(GV.ColorId.GRAY, false);
	
	#start animation
	var animator = ScoreTileAnimator.new(actor.power, actor.ssign, GV.ScaleAnim.DWING, 2, 1);
	actor.add_child(animator);
	
	#create and slide/merge player in slide_dir
	player = game.current_level.get_tile() if game.current_level.pooled else actor.score_tile.instantiate();
	player.pusheds = actor.pusheds.duplicate();
	actor.pusheds.clear();
	for tile in player.pusheds:
		tile.pusher = player;
	#player.debug = true;
	player.color = GV.ColorId.GRAY;
	player.power = actor.power;
	player.ssign = actor.ssign;
	player.pos_t = actor.pos_t;
	player.position = actor.position;
	player.slide_dir = actor.slide_dir;
	player.splitted = true;
	
	if game.current_level.pooled and player.is_inside_tree():
		player.initialize();
	else:
		actor.get_parent().add_child(player);
	#print("player physics: ", player.physics_on);
	assert(actor.physics_on);
	assert(actor.get_process_mode() == PROCESS_MODE_INHERIT);
	
	#player inherits actor's premoves *after* add_child() so enter idle doesn't consume any
	player.premoves = actor.premoves.duplicate();
	player.premove_dirs = actor.premove_dirs.duplicate();
	player.premove_streak = actor.premove_streak;
	actor.premoves.clear();
	actor.premove_dirs.clear();
	
	player.enable_physics_immediately();
	player.slide(actor.slide_dir); #guaranteed to return true
	
	#play sound
	game.split_sound.play();

func inPhysicsProcess(_delta):
	frame_count += 1;

func handleInput(event):
	if actor.color == GV.ColorId.GRAY and game.current_level.update_last_input(event):
		actor.add_premove();

func changeParentState():
	if frame_count == GV.SPLITTING_FRAME_COUNT:
		return states.tile;
	return null;
