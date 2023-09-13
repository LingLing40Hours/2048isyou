extends State

@onready var game:Node2D = $"/root/Game";

var slide_speed:float;
var slide_distance:float = 0;
var slide_target:Vector2;


func enter():
	#do the thing
	actor.get_node("PhysicsEnabler").monitoring = false;
	actor.partner.levelup();
	
	#get slide parameters
	var prev_state:Node2D = get_parent().prevState;
	slide_speed = prev_state.slide_speed;
	slide_distance = prev_state.slide_distance;
	slide_target = prev_state.slide_target;

func inPhysicsProcess(delta):
	#sliding into partner
	slide_distance += slide_speed * delta;
	if slide_distance >= GV.TILE_WIDTH:
		if actor.is_player:
			print("REMOVE");
			print(game.current_level.players.size());
			actor.remove_from_players();
			print(game.current_level.players.size());
		actor.queue_free(); #done sliding
	else:
		actor.move_and_collide(actor.velocity * delta);
	
