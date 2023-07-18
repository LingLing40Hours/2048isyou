extends State

@onready var game:Node2D = $"/root/Game";

var slide_speed:float;
var slide_distance:float = 0;
var slide_target:Vector2;


func enter():
	#set slide parameters
	slide_speed = GV.PLAYER_SLIDE_SPEED if actor.is_player else GV.TILE_SLIDE_SPEED;
	slide_distance = 0;
	slide_target = actor.position + actor.slide_dir * GV.TILE_WIDTH;
	actor.velocity = actor.slide_dir * slide_speed;
	
	#disable collision when sliding
	var collide_with_player:bool = actor.is_player or not GV.player_snap;
	actor.set_collision(false, !collide_with_player);
	
	#play sound
	game.combine_sound.play();

func inPhysicsProcess(delta):
	#sliding into partner
	slide_distance += slide_speed * delta;
	actor.move_and_collide(actor.velocity * delta);
	
func changeParentState():
	if slide_distance >= GV.COMBINE_MERGE_RATIO * GV.TILE_WIDTH:
		return states.merging2;
	return null;
