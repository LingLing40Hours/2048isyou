extends State

@onready var game:Node2D = $"/root/Game";

var slide_speed:float;
var slide_distance:float = 0;
var slide_target:Vector2;


func enter():
	#set slide parameters
	slide_speed = GV.TILE_SLIDE_SPEED;
	if actor.is_player:
		slide_speed *= GV.PLAYER_SPEED_RATIO;
	slide_distance = 0;
	slide_target = actor.position + actor.slide_dir * GV.TILE_WIDTH;
	actor.velocity = actor.slide_dir * slide_speed;
	
	#disable collision when sliding
	var collide_with_player:bool = actor.is_player or not GV.player_snap;
	actor.set_layers(false, !collide_with_player);
	
	#play sound
	game.slide_sound.play();

func inPhysicsProcess(delta):
	#sliding into empty space
	slide_distance += slide_speed * delta;
	if slide_distance >= GV.TILE_WIDTH:
		actor.position = slide_target;
		actor.set_layers(true, true);
	else:
		actor.move_and_collide(actor.velocity * delta);

func changeParentState():
	if actor.position == slide_target:
		if actor.is_player:
			return states.snap;
		return states.tile;
	return null;
