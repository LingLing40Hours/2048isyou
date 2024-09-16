extends State

@onready var game:Node2D = $"/root/Game";

var slide_speed:float;
var slide_distance:float = 0;
var slide_target:Vector2;


func enter():
	#add to snapshot
	if not actor.is_hostile and (!is_instance_valid(actor.pusher) or not actor.pusher.is_hostile):
		if actor.splitted:
			game.current_level.current_snapshot.add_new_tile(actor);
		else:
			game.current_level.current_snapshot.add_tile(actor);
		game.current_level.current_snapshot.add_tile(actor.partner);
	
	#set slide parameters
	slide_speed = GV.TILE_SLIDE_SPEED;
	slide_distance = 0;
	slide_target = actor.position + actor.slide_dir * GV.TILE_WIDTH;
	actor.velocity = actor.slide_dir * slide_speed;
	
	#disable collision when merging
	actor.set_layers(false, GV.player_snap);
	if actor.color == GV.ColorId.GRAY:
		actor.set_masks(false);
	
	#set z_index
	actor.img.z_index = -1;
	
	#play sound
	game.combine_sound.play();

func inPhysicsProcess(delta):
	#sliding into partner
	slide_distance += slide_speed * delta;
	actor.move_and_collide(actor.velocity * delta);

func handleInput(event):
	if actor.color == GV.ColorId.GRAY and game.current_level.update_last_input(event):
		actor.add_premove();
	
func changeParentState():
	if slide_distance >= GV.COMBINING_MERGE_RATIO * GV.TILE_WIDTH:
		return states.merging2;
	return null;
