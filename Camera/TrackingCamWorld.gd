extends TrackingCam
class_name TrackingCamWorld


func _ready():
	super._ready();
	#set initial position
	track_pos = avg_player_pos();
	position = track_pos.clamp(min_pos, max_pos);

func avg_player_pos():
	return GV.pos_t_to_world(level.player_pos_t);
