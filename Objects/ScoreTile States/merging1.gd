extends State

@onready var game:Node2D = $"/root/Game";

var slide_speed:float;
var slide_distance:float = 0;
var slide_target:Vector2;


func enter():
	#snapshot
	var snapshot = PlayerSnapshot.new(actor.position, actor.partner.position);
	actor.save_nearby_baddies(snapshot, GV.PLAYER_SNAPSHOT_BADDIE_RANGE);
	GV.player_snapshots.push_back(snapshot);
	
	#set slide parameters
	slide_speed = GV.TILE_SLIDE_SPEED;
	slide_distance = 0;
	slide_target = actor.position + actor.slide_dir * GV.TILE_WIDTH;
	actor.velocity = actor.slide_dir * slide_speed;
	
	#disable collision when merging
	actor.set_layers(false, actor.is_player or GV.player_snap);
	if actor.is_player:
		actor.set_masks(false);
	
	#set z_index
	actor.img.z_index = -1;
	
	#play sound
	game.combine_sound.play();

func inPhysicsProcess(delta):
	#sliding into partner
	slide_distance += slide_speed * delta;
	actor.move_and_collide(actor.velocity * delta);
	
func changeParentState():
	if slide_distance >= GV.COMBINING_MERGE_RATIO * GV.TILE_WIDTH:
		return states.merging2;
	return null;
