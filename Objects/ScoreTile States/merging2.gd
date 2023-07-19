extends State

@onready var game:Node2D = $"/root/Game";

var slide_speed:float;
var slide_distance:float = 0;
var slide_target:Vector2;


func enter():
	#do the thing
	actor.get_node("PhysicsEnabler").monitoring = false;
	actor.partner.levelup(actor.is_player);
	
	#get slide parameters
	var prev_state:Node2D = get_parent().prevState;
	slide_speed = prev_state.slide_speed;
	slide_distance = prev_state.slide_distance;
	slide_target = prev_state.slide_target;

func inPhysicsProcess(delta):
	#sliding into partner
	slide_distance += slide_speed * delta;
	if slide_distance >= GV.TILE_WIDTH:
		var index = game.current_level.players.rfind(actor);
		game.current_level.players.remove_at(index);
		actor.queue_free(); #done sliding
	else:
		actor.move_and_collide(actor.velocity * delta);
	
