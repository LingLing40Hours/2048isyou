#tile is considered to be merged at this point, don't handle input
extends State

@onready var game:Node2D = $"/root/Game";

var slide_speed:float;
var slide_distance:float = 0;
var slide_target:Vector2;


func enter():
	#levelup partner
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
	if slide_distance >= GV.TILE_WIDTH: #done sliding
		if game.current_level.pooled:
			if not actor.splitted:
				game.current_level.loaded_tiles.erase(actor.pos_t);
			game.current_level.pool_tile(actor);
		else:
			if actor.color == GV.ColorId.GRAY:
				actor.remove_from_players();
			actor.queue_free();
	else:
		actor.move_and_collide(actor.velocity * delta);
