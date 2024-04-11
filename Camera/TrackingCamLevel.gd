extends TrackingCam
class_name TrackingCamLevel


func _ready():
	super._ready();
	#set initial position
	if level.players:
		track_pos = avg_player_pos();
		position = track_pos.clamp(min_pos, max_pos);

#returns (0, 0) if no players present
func avg_player_pos() -> Vector2:
	var ans = Vector2.ZERO;
	for player in level.players:
		ans += player.global_position;
	return ans / level.players.size();
